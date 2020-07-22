const { argv } = require('yargs');
const path = require('path');
const { spawnSync } = require('child_process');
// ktools\\krane.exe $1\\anim.bin $1\\build.bin $1\\output

let { _: [resPath] } = argv;
if (resPath.endsWith('"')) {
	resPath = resPath.slice(0, -1);
}

const animPath = path.resolve(path.join(resPath, 'anim.bin'));
const buildPath = path.resolve(path.join(resPath, 'build.bin'));
const outPath = path.resolve(path.join(resPath, 'output'));

const ret = spawnSync(path.resolve('./tools-scripts/ktools/krane.exe'), [animPath, buildPath, outPath]);

if (ret.stdout) console.log(ret.stdout.toString());
if (ret.stderr) console.error(ret.stderr.toString());
