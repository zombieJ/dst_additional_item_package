const fs = require("fs-extra");
const path = require("path");
const Jimp = require("jimp");

const ROOT_DIR = path.resolve(__dirname, "..", "..");
const DEFAULT_INPUT_DIR = path.join(ROOT_DIR, "_素材");
const DEFAULT_OUTPUT_DIR = path.join(DEFAULT_INPUT_DIR, "out");
const IMAGE_EXTENSIONS = new Set([".png", ".jpg", ".jpeg", ".bmp"]);

const options = parseArgs(process.argv.slice(2));

function parseArgs(argv) {
  const parsed = {
    input: DEFAULT_INPUT_DIR,
    output: DEFAULT_OUTPUT_DIR,
    tolerance: 30,
    fade: 2,
    transparentEdge: 3,
    crop: true,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];

    if (arg === "--input" && next) {
      parsed.input = path.resolve(next);
      i += 1;
    } else if (arg === "--output" && next) {
      parsed.output = path.resolve(next);
      i += 1;
    } else if (arg === "--tolerance" && next) {
      parsed.tolerance = Number(next);
      i += 1;
    } else if (arg === "--fade" && next) {
      parsed.fade = Number(next);
      i += 1;
    } else if (arg === "--transparent-edge" && next) {
      parsed.transparentEdge = Number(next);
      i += 1;
    } else if (arg === "--no-crop") {
      parsed.crop = false;
    } else if (arg === "--no-transparent-edge") {
      parsed.transparentEdge = 0;
    }
  }

  if (!Number.isFinite(parsed.tolerance) || parsed.tolerance < 0) {
    parsed.tolerance = 30;
  }
  if (!Number.isFinite(parsed.fade) || parsed.fade < 0) {
    parsed.fade = 2;
  }
  if (!Number.isFinite(parsed.transparentEdge) || parsed.transparentEdge < 0) {
    parsed.transparentEdge = 3;
  }

  parsed.tolerance = Math.round(parsed.tolerance);
  parsed.fade = Math.round(parsed.fade);
  parsed.transparentEdge = Math.round(parsed.transparentEdge);

  return parsed;
}

function getPixel(data, width, x, y) {
  const index = (y * width + x) * 4;

  return {
    r: data[index],
    g: data[index + 1],
    b: data[index + 2],
    a: data[index + 3],
  };
}

function colorsMatch(c1, c2, tolerance = 0) {
  if (c1.a === 0 || c2.a === 0) {
    return c1.a === c2.a;
  }

  return (
    Math.abs(c1.r - c2.r) <= tolerance &&
    Math.abs(c1.g - c2.g) <= tolerance &&
    Math.abs(c1.b - c2.b) <= tolerance
  );
}

function setPixelTransparent(data, width, x, y) {
  const index = (y * width + x) * 4;
  data[index + 3] = 0;
}

function floodFill(data, width, height, startX, startY, tolerance) {
  const targetColor = getPixel(data, width, startX, startY);

  if (targetColor.a === 0) {
    return 0;
  }

  const visited = new Uint8Array(width * height);
  const stack = [startY * width + startX];
  let removed = 0;

  while (stack.length > 0) {
    const pixelIndex = stack.pop();

    if (visited[pixelIndex]) {
      continue;
    }

    visited[pixelIndex] = 1;

    const x = pixelIndex % width;
    const y = Math.floor(pixelIndex / width);
    const currentColor = getPixel(data, width, x, y);

    if (!colorsMatch(currentColor, targetColor, tolerance)) {
      continue;
    }

    setPixelTransparent(data, width, x, y);
    removed += 1;

    if (x + 1 < width) stack.push(pixelIndex + 1);
    if (x > 0) stack.push(pixelIndex - 1);
    if (y + 1 < height) stack.push(pixelIndex + width);
    if (y > 0) stack.push(pixelIndex - width);
  }

  return removed;
}

function applyBucketFromEdges(image, tolerance) {
  const { data, width, height } = image.bitmap;
  const seeds = [
    [0, 0],
    [width - 1, 0],
    [0, height - 1],
    [width - 1, height - 1],
    [Math.floor(width / 2), 0],
    [Math.floor(width / 2), height - 1],
    [0, Math.floor(height / 2)],
    [width - 1, Math.floor(height / 2)],
  ];

  let removed = 0;

  for (const [x, y] of seeds) {
    removed += floodFill(data, width, height, x, y, tolerance);
  }

  return removed;
}

