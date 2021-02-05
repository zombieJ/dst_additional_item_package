const { argv } = require("yargs");
const path = require("path");
const { spawnSync } = require("child_process");

let {
  _: [resPath],
} = argv;
if (resPath.endsWith('"')) {
  resPath = resPath.slice(0, -1);
}

const texPath = path.resolve(resPath);

const ret = spawnSync(path.resolve("./tools-scripts/ktools/ktech.exe"), [
  "-v",
  "-v",
  "-v",
  "-v",
  "-v",
  "-Q 100",
  "--width 512",
  texPath,
  texPath.replace(/\.tex$/, ".png"),
]);

if (ret.stdout) console.log(ret.stdout.toString());
if (ret.stderr) console.error(ret.stderr.toString());
