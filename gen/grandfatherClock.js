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
const HAND_SCALE = 1.35;
const CLOCK_HAND_ROOT_FILE = {
  id: 0,
  name: `${CLOCK_HAND_ROOT_SYMBOL}/${CLOCK_HAND_ROOT_SYMBOL}.png`,
  width: 1,
  height: 1,
  pivotX: 0.5,
  pivotY: 0.5,
};
const HAND_FILE = {
  id: 0,
  name: "hand/hand.png",
  width: 9,
  height: 48,
  pivotX: 0.5,
  pivotY: 8 / 48,
};

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

function setPixel(img, x, y, pixelColor) {
  if (x >= 0 && x < img.bitmap.width && y >= 0 && y < img.bitmap.height) {
    img.setPixelColor(pixelColor, x, y);
  }
}

function drawRect(img, left, top, right, bottom, pixelColor) {
  for (let y = top; y <= bottom; y += 1) {
    for (let x = left; x <= right; x += 1) {
      setPixel(img, x, y, pixelColor);
    }
  }
}

function drawCircle(img, cx, cy, radius, pixelColor) {
  const radiusSq = radius * radius;
  for (let y = cy - radius; y <= cy + radius; y += 1) {
    for (let x = cx - radius; x <= cx + radius; x += 1) {
      const dx = x - cx;
      const dy = y - cy;
      if (dx * dx + dy * dy <= radiusSq) {
        setPixel(img, x, y, pixelColor);
      }
    }
  }
}

function createAnchorImage() {
  const img = new Jimp(CLOCK_HAND_ROOT_FILE.width, CLOCK_HAND_ROOT_FILE.height, 0x00000000);
  img.setPixelColor(color(255, 255, 255), 0, 0);
  return img;
}

function createHandImage() {
  const img = new Jimp(HAND_FILE.width, HAND_FILE.height, 0x00000000);
  const cx = Math.floor(HAND_FILE.width / 2);
  const pivotY = HAND_FILE.height - 8;
  const dark = color(20, 18, 12);
  const gold = color(194, 153, 63);
  const shine = color(237, 205, 112);

  drawRect(img, cx - 1, 5, cx + 1, pivotY + 5, dark);
  drawRect(img, cx, 4, cx, pivotY + 4, gold);
  drawRect(img, cx, 5, cx, pivotY - 2, shine);

  drawRect(img, cx - 2, 7, cx + 2, 9, dark);
  drawRect(img, cx - 1, 7, cx + 1, 8, gold);

  drawCircle(img, cx, pivotY, 4, dark);
  drawCircle(img, cx, pivotY, 2, gold);
  drawCircle(img, cx, pivotY, 1, dark);

  return img;
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

function createHandScml() {
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
                    <object_ref id="0" name="hand" folder="0" file="${HAND_FILE.id}" abs_x="0" abs_y="0" abs_pivot_x="${HAND_FILE.pivotX}" abs_pivot_y="${formatNumber(HAND_FILE.pivotY)}" abs_angle="${frame.angle}" abs_scale_x="${HAND_SCALE}" abs_scale_y="${HAND_SCALE}" abs_a="1" timeline="0" key="${frame.id}" z_index="0"/>
                </key>`;
    })
    .join("\n");

  const timelineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      return `                <key id="${frame.id}"${time} spin="-1">
                    <object folder="0" file="${HAND_FILE.id}" x="0" y="0" pivot_x="${HAND_FILE.pivotX}" pivot_y="${formatNumber(HAND_FILE.pivotY)}" angle="${frame.angle}" scale_x="${HAND_SCALE}" scale_y="${HAND_SCALE}"/>
                </key>`;
    })
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">
    <folder id="0" name="hand">
        <file id="${HAND_FILE.id}" name="${HAND_FILE.name}" width="${HAND_FILE.width}" height="${HAND_FILE.height}" pivot_x="0" pivot_y="1"/>
    </folder>
    <entity id="0" name="${HAND_PREFAB}">
        <animation id="0" name="idle" length="1000">
            <mainline>
${mainlineKeys}
            </mainline>
            <timeline id="0" name="hand">
${timelineKeys}
            </timeline>
        </animation>
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

  await writeImage(createHandImage(), PATH.join(handPath, "hand.png"));
  FS.writeFileSync(PATH.join(handPrefabPath, `${HAND_PREFAB}.scml`), createHandScml(), "utf8");
}

async function run() {
  const normalizedImages = await buildFolder(PATH.join(ROOT, "exported"));
  await buildHandFolder(PATH.join(ROOT, "exported"));

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