function applyEdgeFade(image, fadeSize) {
  if (fadeSize <= 0) {
    return 0;
  }

  const { data, width, height } = image.bitmap;
  const total = width * height;
  const distanceMap = new Float32Array(total);
  const queue = [];

  distanceMap.fill(Infinity);

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const pixelIndex = y * width + x;
      const dataIndex = pixelIndex * 4;

      if (data[dataIndex + 3] === 0) {
        distanceMap[pixelIndex] = 0;
        queue.push(pixelIndex);
      }
    }
  }

  let queueIndex = 0;

  while (queueIndex < queue.length) {
    const pixelIndex = queue[queueIndex];
    queueIndex += 1;

    const currentDistance = distanceMap[pixelIndex];

    if (currentDistance >= fadeSize) {
      continue;
    }

    const x = pixelIndex % width;
    const y = Math.floor(pixelIndex / width);
    const nextDistance = currentDistance + 1;
    const neighbors = [];

    if (x + 1 < width) neighbors.push(pixelIndex + 1);
    if (x > 0) neighbors.push(pixelIndex - 1);
    if (y + 1 < height) neighbors.push(pixelIndex + width);
    if (y > 0) neighbors.push(pixelIndex - width);

    for (const nextIndex of neighbors) {
      if (nextDistance < distanceMap[nextIndex]) {
        distanceMap[nextIndex] = nextDistance;
        queue.push(nextIndex);
      }
    }
  }

  let faded = 0;

  for (let pixelIndex = 0; pixelIndex < total; pixelIndex += 1) {
    const distance = distanceMap[pixelIndex];

    if (distance > 0 && distance <= fadeSize) {
      const dataIndex = pixelIndex * 4;
      const alpha = data[dataIndex + 3];

      if (alpha > 0) {
        const ratio = distance / (fadeSize + 1);
        data[dataIndex + 3] = Math.floor(alpha * ratio);
        faded += 1;
      }
    }
  }

  return faded;
}

function collectDistanceFromTransparent(image, maxDistance) {
  const { data, width, height } = image.bitmap;
  const total = width * height;
  const distanceMap = new Float32Array(total);
  const queue = [];

  distanceMap.fill(Infinity);

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const pixelIndex = y * width + x;
      const dataIndex = pixelIndex * 4;

      if (data[dataIndex + 3] === 0) {
        distanceMap[pixelIndex] = 0;
        queue.push(pixelIndex);
      }
    }
  }

  let queueIndex = 0;

  while (queueIndex < queue.length) {
    const pixelIndex = queue[queueIndex];
    queueIndex += 1;

    const currentDistance = distanceMap[pixelIndex];

    if (currentDistance >= maxDistance) {
      continue;
    }

    const x = pixelIndex % width;
    const y = Math.floor(pixelIndex / width);
    const nextDistance = currentDistance + 1;

    if (x + 1 < width && nextDistance < distanceMap[pixelIndex + 1]) {
      distanceMap[pixelIndex + 1] = nextDistance;
      queue.push(pixelIndex + 1);
    }
    if (x > 0 && nextDistance < distanceMap[pixelIndex - 1]) {
      distanceMap[pixelIndex - 1] = nextDistance;
      queue.push(pixelIndex - 1);
    }
    if (y + 1 < height && nextDistance < distanceMap[pixelIndex + width]) {
      distanceMap[pixelIndex + width] = nextDistance;
      queue.push(pixelIndex + width);
    }
    if (y > 0 && nextDistance < distanceMap[pixelIndex - width]) {
      distanceMap[pixelIndex - width] = nextDistance;
      queue.push(pixelIndex - width);
    }
  }

  return distanceMap;
}

