const FS = require("fs");
const FSE = require("fs-extra");
const PATH = require("path");
const Jimp = require("jimp");

const ROOT = PATH.join(__dirname, "..");
const SOURCE = PATH.join(ROOT, "_\u7d20\u6750");
const PREFAB = "aip_grandfather_clock";
const HAND_PREFAB = "aip_grandfather_clock_hand";
const SIZE = 512;
const MAX_SCENE_WIDTH = SIZE - 104;
const MAX_SCENE_HEIGHT = SIZE - 52;
const TRIM_PADDING = 12;
const SCENE_SCALE = 1.35;
const SCENE_Y_OFFSET = -14;
const CLOCK_HAND_ROOT_SYMBOL = "clock_hand_root";
const CLOCK_HAND_ROOT_FILE = {
  id: 0,
  name: `${CLOCK_HAND_ROOT_SYMBOL}/${CLOCK_HAND_ROOT_SYMBOL}.png`,
  width: 10,
  height: 10,
  pivotX: 0.5,
  pivotY: 0.5,
};
const HAND_TEXTURE_HEIGHT = 128;
const HAND_DISPLAY_SCALE = 0.45;
const HAND_SOURCE_FILES = [
  { id: "hour", file: "\u65f6\u9488.png", lengthScale: 0.86 },
  { id: "minute", file: "\u5206\u9488.png" },
];
const BACKGROUND_TRANSPARENT_LUMINANCE = 226;
const BACKGROUND_FADE_LUMINANCE = 210;
const BACKGROUND_NEUTRAL_TOLERANCE = 16;
const HAND_ALPHA_PADDING = 0;

const SKINS = [
  { id: "normal", prefab: PREFAB, file: "\u666e\u901a\u5ea7\u949f.png", face: { x: 86, y: 112 } },
  { id: "ruined", prefab: `${PREFAB}_ruined`, file: "\u7834\u8d25\u5ea7\u949f.png", face: { x: 100, y: 177 } },
  { id: "metal", prefab: `${PREFAB}_metal`, file: "\u91d1\u5c5e\u5ea7\u949f.png", face: { x: 83, y: 108 } },
  { id: "tall", prefab: `${PREFAB}_tall`, file: "\u9ad8\u811a\u5ea7\u949f.png", face: { x: 78, y: 128 } },
];

function makeDir(path) {
  FSE.ensureDirSync(path);
}

function writeImage(img, path) {
  return new Promise((resolve, reject) => {
    img.write(path, err => (err ? reject(err) : resolve()));
  });
}

function formatNumber(value) {
  return Number(value.toFixed(6));
}

function color(r, g, b, a = 255) {
  return Jimp.rgbaToInt(r, g, b, a);
}

function createAnchorImage() {
  return new Jimp(CLOCK_HAND_ROOT_FILE.width, CLOCK_HAND_ROOT_FILE.height, 0x00000000);
}

function findRawAlphaBounds(img) {
  const { width, height, data } = img.bitmap;
  let left = width;
  let right = 0;
  let top = height;
  let bottom = 0;

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const alpha = data[(width * y + x) * 4 + 3];
      if (alpha > 8) {
        left = Math.min(left, x);
        right = Math.max(right, x);
        top = Math.min(top, y);
        bottom = Math.max(bottom, y);
      }
    }
  }

  if (left > right || top > bottom) {
    return { x: 0, y: 0, w: width, h: height };
  }

  return { x: left, y: top, w: right - left + 1, h: bottom - top + 1 };
}

function padBounds(img, bounds, padding) {
  const left = Math.max(0, bounds.x - padding);
  const top = Math.max(0, bounds.y - padding);
  const right = Math.min(img.bitmap.width, bounds.x + bounds.w + padding);
  const bottom = Math.min(img.bitmap.height, bounds.y + bounds.h + padding);

  return { x: left, y: top, w: right - left, h: bottom - top };
}

function clamp01(value) {
  return Math.max(0, Math.min(1, value));
}

function getLuminance(r, g, b) {
  return (r + g + b) / 3;
}

