/**
 * 生成食品配方合成公式图片：
 * - node .\gen\foodPreview.js
 */
const FS = require('fs');
const FSE = require('fs-extra');
const PATH = require('path');
const JIMP = require("jimp");

const STATE_TITLE = 1;
const STATE_TEST = 2;
const LINE_HEIGHT = 75;
const IMAGE_HEIGHT = 64;
const MARK_HEIGHT = 30;

const imgDes = (IMAGE_HEIGHT - MARK_HEIGHT) / 2;

let id = 0;

const path = PATH.normalize(__dirname);
const rootPath = PATH.join(path, '..');

// 获取图片文件路径
function getImagePath(name) {
	const modItemPath = PATH.join(rootPath, 'images', 'inventoryimages', `${name}.png`);
	if (FSE.existsSync(modItemPath)) {
		return modItemPath;
	}
	return  PATH.join(rootPath, 'images_done', `${name}.png`);
}

async function asyncMap(list, func) {
	const promiseList = [];

	for (let index = 0; index < list.length; index += 1) {
		const promise = await func(list[index], index);
		promiseList.push(promise);
	}

	return Promise.all(promiseList);
}

function parseItem(itemStr, recipes) {
	itemStr = itemStr.trim();

	if (itemStr.match(/^\(.*\)$/)) {
		// Or Match
		itemStr = itemStr.slice(1, -1);
		const orList = itemStr.split(/\s+or\s+/);

		const innerRecipes = {};
		orList.forEach(orStr => {
			parseItem(orStr, innerRecipes);
		});

		recipes[id] = Object.values(innerRecipes);
			//.filter(({ name }) => !name.includes('_cooked'));

		id += 1;
	} else {
		// Normal Match
		const regex = /^(not\s+)?([\w_.]+)(\s+([<=>]+)\s([\d.]+))?$/;
		const match = itemStr.match(regex);

		if (!match) {
			console.warn('[Not Match]', itemStr);
			return;
		}

		const [, not, name, , compare, value] = match;

		// Fill object
		const recipe = recipes[name] = recipes[name] || { name };
		if (not) recipe.not = true;
		if (compare) recipe[compare] = value;
	}
}

