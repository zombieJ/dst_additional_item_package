const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const archiver = require('archiver');
const { argv } = require('yargs');

const GROUP_START_COMMENT = '--[[';
const GROUP_END_COMMENT = ']]';

// 压缩 lua
function compressLua(text = '') {
	let clone = '';

	// 删除群组注释
	let commenting = false
	for (let i = 0; i < text.length; i += 1) {
		const char = text[i];
		if (!commenting && text.substr(i, GROUP_START_COMMENT.length) === GROUP_START_COMMENT) {
			commenting = true
		} else if (commenting && text.substr(i, GROUP_END_COMMENT.length) === GROUP_END_COMMENT) {
			i = i + GROUP_END_COMMENT.length - 1;
			commenting = false;
		} else if (!commenting || char === '\n' || char === '\r') {
			clone += char
		}
	}

	const lines = clone.split(/\n/);

	return lines.map(line => line
		.replace(/\s+/g, ' ')					// 多个空格替换成单个
		.replace(/\s*=\s*/g, '=')				// 等号前后空格
		.replace(/\s*==\s*/g, '==')				// 等式前后空格
		.replace(/\s*~=\s*/g, '~=')				// 不等式前后空格
		.replace(/---*\s.*/g, '')				// 删除简单注释
		.replace(/---.*/g, '')					// 删除简单注释
		.replace(/\s*([\+\-\*\/])\s*/g, '$1')	// 加减乘除不需要空格
		.replace(/\s*,\s*/g, ',')				// 逗号前后不需要空格
		.replace(/^\s+/g, '')					// 行首空格
		.replace(/\s+$/g, '')					// 行尾空格
	).join('\n');
}

// 压缩文件
function compressFolderLua(folderPath) {
	const fileList = fs.readdirSync(folderPath);

	fileList.forEach(fileName => {
		const filePath = path.join(folderPath, fileName);
		if (filePath.toLowerCase().endsWith('.lua')) {
			// 压缩 lua
			const text = fs.readFileSync(filePath, 'utf8');
			const compressed = compressLua(text);
			fs.writeFileSync(filePath, compressed, 'utf8');
		} else if (fs.statSync(filePath).isDirectory()) {
			// 递归压缩文件夹
			compressFolderLua(filePath)
		}
	});
}

async function doJob() {
	console.log(chalk.yellow("Clean up..."));
	fs.removeSync('package/');

	console.log(chalk.cyan("Create related folder..."));
	fs.ensureDirSync('package/images/inventoryimages');
	fs.ensureDirSync('package/minimap');

	console.log(chalk.cyan("Copy resourse..."));
	fs.copySync('anim', 'package/anim');
	fs.copySync('anim', 'package/anim');
	console.log(chalk.green("Copy resourse...anim done"));

	fs.copySync('images/inventoryimages/', 'package/images/inventoryimages/', { filter(src) {
		return src === 'images/inventoryimages/' || src.endsWith('.tex') || src.endsWith('.xml');
	} });
	console.log(chalk.green("Copy resourse...inventoryimages done"));

	fs.copySync('minimap/', 'package/minimap/', { filter(src) {
		return src === 'minimap/' || src.endsWith('.tex') || src.endsWith('.xml');
	} });
	console.log(chalk.green("Copy resourse...minimap done"));

	fs.copySync('scripts', 'package/scripts');
	console.log(chalk.green("Copy resourse...scripts done"));

	fs.copySync('modicon.tex', 'package/modicon.tex');
	fs.copySync('modicon.xml', 'package/modicon.xml');
	fs.copySync('modinfo.lua', 'package/modinfo.lua');
	fs.copySync('modmain.lua', 'package/modmain.lua');
	console.log(chalk.green("Copy resourse...mode info done"));

	console.log(chalk.cyan("Replace DEV mark..."));
	const outputMark = !!argv.target

	function replaceText(filepath, src, tgt) {
		let text = fs.readFileSync(filepath, 'utf8');
		text = text.replace(src, tgt);
		fs.writeFileSync(filepath, text, 'utf8');
	}
	replaceText('package/modinfo.lua', /"\(DEV MODE\)",/g, outputMark ? '"(内测)",' : '');
	replaceText('package/modinfo.lua', /name = "Additional Item Package DEV"/g, `name = "Additional Item Package${outputMark ? ' (测试)' : ''}"`);
	replaceText('package/modmain.lua', /TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package DEV"/g, 'TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package"');

	// 压缩一下 LUA 代码
	await compressFolderLua('package/')

	if (argv.target) {
		const relativePath = path.resolve(argv.target);
		console.log(chalk.green(`Copy generated package to '${relativePath}'`));

		console.log(chalk.yellow("Clean up target..."));
		try {
			fs.removeSync(relativePath);
		} catch(e) {
			console.error(e);
			console.log(chalk.yellow("Remove folder failed. Clean up content instead..."));
			const targetFiles = fs.readdirSync(relativePath);
			targetFiles.forEach((file) => {
				const targetFile = path.join(relativePath, file);
				console.log('- Remove:', targetFile);
				fs.removeSync(targetFile);
			});
		}

		console.log(chalk.cyan("Copy package..."));
		fs.copySync('package', relativePath);

		console.log(chalk.cyan("Add name mark..."));
		replaceText(path.join(relativePath, '/modinfo.lua'), /name = "Additional Item Package"/g, 'name = "Additional Item Package (内测)"');

		// 创建 zip 包
		const parentFolder = path.dirname(relativePath);
		const tmpZipFilePath = path.join(parentFolder, 'tmp.zip');

		console.log(chalk.yellow("Prepare tmp zip file:", tmpZipFilePath));
		fs.removeSync(tmpZipFilePath);

		// Init output
		await new Promise((resolve, reject) => {
			const output = fs.createWriteStream(tmpZipFilePath);
			const archive = archiver('zip');

			output.on('close', function () {
				console.log(chalk.cyan('Zip done. Total bytes:' + archive.pointer()));
				resolve();
			});
			
			archive.on('error', function(err){
				reject(err);
			});

			archive.pipe(output);

			// Do zip
			archive.directory(relativePath, false);
			archive.finalize();
		});

		// Move zip file
		const basename = path.basename(relativePath);
		const targetZipFilePath = path.join(relativePath, basename + '.zip');
		console.log(chalk.cyan('Move zip file to:', targetZipFilePath));
		fs.moveSync(tmpZipFilePath, targetZipFilePath);
	}

	console.log(chalk.green("All finished!"));
}

doJob();