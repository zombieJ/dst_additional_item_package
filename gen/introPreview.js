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
const IMG_CONTENT_SIZE = 52;
const MAX_WIDTH_COUNT = 9;
const IMG_DES = 4;

const IMAGES = [
	[
		'aip_blood_package', 'aip_plaster', 'aip_glass_minecar', 'aip_dou_tooth',
		'aip_krampus_plus',
	],

	[
		'aip_xiyou_card_single', 'aip_xiyou_card_multiple', 'aip_xiyou_card_package', 'aip_xiyou_cards',
	],

	['incinerator', 'aip_nectar_maker', 'aip_woodener', 'aip_igloo'],

	[
		'aip_dou_totem/totem/head', 'dark_observer', 'aip_fake_fly_totem', 'aip_fly_totem',
		'aip_shadow_transfer',
		'aip_dou_inscription_package', 'aip_dou_opal', 'aip_legion',
		'aip_leaf_note', 'aip_glass_chest',
	],

	[
		'popcorngun', 'aip_fish_sword', 'aip_beehave', 'aip_oar_woodead', 'aip_armor_gambler',
		'aip_dou_scepter', 'aip_dou_empower_scepter', 'aip_xinyue_hoe', 'aip_track_tool',
		"aip_score_ball",
	],

	[
		'aip_dou_cost_inscription', 'aip_dou_fire_inscription', 'aip_dou_heal_inscription',
		'aip_dou_ice_inscription', 'aip_dou_sand_inscription', 'aip_dou_dawn_inscription',
		'aip_dou_rock_inscription',
		'aip_dou_area_inscription', 'aip_dou_follow_inscription', 'aip_dou_split_inscription', 
		'aip_dou_through_inscription',
	],

	[
		'aip_blue_glasses', 'aip_horse_head', 'aip_som', 'aip_joker_face',
		'aip_wizard_hat',
	],

	['aip_olden_tea_half', 'aip_suwu', 'aip_map', 'aip_shell_stone', 'aip_22_fish'],

	[
		'chesspiece_aip_doujiang_marble', 'chesspiece_aip_doujiang_stone', 'chesspiece_aip_doujiang_moonglass',
		'chesspiece_aip_deer', 'chesspiece_aip_deer_stone', 'chesspiece_aip_deer_moonglass',
		'chesspiece_aip_moon_marble', 'chesspiece_aip_moon_stone', 'chesspiece_aip_moon_moonglass',
	],

	// 花蜜
	[
		'aip_nectar_0', 'aip_nectar_1', 'aip_nectar_2', 'aip_nectar_3', 'aip_nectar_4', 'aip_nectar_5',
		'aip_nectar_wine',
	],

	// 古神低语
	[
		'aip_oldone_plant_broken', 'aip_oldone_plant_full', 'aip_oldone_durian',
		'aip_oldone_wall_item', "aip_oldone_marble_head", "aip_oldone_marble_head_lock",
		"aip_four_flower/body/bud", "aip_four_flower/body/open", "aip_watering_flower/body/bloom", "aip_oldone_rock/body/full",
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
	// 实体目录
	if (name.includes('/')) {
		// 当前
		const modExeportPath = path.join(rootPath, 'exported', `${name}.png`);
		if (fs.existsSync(modExeportPath)) {
			return modExeportPath;
		}

		// 备份
		const modExeportDonePath = path.join(rootPath, 'exported_done', `${name}.png`);
		if (fs.existsSync(modExeportDonePath)) {
			return modExeportDonePath;
		}
	}

	// 当前 Image 目录
	const modItemPath = path.join(rootPath, 'images', 'inventoryimages', `${name}.png`);
	if (fs.existsSync(modItemPath)) {
		return modItemPath;
	}

	// 备份 Image 目录
	return  path.join(rootPath, 'images_done', `${name}.png`);
}

(async function() {
	console.log(chalk.cyan("Start build intro image..."));

	// ========================== 获取食物 ==========================
	console.log(chalk.yellow("Generate food json..."));
	const foodsFilePath = path.join(rootPath, 'scripts' , 'prefabs', `foods.lua`);
	const foodsContextLines = fs.readFileSync(foodsFilePath, 'utf8').split(/[\r\n]+/);
	
	const recipeLineNo = foodsContextLines.findIndex(line => line.includes('food_recipes'));

	let left = 0;
	const foodList = [];
	IMAGES.push(foodList);

	for (i = recipeLineNo; i < foodsContextLines.length; i += 1) {
		const line = foodsContextLines[i];
		left += line.includes('{') ? 1 : 0;
		left -= line.includes('}') ? 1 : 0;

		// 获取食物名字
		const match = line.match(/^\t([a-zA-Z_]+)\s*=\s*\{/);
		if (match) {
			console.log(match[1]);
			foodList.push(match[1]);
		}

		if (left === 0) {
			break;
		}
	}

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

	console.log('Image Lines:');
	console.log(imageLines);

	// Generate images
	console.log(chalk.cyan("Generating..."));
	const descImg = new jimp(
		MAX_WIDTH_COUNT * (IMG_SIZE + IMG_DES) - IMG_DES,
		imageLines.length * (IMG_SIZE + IMG_DES) - IMG_DES,
	);

	for (let y = 0; y < imageLines.length; y += 1) {
		const images = imageLines[y];

		for (let x = 0; x < images.length; x += 1) {
			const imagePath = getImagePath(images[x]);
			const img = await jimp.read(imagePath);

			// ============= 裁剪图片 =============
			const { width, height } = img.bitmap;
			let left = 0;
			let right = width - 1;
			let top = 0;
			let bottom = height - 1;

			// 上边
			while (top < bottom) {
				let pass = true;
				for (let x = 0; x < width; x += 1) {
					const pixel = img.getPixelColor(x, top);
					const alpha = jimp.intToRGBA(pixel).a
					if (alpha !== 0) {
						pass = false;
						break;
					}
				}

				if (!pass) {
					break;
				}

				top += 1
			}

			// 下边
			while (top < bottom) {
				let pass = true;
				for (let x = 0; x < width; x += 1) {
					const pixel = img.getPixelColor(x, bottom);
					const alpha = jimp.intToRGBA(pixel).a
					if (alpha !== 0) {
						pass = false;
						break;
					}
				}

				if (!pass) {
					break;
				}

				bottom -= 1
			}

			// 左边
			while (left < right) {
				let pass = true;
				for (let y = 0; y < height; y += 1) {
					const pixel = img.getPixelColor(left, y);
					const alpha = jimp.intToRGBA(pixel).a
					if (alpha !== 0) {
						pass = false;
						break;
					}
				}

				if (!pass) {
					break;
				}

				left += 1
			}

			// 右边
			while (left < right) {
				let pass = true;
				for (let y = 0; y < height; y += 1) {
					const pixel = img.getPixelColor(right, y);
					const alpha = jimp.intToRGBA(pixel).a
					if (alpha !== 0) {
						pass = false;
						break;
					}
				}

				if (!pass) {
					break;
				}

				right -= 1
			}

			const newWidth = right - left;
			const newHeight = bottom - top;
			img.crop(left, top, newWidth, newHeight);

			// ============= 缩放图片 =============
			const minSize = Math.min(newWidth, newHeight);
			const maxSize = Math.max(newWidth, newHeight);
			const smallSize = maxSize / minSize < 1.3
			const des = smallSize ? (IMG_SIZE - IMG_CONTENT_SIZE) / 2 : 0;

			if (smallSize) {
				img.contain(
					IMG_CONTENT_SIZE,
					IMG_CONTENT_SIZE,
				);
			} else {
				img.contain(
					IMG_SIZE,
					IMG_SIZE,
				);
			}

			descImg.composite(
				img,
				x * (IMG_SIZE + IMG_DES) + des,
				y * (IMG_SIZE + IMG_DES) + des
			);
		}
	}

	console.log(chalk.cyan("Saving..."));
	const savedPath = path.join(__STEAM__PATH, 'intro.png');
	descImg
		.write(savedPath);

		console.log(chalk.green(`done: ${savedPath}`));
})();