const chalk = require('chalk');
const fs = require('fs-extra');

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

console.log(chalk.green("All finished!"));