function removeCheckerBackground(img) {
  const cleaned = img.clone();
  const { data } = cleaned.bitmap;

  cleaned.scan(0, 0, cleaned.bitmap.width, cleaned.bitmap.height, function scanPixel(x, y, idx) {
    const r = data[idx];
    const g = data[idx + 1];
    const b = data[idx + 2];
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const luminance = getLuminance(r, g, b);
    const neutral = max - min <= BACKGROUND_NEUTRAL_TOLERANCE;

    if (neutral && luminance >= BACKGROUND_FADE_LUMINANCE) {
      const alpha =
        luminance >= BACKGROUND_TRANSPARENT_LUMINANCE
          ? 0
          : Math.round(
              ((BACKGROUND_TRANSPARENT_LUMINANCE - luminance) /
                (BACKGROUND_TRANSPARENT_LUMINANCE - BACKGROUND_FADE_LUMINANCE)) *
                255
            );

      data[idx + 3] = Math.min(data[idx + 3], alpha);

      if (data[idx + 3] <= 0) {
        data[idx] = 0;
        data[idx + 1] = 0;
        data[idx + 2] = 0;
      }
    }
  });

  return cleaned;
}

function findHandPivot(img) {
  const { width, height, data } = img.bitmap;
  const x = Math.floor(width / 2);
  const spans = [];
  let spanStart = null;

  for (let y = 0; y < height; y += 1) {
    const alpha = data[(width * y + x) * 4 + 3];
    const transparent = alpha <= 8;

    if (transparent && spanStart == null) {
      spanStart = y;
    } else if (!transparent && spanStart != null) {
      spans.push({ start: spanStart, end: y - 1 });
      spanStart = null;
    }
  }

  if (spanStart != null) {
    spans.push({ start: spanStart, end: height - 1 });
  }

  const candidates = spans.filter(span => span.start > height * 0.55 && span.end < height - 2);
  const pivotSpan = candidates.sort((a, b) => b.end - a.end)[0];

  return {
    x: width / 2,
    y: pivotSpan == null ? height * 0.86 : (pivotSpan.start + pivotSpan.end) / 2,
  };
}

function shortenHandLength(img, pivotYFromBottom, lengthScale) {
  if (lengthScale == null || lengthScale >= 1) {
    return { image: img, pivotYFromBottom };
  }

  const width = img.bitmap.width;
  const height = img.bitmap.height;
  const bottomHeight = Math.max(1, Math.round(height * pivotYFromBottom));
  const topHeight = height - bottomHeight;
  const newTopHeight = Math.max(1, Math.round(topHeight * lengthScale));
  const shortened = new Jimp(width, newTopHeight + bottomHeight, 0x00000000);
  const top = img.clone().crop(0, 0, width, topHeight).resize(width, newTopHeight);
  const bottom = img.clone().crop(0, topHeight, width, bottomHeight);

  shortened.composite(top, 0, 0);
  shortened.composite(bottom, 0, newTopHeight);

  return {
    image: shortened,
    pivotYFromBottom: bottomHeight / shortened.bitmap.height,
  };
}

async function createHandImage(hand, fileId) {
  const src = PATH.join(SOURCE, hand.file);
  if (!FS.existsSync(src)) {
    throw new Error(`Missing source: ${src}`);
  }

  const image = removeCheckerBackground(await Jimp.read(src));
  const pivot = findHandPivot(image);
  const bounds = padBounds(image, findRawAlphaBounds(image), HAND_ALPHA_PADDING);
  const cropped = image.clone().crop(bounds.x, bounds.y, bounds.w, bounds.h);
  const width = Math.max(1, Math.round((cropped.bitmap.width * HAND_TEXTURE_HEIGHT) / cropped.bitmap.height));
  cropped.resize(width, HAND_TEXTURE_HEIGHT);
  const pivotY = clamp01((bounds.y + bounds.h - pivot.y) / bounds.h);
  const shortened = shortenHandLength(cropped, pivotY, hand.lengthScale);

  return {
    image: shortened.image,
    id: hand.id,
    fileId,
    name: `hand/${hand.id}.png`,
    width,
    height: shortened.image.bitmap.height,
    pivotX: formatNumber(clamp01((pivot.x - bounds.x) / bounds.w)),
    pivotY: formatNumber(clamp01(shortened.pivotYFromBottom)),
  };
}

