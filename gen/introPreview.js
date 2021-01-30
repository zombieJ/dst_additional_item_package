/**
 * 生成物品介绍页面：
 * - node .\gen\introPreview.js
 */
const fs = require('fs-extra');
const path = require('path');
const jimp = require("jimp");
const chalk = require("chalk");
const execSync = require('child_process').execSync;

const IMG_SIZE = 64;
const MAX_WIDTH_COUNT = 9;

const IMAGES = [
	['aip_blood_package', 'aip_plaster', 'aip_mine_car'],
	['incinerator', 'aip_orbit_item', 'aip_nectar_maker', 'aip_woodener', 'aip_igloo'],
	['dark_observer', 'aip_shadow_paper_package', 'aip_shadow_package', 'aip_dou_inscription_package', 'aip_dou_opal', 'aip_leaf_note', 'aip_glass_chest'],
	[
		'popcorngun', 'aip_fish_sword', 'aip_beehave', 'aip_oar_woodead', 'aip_armor_gambler',
		'aip_dou_scepter', 'aip_xinyue_hoe',
	],
	[
		'aip_dou_cost_inscription', 'aip_dou_fire_inscription', 'aip_dou_heal_inscription',
		'aip_dou_ice_inscription', 'aip_dou_sand_inscription', "aip_dou_dawn_inscription",
		"aip_dou_rock_inscription",
		'aip_dou_area_inscription', 'aip_dou_follow_inscription', 'aip_dou_split_inscription', 
		'aip_dou_through_inscription',
	],
	['aip_blue_glasses', 'aip_horse_head', 'aip_som', 'aip_joker_face'],
	[
		'chesspiece_aip_doujiang_marble', 'chesspiece_aip_doujiang_stone', 'chesspiece_aip_doujiang_moonglass',
		'chesspiece_aip_deer', 'chesspiece_aip_deer_stone', 'chesspiece_aip_deer_moonglass',
		'chesspiece_aip_moon_marble', 'chesspiece_aip_moon_stone', 'chesspiece_aip_moon_moonglass',
	],
	[
		'aip_veggie_wheat', 'aip_veggie_wheat_cooked',
		'aip_veggie_sunflower', 'aip_veggie_sunflower_cooked',
		'aip_veggie_grape', 'aip_veggie_grape_cooked',
	],
];

// 获取根目录
const rootPath = path.join(path.normalize(__dirname), '..');
const __STEAM__PATH = path.join(rootPath, '__STEAM__');

// 获取图片文件路径
function getImagePath(name) {
	const modItemPath = path.join(rootPath, 'images', 'inventoryimages', `${name}.png`);
	if (fs.existsSync(modItemPath)) {
		return modItemPath;
	}
	return  path.join(rootPath, 'images_done', `${name}.png`);
}

(async function() {
	console.log(chalk.cyan("Start build intro image..."));

	// 获取食物
	console.log(chalk.yellow("Generate food json..."));
	execSync(`node "${path.resolve(rootPath, 'gen', 'foodPreview.js')}"`);

	const foodList = fs.readJSONSync(path.join(__STEAM__PATH, 'food.json'));
	IMAGES.push(foodList.map(food => food.name));

	// Auto break lines
	console.log(chalk.cyan("Relayouting..."));
	const imageLines = [];
	IMAGES.forEach(images => {
		const clone = images.slice();
		while(clone.length) {
			const fitLine = clone.splice(0, MAX_WIDTH_COUNT);
			imageLines.push(fitLine);
		}
	});
	console.log(imageLines);

	// Generate images
	console.log(chalk.cyan("Generating..."));
	const descImg = new jimp(MAX_WIDTH_COUNT * IMG_SIZE, imageLines.length * IMG_SIZE);

	for (let y = 0; y < imageLines.length; y += 1) {
		const images = imageLines[y];

		for (let x = 0; x < images.length; x += 1) {
			const imagePath = getImagePath(images[x]);
			const img = await jimp.read(imagePath);

			descImg.composite(img, x * IMG_SIZE, y * IMG_SIZE);
		}
	}

	console.log(chalk.cyan("Saving..."));
	const savedPath = path.join(__STEAM__PATH, 'intro.png');
	descImg
		.write(savedPath);

		console.log(chalk.green(`done: ${savedPath}`));
})();