const FS = require("fs");
const FSE = require("fs-extra");
const PATH = require("path");
const Jimp = require("jimp");

const ROOT = PATH.join(__dirname, "..");
const SOURCE = PATH.join(ROOT, "_\u7d20\u6750");
const PREFAB = "aip_grandfather_clock";
const SIZE = 512;
const MAX_SCENE_WIDTH = SIZE - 104;
const MAX_SCENE_HEIGHT = SIZE - 52;
const TRIM_PADDING = 12;
const SCENE_SCALE = 1.35;
const SCENE_Y_OFFSET = -14;

const SKINS = [
  { id: "normal", prefab: PREFAB, file: "\u666e\u901a\u5ea7\u949f.png" },
  { id: "ruined", prefab: `${PREFAB}_ruined`, file: "\u7834\u8d25\u5ea7\u949f.png" },
  { id: "metal", prefab: `${PREFAB}_metal`, file: "\u91d1\u5c5e\u5ea7\u949f.png" },
  { id: "tall", prefab: `${PREFAB}_tall`, file: "\u9ad8\u811a\u5ea7\u949f.png" },
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

  const mainlineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      return `                <key id="${frame.id}"${time}>
                    <object_ref id="0" name="${skin.id}" folder="0" file="${fileId}" abs_x="${frame.x}" abs_y="${SCENE_Y_OFFSET}" abs_pivot_x="${skin.pivotX}" abs_pivot_y="${skin.pivotY}" abs_angle="${frame.angle}" abs_scale_x="${SCENE_SCALE}" abs_scale_y="${SCENE_SCALE}" abs_a="1" timeline="0" key="${frame.id}" z_index="0"/>
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

  return `        <animation id="${id}" name="${skin.id}${suffix}" length="${length}">
            <mainline>
${mainlineKeys}
            </mainline>
            <timeline id="0" name="${skin.id}">
${timelineKeys}
            </timeline>
        </animation>`;
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
    <entity id="0" name="${PREFAB}">
${animations.join("\n")}
    </entity>
</spriter_data>
`;
}

async function buildFolder(base) {
  const prefabPath = PATH.join(base, PREFAB);
  const clockPath = PATH.join(prefabPath, "clock");
  FSE.removeSync(prefabPath);
  makeDir(clockPath);

  const normalizedImages = {};
  for (const skin of SKINS) {
    const normalized = await normalizeSkin(skin, PATH.join(clockPath, `${skin.id}.png`));
    normalizedImages[skin.id] = normalized;
  }

  FS.writeFileSync(PATH.join(prefabPath, `${PREFAB}.scml`), createScml(), "utf8");

  return normalizedImages;
}

async function run() {
  const normalizedImages = await buildFolder(PATH.join(ROOT, "exported"));

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