function findAlphaBounds(img) {
  const raw = findRawAlphaBounds(img);
  let left = raw.x;
  let right = raw.x + raw.w - 1;
  let top = raw.y;
  let bottom = raw.y + raw.h - 1;
  const padding = Math.ceil(Math.max(right - left, bottom - top) * 0.03);
  left = Math.max(0, left - padding);
  right = Math.min(img.bitmap.width - 1, right + padding);
  top = Math.max(0, top - padding);
  bottom = Math.min(img.bitmap.height - 1, bottom + padding);

  return { x: left, y: top, w: right - left + 1, h: bottom - top + 1 };
}

function trimAlpha(img, padding) {
  const bounds = findRawAlphaBounds(img);
  const left = Math.max(0, bounds.x - padding);
  const top = Math.max(0, bounds.y - padding);
  const right = Math.min(img.bitmap.width, bounds.x + bounds.w + padding);
  const bottom = Math.min(img.bitmap.height, bounds.y + bounds.h + padding);

  return img.clone().crop(left, top, right - left, bottom - top);
}

function imagePointToScene(skin, point) {
  return {
    x: formatNumber((point.x - skin.width * skin.pivotX) * SCENE_SCALE),
    y: formatNumber(SCENE_Y_OFFSET + (skin.height * (1 - skin.pivotY) - point.y) * SCENE_SCALE),
  };
}

function transformScenePoint(point, frame) {
  const radians = (frame.angle * Math.PI) / 180;
  const dx = point.x;
  const dy = point.y - SCENE_Y_OFFSET;
  return {
    x: formatNumber(frame.x + dx * Math.cos(radians) - dy * Math.sin(radians)),
    y: formatNumber(SCENE_Y_OFFSET + dx * Math.sin(radians) + dy * Math.cos(radians)),
    angle: frame.angle,
  };
}

async function normalizeSkin(skin, outputPath) {
  const src = PATH.join(SOURCE, skin.file);
  if (!FS.existsSync(src)) {
    throw new Error(`Missing source: ${src}`);
  }

  const image = await Jimp.read(src);
  const bounds = findAlphaBounds(image);
  const cropped = image.clone().crop(bounds.x, bounds.y, bounds.w, bounds.h);
  const scale = Math.min(MAX_SCENE_WIDTH / cropped.bitmap.width, MAX_SCENE_HEIGHT / cropped.bitmap.height);
  const width = Math.max(1, Math.round(cropped.bitmap.width * scale));
  const height = Math.max(1, Math.round(cropped.bitmap.height * scale));
  cropped.resize(width, height);

  const inventory = new Jimp(SIZE, SIZE, 0x00000000);
  inventory.composite(cropped.clone(), Math.round((SIZE - width) / 2), SIZE - height - 18);

  const normalized = trimAlpha(cropped, TRIM_PADDING);
  skin.width = normalized.bitmap.width;
  skin.height = normalized.bitmap.height;
  skin.pivotX = 0.5;
  skin.pivotY = formatNumber(TRIM_PADDING / normalized.bitmap.height);

  await writeImage(normalized, outputPath);
  return {
    scene: normalized,
    inventory,
  };
}

