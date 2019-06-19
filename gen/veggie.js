/**
 * 生成农作物图片：
 * - node .\gen\veggie.js .\veggies\wheat
 */

const FS = require('fs');
const FSE = require('fs-extra');
const PATH = require('path');
const JIMP = require("jimp");

function removeSync(path) {
	if(FS.existsSync(path)) {
		// Delete if is file
		if(FS.lstatSync(path).isFile()) {
			FS.unlinkSync(path);
			return;
		}

		FS.readdirSync(path).forEach(function (file, index) {
		var curPath = path + "/" + file;
		if(FS.lstatSync(curPath).isDirectory()) { // recurse
			removeSync(curPath);
		} else { // delete file
			FS.unlinkSync(curPath);
		}
		});
		FS.rmdirSync(path);
	}
}

function makeDir(path) {
	if (!FS.existsSync(path)) {
		FS.mkdirSync(path);
	}
}

async function run() {
	const args = process.argv;

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
	const seedTmplPath = PATH.join(path, 'seed.png');

	if (!FS.lstatSync(originPath).isFile()) {
		console.error('"origin.png" not found');
		return;
	}
	console.log('File check success...');

	// Create veggie export
	const veggieName = `aip_veggie_${veggie}`;
	const veggieName01 = `${veggieName}01`;
	const exportFolderPath = PATH.join(path, '..', 'exported', veggieName);

	console.log('Create dir...');
	makeDir(exportFolderPath);

	// Generate .scml file
	console.log('Create .scml...');
	const scmlTemplate = FS.readFileSync(PATH.join(path, 'veggie.scml'), 'utf8').toString();
	const scmlText = scmlTemplate.replace(new RegExp(`\\[VEGGIE\\]`, 'g'), veggieName);
	FS.writeFileSync(PATH.join(exportFolderPath, `${veggieName}.scml`), scmlText, 'utf8');

	// Copy resource
	console.log('Copy resource...');
	const exportResFolderPath = PATH.join(exportFolderPath, veggieName01);
	makeDir(exportResFolderPath);
	FSE.copySync(originPath, PATH.join(exportResFolderPath, `${veggieName01}-0.png`));
	FSE.copySync(cookedPath, PATH.join(exportResFolderPath, `${veggieName01}-1.png`));

	// ===============================================================================
	// =                            Save inventory images                            =
	// ===============================================================================
	console.log('Save inventory images...')

	// Origin
	const originImg = await JIMP.read(originPath);
	originImg
		.resize(64, 64)
		.write(PATH.join(path, '..', 'images', 'inventoryimages', `${veggieName}.png`));

	// Cooked
	const cookedImg = await JIMP.read(cookedPath);
	cookedImg
		.resize(64, 64)
		.write(PATH.join(path, '..', 'images', 'inventoryimages', `${veggieName}_cooked.png`));

	// Seed
	const scaleOriginImg = originImg.clone().resize(50,50);
	const seedTmplImg = await JIMP.read(seedTmplPath);
	const seedBacImg = seedTmplImg.clone().opacity(0);
	// seedTmplImg.blit( scaleOriginImg, x, y[, srcx, srcy, srcw, srch] );
	/* seedTmplImg
		.composite(scaleOriginImg, 0, 0)
		.write(PATH.join(path, '..', 'images', 'inventoryimages', `${veggieName}_seed.png`)); */
	seedBacImg
		.composite(scaleOriginImg, 10, 0)
		.composite(seedTmplImg, 0, 0)
		.write(PATH.join(path, '..', 'images', 'inventoryimages', `${veggieName}_seeds.png`));

	// ===============================================================================
	// =                                  Clean Up                                   =
	// ===============================================================================
	console.log('Remove anim.zip...')
	removeSync(PATH.join(path, '..', 'anim', `${veggieName}.zip`));
}

run().catch((err) => {
	console.error('\n\nFailed!', err);
});