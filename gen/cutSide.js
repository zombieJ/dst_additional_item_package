// 将 PNG 图片切边
const fs = require("fs-extra");
const path = require("path");
const jimp = require("jimp");

// 导出文件夹路径
const OUT_FOLDER = "_tmp";

// 遍历所有 png 图片
async function loopPng(dir) {
  const absFolderPath = path.resolve(dir);
  const stat = await fs.stat(absFolderPath);

  if (stat.isDirectory()) {
    let retList = [];
    const files = await fs.readdir(absFolderPath);
    for (const file of files) {
      const filePath = path.join(absFolderPath, file);
      retList = retList.concat(await loopPng(filePath));
    }

    return retList;
  }

  return path.extname(absFolderPath) === ".png" ? [absFolderPath] : [];
}

(async () => {
  const { argv } = process;
  const folderPath = argv[argv.length - 1];

  // 遍历 png 进行剪裁
  const pngList = (await loopPng(folderPath)).filter(
    (path) => !path.includes(OUT_FOLDER)
  );

  let count = 0;
  const total = pngList.length;

  const promiseList = pngList.map(async (pngPath) => {
    const img = await jimp.read(pngPath);

    const { width, height } = img.bitmap;
    let left = width - 1;
    let right = 0;
    let top = height - 1;
    let bottom = 0;

    for (let x = 0; x < width; x += 1) {
      for (let y = 0; y < height; y += 1) {
        const pixel = img.getPixelColor(x, y);
        const alpha = jimp.intToRGBA(pixel).a;

        if (alpha !== 0) {
          left = Math.min(left, x);
          right = Math.max(right, x);
          top = Math.min(top, y);
          bottom = Math.max(bottom, y);
        }
      }
    }

    // 切割图片
    const newWidth = right - left;
    const newHeight = bottom - top;
    img.crop(left, top, newWidth, newHeight);

    const basename = path.basename(pngPath);
    const outputFolder = path.resolve(path.dirname(pngPath), OUT_FOLDER);
    fs.ensureDirSync(outputFolder);

    img.write(path.resolve(outputFolder, basename));

    count += 1;
    console.log(
      `${count}/${total} (${((count / total) * 100).toFixed(0)}%) - ${basename}`
    );
  });

  await Promise.all(promiseList);
})();