function createAnimation(id, skin, fileId, hit) {
  const suffix = hit ? "_hit" : "";
  const length = hit ? 300 : 100;
  const frames = hit
    ? [
        { id: 0, time: null, x: 0, angle: 0 },
        { id: 1, time: 100, x: 5, angle: 358 },
        { id: 2, time: 200, x: -5, angle: 2 },
      ]
    : [{ id: 0, time: null, x: 0, angle: 0 }];

  const root = imagePointToScene(skin, skin.face);

  const mainlineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      const rootFrame = transformScenePoint(root, frame);
      return `                <key id="${frame.id}"${time}>
                    <object_ref id="0" name="${skin.id}" folder="0" file="${fileId}" abs_x="${frame.x}" abs_y="${SCENE_Y_OFFSET}" abs_pivot_x="${skin.pivotX}" abs_pivot_y="${skin.pivotY}" abs_angle="${frame.angle}" abs_scale_x="${SCENE_SCALE}" abs_scale_y="${SCENE_SCALE}" abs_a="1" timeline="0" key="${frame.id}" z_index="0"/>
                    <object_ref id="1" name="${CLOCK_HAND_ROOT_SYMBOL}" folder="1" file="${CLOCK_HAND_ROOT_FILE.id}" abs_x="${rootFrame.x}" abs_y="${rootFrame.y}" abs_pivot_x="${CLOCK_HAND_ROOT_FILE.pivotX}" abs_pivot_y="${CLOCK_HAND_ROOT_FILE.pivotY}" abs_angle="${rootFrame.angle}" abs_scale_x="1" abs_scale_y="1" abs_a="1" timeline="1" key="${frame.id}" z_index="1"/>
                </key>`;
    })
    .join("\n");

  const timelineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      const spin = hit ? ' spin="-1"' : ' spin="0"';
      return `                <key id="${frame.id}"${time}${spin}>
                    <object folder="0" file="${fileId}" x="${frame.x}" y="${SCENE_Y_OFFSET}" pivot_x="${skin.pivotX}" pivot_y="${skin.pivotY}" angle="${frame.angle}" scale_x="${SCENE_SCALE}" scale_y="${SCENE_SCALE}"/>
                </key>`;
    })
    .join("\n");

  const rootTimelineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      const spin = hit ? ' spin="-1"' : ' spin="0"';
      const rootFrame = transformScenePoint(root, frame);
      return `                <key id="${frame.id}"${time}${spin}>
                    <object folder="1" file="${CLOCK_HAND_ROOT_FILE.id}" x="${rootFrame.x}" y="${rootFrame.y}" pivot_x="${CLOCK_HAND_ROOT_FILE.pivotX}" pivot_y="${CLOCK_HAND_ROOT_FILE.pivotY}" angle="${rootFrame.angle}" scale_x="1" scale_y="1"/>
                </key>`;
    })
    .join("\n");

  return `        <animation id="${id}" name="${skin.id}${suffix}" length="${length}">
            <mainline>
${mainlineKeys}
            </mainline>
            <timeline id="0" name="${skin.id}">
${timelineKeys}
            </timeline>
            <timeline id="1" name="${CLOCK_HAND_ROOT_SYMBOL}">
${rootTimelineKeys}
            </timeline>
        </animation>`;
}

function createHandAnimation(animationId, hand) {
  const frames = [
    { id: 0, time: null, angle: 0 },
    { id: 1, time: 250, angle: 270 },
    { id: 2, time: 500, angle: 180 },
    { id: 3, time: 750, angle: 90 },
    { id: 4, time: 999, angle: 0 },
  ];

  const mainlineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      return `                <key id="${frame.id}"${time}>
                    <object_ref id="0" name="${hand.id}" folder="0" file="${hand.fileId}" abs_x="0" abs_y="0" abs_pivot_x="${hand.pivotX}" abs_pivot_y="${hand.pivotY}" abs_angle="${frame.angle}" abs_scale_x="${HAND_DISPLAY_SCALE}" abs_scale_y="${HAND_DISPLAY_SCALE}" abs_a="1" timeline="0" key="${frame.id}" z_index="0"/>
                </key>`;
    })
    .join("\n");

  const timelineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      return `                <key id="${frame.id}"${time} spin="-1">
                    <object folder="0" file="${hand.fileId}" x="0" y="0" pivot_x="${hand.pivotX}" pivot_y="${hand.pivotY}" angle="${frame.angle}" scale_x="${HAND_DISPLAY_SCALE}" scale_y="${HAND_DISPLAY_SCALE}"/>
                </key>`;
    })
    .join("\n");

  return `        <animation id="${animationId}" name="${hand.id}" length="1000">
            <mainline>
${mainlineKeys}
            </mainline>
            <timeline id="0" name="${hand.id}">
${timelineKeys}
            </timeline>
        </animation>`;
}

