const { argv } = require('yargs');
const path = require('path');
const { spawnSync } = require('child_process');
// ktools\\krane.exe $1\\anim.bin $1\\build.bin $1\\output

const { _: [resPath] } = argv;

const animPath = path.resolve(path.join(resPath, 'anim.bin'));
const buildPath = path.resolve(path.join(resPath, 'build.bin'));
const outPath = path.resolve(path.join(resPath, 'output'));

spawn(path.resolve('./tools-scripts/ktools/krane.exe'), [animPath, buildPath, outPath])

console.log(animPath, buildPath, outPath);