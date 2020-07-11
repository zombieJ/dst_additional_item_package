const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const { argv } = require('yargs');

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
function replaceText(filepath, src, tgt) {
	let text = fs.readFileSync(filepath, 'utf8');
	text = text.replace(src, tgt);
	fs.writeFileSync(filepath, text, 'utf8');
}
replaceText('package/modinfo.lua', /"\(DEV MODE\)",/g, '');
replaceText('package/modinfo.lua', /name = "Additional Item Package DEV"/g, 'name = "Additional Item Package"');
replaceText('package/modmain.lua', /TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package DEV"/g, 'TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package"');

if (argv.target) {
	const relativePath = path.resolve(argv.target);
	console.log(chalk.green(`Copy generated package to '${relativePath}'`));

	console.log(chalk.yellow("Clean up..."));
	fs.removeSync(relativePath);

	console.log(chalk.cyan("Copy package..."));
	fs.copySync('package', relativePath);

	console.log(chalk.cyan("Add name mark..."));
	replaceText(path.join(relativePath, '/modinfo.lua'), /name = "Additional Item Package"/g, 'name = "Additional Item Package (output)"');
}

console.log(chalk.green("All finished!"));