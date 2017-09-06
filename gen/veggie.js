const args = process.argv;

const FS = require('fs');
const PATH = require('path');
const Jimp = require("jimp");

// Get file path
const path = PATH.normalize(__dirname);
const veggieFolderPath = PATH.join(path, '..', 'veggies');

let veggiePath = (args[2] || '').replace(/[\\\/]$/, '');
const veggiePathArr = veggiePath.split(/[\\\/]/);
veggie = veggiePathArr[veggiePathArr.length - 1];

veggiePath = PATH.join(veggieFolderPath, veggie);

console.log('Veggie Path:\n', veggiePath);

// Check if is folder
if (!FS.lstatSync(veggiePath).isDirectory()) {
    console.error('Path is not a folder!');
    return;
}

// Check material
const originPath = PATH.join(veggiePath, 'origin');
const cookedPath = PATH.join(veggiePath, 'cooked');
const seedPath = PATH.join(veggiePath, 'seed');