function createHandScml(hands) {
  const files = hands
    .map(hand => {
      return `        <file id="${hand.fileId}" name="${hand.name}" width="${hand.width}" height="${hand.height}" pivot_x="0" pivot_y="1"/>`;
    })
    .join("\n");

  const animations = hands.map((hand, index) => createHandAnimation(index, hand)).join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">
    <folder id="0" name="hand">
${files}
    </folder>
    <entity id="0" name="${HAND_PREFAB}">
${animations}
    </entity>
</spriter_data>
`;
}

function createScml() {
  const files = SKINS.map((skin, index) => {
    return `        <file id="${index}" name="clock/${skin.id}.png" width="${skin.width}" height="${skin.height}" pivot_x="0" pivot_y="1"/>`;
  }).join("\n");

  const animations = [];
  SKINS.forEach((skin, index) => {
    animations.push(createAnimation(animations.length, skin, index, false));
    animations.push(createAnimation(animations.length, skin, index, true));
  });

  return `<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">
    <folder id="0" name="clock">
${files}
    </folder>
    <folder id="1" name="${CLOCK_HAND_ROOT_SYMBOL}">
        <file id="${CLOCK_HAND_ROOT_FILE.id}" name="${CLOCK_HAND_ROOT_FILE.name}" width="${CLOCK_HAND_ROOT_FILE.width}" height="${CLOCK_HAND_ROOT_FILE.height}" pivot_x="${CLOCK_HAND_ROOT_FILE.pivotX}" pivot_y="${CLOCK_HAND_ROOT_FILE.pivotY}"/>
    </folder>
    <entity id="0" name="${PREFAB}">
${animations.join("\n")}
    </entity>
</spriter_data>
`;
}

async function buildFolder(base) {
  const prefabPath = PATH.join(base, PREFAB);
  const clockPath = PATH.join(prefabPath, "clock");
  const anchorPath = PATH.join(prefabPath, CLOCK_HAND_ROOT_SYMBOL);
  FSE.removeSync(prefabPath);
  makeDir(clockPath);
  makeDir(anchorPath);

  const normalizedImages = {};
  for (const skin of SKINS) {
    const normalized = await normalizeSkin(skin, PATH.join(clockPath, `${skin.id}.png`));
    normalizedImages[skin.id] = normalized;
  }

  await writeImage(createAnchorImage(), PATH.join(prefabPath, CLOCK_HAND_ROOT_FILE.name));
  FS.writeFileSync(PATH.join(prefabPath, `${PREFAB}.scml`), createScml(), "utf8");

  return normalizedImages;
}

async function buildHandFolder(base) {
  const handPrefabPath = PATH.join(base, HAND_PREFAB);
  const handPath = PATH.join(handPrefabPath, "hand");
  FSE.removeSync(handPrefabPath);
  makeDir(handPath);

  const hands = [];
  for (const [index, hand] of HAND_SOURCE_FILES.entries()) {
    const handImage = await createHandImage(hand, index);
    hands.push(handImage);
    await writeImage(handImage.image, PATH.join(handPrefabPath, handImage.name));
  }

  FS.writeFileSync(PATH.join(handPrefabPath, `${HAND_PREFAB}.scml`), createHandScml(hands), "utf8");
}

async function run() {
  const handOnly = process.argv.includes("--hand-only");
  const normalizedImages = handOnly ? null : await buildFolder(PATH.join(ROOT, "exported"));
  await buildHandFolder(PATH.join(ROOT, "exported"));

  if (handOnly) {
    return;
  }

  const inventoryRoot = PATH.join(ROOT, "images", "inventoryimages");
  makeDir(inventoryRoot);

  for (const skin of SKINS) {
    const image = normalizedImages[skin.id];
    const inventoryPath = PATH.join(inventoryRoot, `${skin.prefab}.png`);
    await writeImage(image.inventory.clone().resize(64, 64), inventoryPath);
  }
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
