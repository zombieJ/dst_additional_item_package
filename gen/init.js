// 初始化整个项目，用于生成对应的 anim 文件

const chalk = require('chalk');
const path = require('path');
const fs = require('fs-extra');
const { spawnSync } = require('child_process');

function run() {
  // ========================== Get Tool Path ==========================
  const prjPath = process.cwd();
  console.log(chalk.cyan('Prepare project enviroment...'));

  const toolPath = path.resolve(
    prjPath,
    '..',
    '..',
    '..',
    "Don't Starve Mod Tools",
    'mod_tools',
    'autocompiler.exe'
  );
  console.log(chalk.yellow('Tool:'), toolPath);

  if (!fs.existsSync(toolPath)) {
    console.log(chalk.red('Tool path not exist! Stop...'));
    return;
  }

  // ======================== Cache All Exports ========================
  const tmpPath = path.relative(prjPath, 'tmp');
  fs.removeSync(tmpPath);
  fs.ensureDirSync(tmpPath);

  fs.copySync(
    path.resolve(prjPath, 'exported'),
    path.resolve(tmpPath, 'exported')
  );
  fs.copySync(
    path.resolve(prjPath, 'exported_done'),
    path.resolve(tmpPath, 'exported_done')
  );

  try {
    // =============== Move all exists files to exported ===============
    const fileList = fs.readdirSync(path.resolve(prjPath, 'exported_done'));
    fileList.forEach(fileName => {
      fs.copySync(
        path.resolve(prjPath, 'exported_done', fileName),
        path.resolve(prjPath, 'exported', fileName)
      );
    });

    // ========================= Execute Tools =========================
    spawnSync(toolPath, {
      stdio: [null, process.stdout, process.stderr]
    });
    console.log(chalk.green('Done!'));
  } catch (err) {
    console.error(err);
  } finally {
    console.log(chalk.cyan('Restore files'));
    fs.removeSync(path.resolve(prjPath, 'exported'));
    fs.moveSync(
      path.resolve(tmpPath, 'exported'),
      path.resolve(prjPath, 'exported')
    );
  }
}

run();
