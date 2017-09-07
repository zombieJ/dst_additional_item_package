(async function() {
	const args = process.argv;

	const FS = require('fs');
	const FSE = require('fs-extra');
	const PATH = require('path');
	const JIMP = require("jimp");

	// Get file path
	const path = PATH.normalize(__dirname);

	const veggieFolderPath = PATH.join(path, '..', 'veggies');

	let veggiePath = (args[2] || '').replace(/[\\\/]$/, '');
	const veggiePathArr = veggiePath.split(/[\\\/]/);
	veggie = veggiePathArr[veggiePathArr.length - 1];

	veggiePath = PATH.join(veggieFolderPath, veggie);

	console.log('Build veggie:', veggie);

	// Check if is folder
	if (!FS.lstatSync(veggiePath).isDirectory()) {
		console.error('Path is not a folder!');
		return;
	}

	// Check material
	const originPath = PATH.join(veggiePath, 'origin.png');
	const cookedPath = PATH.join(veggiePath, 'cooked.png');
	const seedPath = PATH.join(veggiePath, 'seed.png');

	if (!FS.lstatSync(originPath).isFile()) {
		console.error('"origin.png" not found');
		return;
	}
	console.log('File check success...');

	// Create veggie export
	const veggieName = `aip_veggie_${veggie}`;
	const exportFolderPath = PATH.join(path, '..', 'exported', veggieName);

	console.log('Remove old dir...');
	FSE.removeSync(exportFolderPath);

	console.log('Create dir...');
	FS.mkdirSync(exportFolderPath);

	// Generate .scml file
	console.log('Create .scml...');
	const scmlTemplate = FS.readFileSync(PATH.join(path, 'veggie.scml'), 'utf8').toString();
	const scmlText = scmlTemplate.replace(new RegExp(`\\[VEGGIE\\]`, 'g'), veggieName);
	FS.writeFileSync(PATH.join(exportFolderPath, `${veggieName}.scml`), scmlText, 'utf8');

	// Copy resource
	console.log('Copy resource...');
	const exportResFolderPath = PATH.join(exportFolderPath, veggieName);
	FS.mkdirSync(exportResFolderPath);
	FSE.copySync(originPath, PATH.join(exportResFolderPath, 'origin.png'));
	FSE.copySync(cookedPath, PATH.join(exportResFolderPath, 'cooked.png'));

	// Save inventory images
	console.log('Save inventory images...')
	const originImg = await JIMP.read(originPath);
	originImg
		.resize(64, 64)
		.write(PATH.join(path, '..', 'images', 'inventoryimages', `${veggieName}.png`));

	const cookedImg = await JIMP.read(cookedPath);
	cookedImg
		.resize(64, 64)
		.write(PATH.join(path, '..', 'images', 'inventoryimages', `${veggieName}_cooked.png`));

	// Remove anim
	console.log('Remove anim.zip...')
	FSE.removeSync(PATH.join(path, '..', 'anim', `${veggieName}.zip`));
})();