const FS = require("fs");
const FSE = require("fs-extra");
const PATH = require("path");
const Jimp = require("jimp");

const ROOT = PATH.join(__dirname, "..");
const SOURCE = PATH.join(ROOT, "_枕头素材");
const PREFAB = "aip_cozy_nest";
const SIZE = 512;

const SKINS = [
  { id: "pillow", file: "枕头小窝.png" },
  { id: "colorful", file: "彩色小窝.png" },
  { id: "pile", file: "枕头堆小窝.png" },
  { id: "rare", file: "珍品小窝.png" },
  { id: "red", file: "红色小窝.png" },
  { id: "patch", file: "补丁小窝.png" },
];

function makeDir(path) {
  FSE.ensureDirSync(path);
}

function writeImage(img, path) {
  return new Promise((resolve, reject) => {
    img.write(path, err => (err ? reject(err) : resolve()));
  });
}

function findAlphaBounds(img) {
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

  const padding = Math.ceil(Math.max(right - left, bottom - top) * 0.06);
  left = Math.max(0, left - padding);
  right = Math.min(width - 1, right + padding);
  top = Math.max(0, top - padding);
  bottom = Math.min(height - 1, bottom + padding);

  return { x: left, y: top, w: right - left + 1, h: bottom - top + 1 };
}

async function normalizeSkin(skin, outputPath) {
  const src = PATH.join(SOURCE, skin.file);
  if (!FS.existsSync(src)) {
    throw new Error(`Missing source: ${src}`);
  }

  const image = await Jimp.read(src);
  const bounds = findAlphaBounds(image);
  const cropped = image.clone().crop(bounds.x, bounds.y, bounds.w, bounds.h);
  const scale = Math.min((SIZE - 72) / cropped.bitmap.width, (SIZE - 88) / cropped.bitmap.height);
  const width = Math.max(1, Math.round(cropped.bitmap.width * scale));
  const height = Math.max(1, Math.round(cropped.bitmap.height * scale));
  cropped.resize(width, height);

  const canvas = new Jimp(SIZE, SIZE, 0x00000000);
  canvas.composite(cropped, Math.round((SIZE - width) / 2), SIZE - height - 28);

  await writeImage(canvas, outputPath);
  return canvas;
}

function createAnimation(id, skin, fileId, hit) {
  const suffix = hit ? "_hit" : "";
  const length = hit ? 300 : 100;
  const frames = hit
    ? [
        { id: 0, time: null, x: 0, angle: 0 },
        { id: 1, time: 100, x: 8, angle: 356 },
        { id: 2, time: 200, x: -8, angle: 5 },
      ]
    : [{ id: 0, time: null, x: 0, angle: 0 }];

  const mainlineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      return `                <key id="${frame.id}"${time}>
                    <object_ref id="0" name="${skin.id}" folder="0" file="${fileId}" abs_x="${frame.x}" abs_y="0" abs_pivot_x="0.5" abs_pivot_y="0.25" abs_angle="${frame.angle}" abs_scale_x="0.5" abs_scale_y="0.5" abs_a="1" timeline="0" key="${frame.id}" z_index="0"/>
                </key>`;
    })
    .join("\n");

  const timelineKeys = frames
    .map(frame => {
      const time = frame.time == null ? "" : ` time="${frame.time}"`;
      const spin = hit ? ' spin="-1"' : ' spin="0"';
      return `                <key id="${frame.id}"${time}${spin}>
                    <object folder="0" file="${fileId}" x="${frame.x}" y="0" pivot_x="0.5" pivot_y="0.25" angle="${frame.angle}" scale_x="0.5" scale_y="0.5"/>
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
    return `        <file id="${index}" name="nest/${skin.id}.png" width="${SIZE}" height="${SIZE}" pivot_x="0" pivot_y="1"/>`;
  }).join("\n");

  const animations = [];
  SKINS.forEach((skin, index) => {
    animations.push(createAnimation(animations.length, skin, index, false));
    animations.push(createAnimation(animations.length, skin, index, true));
  });

  return `<?xml version="1.0" encoding="UTF-8"?>
<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">
    <folder id="0" name="nest">
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
  const nestPath = PATH.join(prefabPath, "nest");
  FSE.removeSync(prefabPath);
  makeDir(nestPath);

  let defaultImage = null;
  for (const skin of SKINS) {
    const normalized = await normalizeSkin(skin, PATH.join(nestPath, `${skin.id}.png`));
    if (skin.id === "pillow") {
      defaultImage = normalized;
    }
  }

  FS.writeFileSync(PATH.join(prefabPath, `${PREFAB}.scml`), createScml(), "utf8");

  return defaultImage;
}

async function run() {
  const defaultImage = await buildFolder(PATH.join(ROOT, "exported_done"));
  await buildFolder(PATH.join(ROOT, "exported"));

  const inventoryPath = PATH.join(ROOT, "images", "inventoryimages", `${PREFAB}.png`);
  makeDir(PATH.dirname(inventoryPath));
  await writeImage(defaultImage.clone().resize(64, 64), inventoryPath);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
