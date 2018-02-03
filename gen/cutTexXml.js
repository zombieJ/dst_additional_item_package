const FS = require('fs');
const FSE = require('fs-extra');
const PATH = require('path');
const JIMP = require("jimp");
const XML2JSON = require('xml2json');

// Get file path
const path = PATH.normalize(__dirname);
const rootPath = PATH.join(path, '..');
const args = process.argv;

// Get relative path
const folderPath = args[2];
const animPath = PATH.join(rootPath, '_anim', folderPath);

async function parser(list, func) {
	// Read XML
	const xml = (await FSE.readFile(animPath)).toString();
	const json = JSON.parse(XML2JSON.toJson(xml)).Atlas;

	const texFileName = json.Texture.filename;
	const elements = json.Elements.Element;

	const imageFilePath = PATH.join(animPath, '..', texFileName.replace('.tex', '.png'));
	// console.log(imageFilePath);

	// Read Image
	const $img = await JIMP.read(imageFilePath);
	const width = $img.bitmap.width;
	const height = $img.bitmap.height;

	// Loop export Image
	const outputFolderPath = imageFilePath.replace(/\.png/, '');
	FSE.ensureDirSync(outputFolderPath);
	const promiseList = elements.map(({ name, u1, u2, v1, v2 }) => {
		const exportPath = PATH.join(outputFolderPath, name.replace('.tex', '.png'));
		const $cloneImage = $img.clone();
		const left = u1;
		const right = u2;
		const top = 1 - v2;
		const bottom = 1 - v1;

		console.log('Exported:', name);

		return $cloneImage
			.crop(
				left * width - 1,
				top * height - 1,
				(right - left) * width + 1,
				(bottom - top) * height + 1,
			)
			.write(exportPath);
	});
}

parser().catch((err) => {
	console.log(err);
});