async function run() {
	// Get file path
	const foodPrefabsPath = PATH.join(rootPath, 'scripts', 'prefabs', 'foods.lua');
	const fileText = FS.readFileSync(foodPrefabsPath, 'utf8').toString();

	const index = fileText.indexOf('food_recipes');

	let braceCount = 0;
	let startLoc = -1;
	let endLoc = -1;
	for (let i = index; i < fileText.length; i += 1) {
		const c = fileText[i];
		if (c === '{') {
			if (braceCount === 0) startLoc = i + 1;
			braceCount += 1;
		} else if (c === '}') {
			braceCount -= 1;
			if (braceCount === 0) {
				endLoc = i;
				break;
			}
		}
	}

	const regex = /[\r\n]+/;
	const lines = fileText.slice(startLoc, endLoc)
		.split(regex)
		.map(line => line.trim())
		.filter(line => (
			!line.startsWith('priority') &&
			!line.startsWith('weight') &&
			!line.startsWith('foodtype') &&
			!line.startsWith('health') &&
			!line.startsWith('hunger') &&
			!line.startsWith('sanity') &&
			!line.startsWith('perishtime') &&
			!line.startsWith('cooktime') &&
			!line.startsWith('tags') &&
			!line.startsWith('temperature') &&
			!line.startsWith('temperatureduration') &&
			!line.startsWith('goldvalue') &&
			line.trim()
		));

	let foodList = [];

	let state = STATE_TITLE;
	let current;
	let currentTestStr;

	lines.forEach((line) => {
		switch (state) {
			case STATE_TITLE: {
				const match = line.match(/^[^}\s]+/);
				if (!match) return;

				const name = match[0];
				current = {
					name,
				};
				currentTestStr = '';
				foodList.push(current);

				state = STATE_TEST;
				break;
			}

			case STATE_TEST: {
				const recipes = {};
				currentTestStr += line + ' ';

				if (line.includes('end')) {
					state = STATE_TITLE;

					// Process str
					currentTestStr = currentTestStr.replace(/^[^)]+\)/, '');
					currentTestStr = currentTestStr.replace(/^\s*return/, '');
					currentTestStr = currentTestStr.replace(/ end,/, '');
					currentTestStr = currentTestStr.trim();
					current.str = currentTestStr;

					// Food list
					const itemList = currentTestStr.split(/\s+and\s+/);
					itemList.forEach(itemStr => {
						parseItem(itemStr, recipes);
					});

					const recipeList = Object.values(recipes);
					current.recipes = recipeList;
				}
				break;
			}
		}
	});

	// Speical process for veg_lohan
	foodList = foodList.map((food) => {
		if (food.name === 'veg_lohan') {
			return {
				...food,
				recipes: [{
					name: 'tags.cap',
					['>']: 3,
				}],
			};
		}

		return food;
	});

	console.log('============== Generating ==============');
	// Prepare food image
	const descPath = PATH.join(rootPath, '__STEAM__');
	FSE.ensureDirSync(descPath);

	const resPath = PATH.join(rootPath, 'gen', 'res');

	let maxWidth = 0;
	const descImg = new JIMP(2000, foodList.length * LINE_HEIGHT);//, 0x1b2838FF);
	const notImg = await JIMP.read(PATH.join(resPath, 'not.png'));
	const equalsImg = await JIMP.read(PATH.join(resPath, 'equals.png'));
	const plusImg = await JIMP.read(PATH.join(resPath, 'plus.png'));
	const orImg = await JIMP.read(PATH.join(resPath, 'or.png'));

	const ltImg = await JIMP.read(PATH.join(resPath, 'lt.png'));
	const stImg = await JIMP.read(PATH.join(resPath, 'st.png'));
	const letImg = await JIMP.read(PATH.join(resPath, 'let.png'));
	const setImg = await JIMP.read(PATH.join(resPath, 'set.png'));
	const eqImg = equalsImg.clone();

	const num1Img = await JIMP.read(PATH.join(resPath, '1.png'));
	const num15Img = await JIMP.read(PATH.join(resPath, '1.5.png'));
	const num2Img = await JIMP.read(PATH.join(resPath, '2.png'));
	const num25Img = await JIMP.read(PATH.join(resPath, '2.5.png'));
	const num3Img = await JIMP.read(PATH.join(resPath, '3.png'));

	[ltImg, letImg, eqImg, stImg, setImg, num1Img, num15Img, num2Img, num25Img, num3Img].forEach(img => {
		img.resize(MARK_HEIGHT, MARK_HEIGHT);
	});

	const cmpImgs = {
		['<']: stImg,
		['<=']: setImg,
		['==']: eqImg,
		['>=']: letImg,
		['>']: ltImg,
	};
	const numImgs = {
		['1']: num1Img,
		['1.5']: num15Img,
		['2']: num2Img,
		['2.5']: num25Img,
		['3']: num3Img,
	};

	const LIMIT = 999;
	// console.log(foodList[LIMIT - 1]);

	// Loop of foods
	const promiseList = foodList.map(async (food, index) => {
		if (index >= LIMIT) return;

		const { name, recipes } = food;
		let startOffset = 0;

		// Draw food
		const foodImagePath = getImagePath(name);
		const foodImg = await JIMP.read(foodImagePath);
		descImg.composite(foodImg, startOffset, LINE_HEIGHT * index + (IMAGE_HEIGHT - foodImg.bitmap.height) / 2);
		startOffset += IMAGE_HEIGHT;

		// Draw equals
		descImg.composite(equalsImg, startOffset, LINE_HEIGHT * index);
		startOffset += IMAGE_HEIGHT;

		async function loopDraw(recipeList, useOr = false) {
			const recipesPromise = asyncMap(recipeList, async (recipe, rIndex) => {
				if (rIndex !== 0) {
					// Draw plus
					descImg.composite(
						useOr ? orImg : plusImg,
						startOffset,
						LINE_HEIGHT * index,
					);
					startOffset += IMAGE_HEIGHT;
				}
	
				if (Array.isArray(recipe)) {
					await loopDraw(recipe, true);
					return;
				}
	
				const recipeImg = new JIMP(5 * IMAGE_HEIGHT, IMAGE_HEIGHT);
				let needLeft = false;
				let needRight = false;
	
				// Draw item
				let itemImg;
				if (recipe.name.startsWith('names.')) {
					const recipeName = recipe.name.match(/names.(.*)/)[1];
					const modItemPath = getImagePath(recipeName);
					if (FS.existsSync(modItemPath)) {
						itemImg = await JIMP.read(modItemPath);
					}
				}
				if (!itemImg) itemImg = await JIMP.read(PATH.join(resPath, `${recipe.name}.png`));
				recipeImg.composite(itemImg, 2 * IMAGE_HEIGHT, 0);
	
				// Not
				if (recipe.not) {
					recipeImg.composite(notImg, 2 * IMAGE_HEIGHT, 0);
				}
	
				// Count
				if ((recipe['<'] || recipe['<=']) && (recipe['>='] || recipe['>'])) {
					needLeft = true;
					needRight = true;
					let leftCmpImg;
					let leftNumImg;
					let rightCmpImg;
					let rightNumImg;

					if (recipe['<']) {
						rightCmpImg = cmpImgs['<'];
						rightNumImg = numImgs[recipe['<']];
					} else {
						rightCmpImg = cmpImgs['<='];
						rightNumImg = numImgs[recipe['<=']];
					}

					if (recipe['>']) {
						leftCmpImg = cmpImgs['<'];
						leftNumImg = numImgs[recipe['>']];
					} else {
						leftCmpImg = cmpImgs['<='];
						leftNumImg = numImgs[recipe['>=']];
					}

					recipeImg.composite(leftCmpImg, 2 * IMAGE_HEIGHT - MARK_HEIGHT, imgDes);
					recipeImg.composite(leftNumImg, 2 * IMAGE_HEIGHT - MARK_HEIGHT * 2, imgDes);
					recipeImg.composite(rightCmpImg, 3 * IMAGE_HEIGHT, imgDes);
					recipeImg.composite(rightNumImg, 3 * IMAGE_HEIGHT + MARK_HEIGHT, imgDes);
				} else {
					['<', '<=', '==', '>=', '>'].forEach((cmp) => {
						if (!recipe[cmp]) return;
	
						needRight = true;
						const value = recipe[cmp];
						const cmpImg = cmpImgs[cmp];
						const numImg = numImgs[recipe[cmp]];
	
						recipeImg.composite(cmpImg, 3 * IMAGE_HEIGHT, imgDes);
						recipeImg.composite(numImg, 3 * IMAGE_HEIGHT + MARK_HEIGHT, imgDes);
					});
				}
	
				// Draw in desc
				descImg.composite(
					recipeImg,
					startOffset - (needLeft ? 2 * (IMAGE_HEIGHT - MARK_HEIGHT) : 2 * IMAGE_HEIGHT),
					LINE_HEIGHT * index
				);
	
				startOffset += 5 * IMAGE_HEIGHT - 4 * (IMAGE_HEIGHT - MARK_HEIGHT);
				if (!needLeft) startOffset -= 2 * MARK_HEIGHT;
				if (!needRight) startOffset -= 2 * MARK_HEIGHT;
			});

			return recipesPromise;
		}

		await loopDraw(recipes);
		maxWidth = Math.max(maxWidth, startOffset);
	});

	// Save images
	await Promise.all(promiseList);

	console.log('================= Help ================');
	// 保存一份食物文档
	FSE.writeFileSync(PATH.join(descPath, 'food.json'), JSON.stringify(foodList, null, 2), 'utf8');

	console.log('================= Save ================');
	const destPath = PATH.join(descPath, 'food.png');
	descImg
		.crop(0, 0, maxWidth, descImg.bitmap.height)
		.write(destPath);

	console.log('output file:', destPath);
}

run().catch((err) => {
	console.error('\n\nFailed!', err);
});