function applyTransparentEdge(image, edgeSize) {
  if (edgeSize <= 0) {
    return 0;
  }

  const { data, width, height } = image.bitmap;
  const distanceMap = collectDistanceFromTransparent(image, edgeSize);
  let changed = 0;

  for (let pixelIndex = 0; pixelIndex < width * height; pixelIndex += 1) {
    const distance = distanceMap[pixelIndex];

    if (distance <= 0 || distance > edgeSize) {
      continue;
    }

    const dataIndex = pixelIndex * 4;
    const r = data[dataIndex];
    const g = data[dataIndex + 1];
    const b = data[dataIndex + 2];
    const a = data[dataIndex + 3];

    if (a === 0) {
      continue;
    }

    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const saturation = max - min;

    if (saturation > 48) {
      continue;
    }

    const alpha = Math.max(0, Math.floor(255 - (r + g + b) / 3));

    data[dataIndex] = 0;
    data[dataIndex + 1] = 0;
    data[dataIndex + 2] = 0;
    data[dataIndex + 3] = Math.min(a, alpha);
    changed += 1;
  }

  return changed;
}

function trimTransparent(image) {
  const { data, width, height } = image.bitmap;
  let left = width;
  let right = -1;
  let top = height;
  let bottom = -1;

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const alpha = data[(y * width + x) * 4 + 3];

      if (alpha !== 0) {
        left = Math.min(left, x);
        right = Math.max(right, x);
        top = Math.min(top, y);
        bottom = Math.max(bottom, y);
      }
    }
  }

  if (right < left || bottom < top) {
    return { cropped: false, width, height };
  }

  const cropWidth = right - left + 1;
  const cropHeight = bottom - top + 1;

  image.crop(left, top, cropWidth, cropHeight);

  return {
    cropped: left !== 0 || top !== 0 || cropWidth !== width || cropHeight !== height,
    width: cropWidth,
    height: cropHeight,
  };
}

function writeImage(image, outputPath) {
  return new Promise((resolve, reject) => {
    image.write(outputPath, (err) => {
      if (err) {
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

function listImages(inputDir, outputDir) {
  return fs
    .readdirSync(inputDir)
    .map((file) => path.join(inputDir, file))
    .filter((filePath) => {
      const stat = fs.statSync(filePath);
      const ext = path.extname(filePath).toLowerCase();

      return (
        stat.isFile() &&
        IMAGE_EXTENSIONS.has(ext) &&
        path.dirname(filePath) !== outputDir
      );
    });
}

async function processImage(filePath, outputDir) {
  const image = await Jimp.read(filePath);
  const beforeWidth = image.bitmap.width;
  const beforeHeight = image.bitmap.height;
  const removed = applyBucketFromEdges(image, options.tolerance);
  const transparentEdge = applyTransparentEdge(image, options.transparentEdge);
  const faded = applyEdgeFade(image, options.fade);
  const cropInfo = options.crop
    ? trimTransparent(image)
    : { cropped: false, width: image.bitmap.width, height: image.bitmap.height };
  const basename = path.basename(filePath, path.extname(filePath));
  const outputPath = path.join(outputDir, `${basename}.png`);

  await writeImage(image, outputPath);

  return {
    name: path.basename(filePath),
    output: outputPath,
    beforeWidth,
    beforeHeight,
    afterWidth: cropInfo.width,
    afterHeight: cropInfo.height,
    removed,
    transparentEdge,
    faded,
  };
}

async function main() {
  const inputDir = path.resolve(options.input);
  const outputDir = path.resolve(options.output);

  if (!fs.existsSync(inputDir)) {
    throw new Error(`Input folder not found: ${inputDir}`);
  }

  fs.ensureDirSync(outputDir);

  const imageList = listImages(inputDir, outputDir);

  if (imageList.length === 0) {
    console.log(`No images found in ${inputDir}`);
    return;
  }

  console.log(`Input : ${inputDir}`);
  console.log(`Output: ${outputDir}`);
  console.log(
    `Mode  : bucket tolerance ${options.tolerance}, transparent edge ${options.transparentEdge}px, ` +
      `edge fade ${options.fade}px, crop ${options.crop ? "on" : "off"}`
  );

  for (let index = 0; index < imageList.length; index += 1) {
    const result = await processImage(imageList[index], outputDir);

    console.log(
        `${index + 1}/${imageList.length} ${result.name} ` +
        `${result.beforeWidth}x${result.beforeHeight} -> ${result.afterWidth}x${result.afterHeight}, ` +
        `transparent ${result.removed}, edge ${result.transparentEdge}, faded ${result.faded}`
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
