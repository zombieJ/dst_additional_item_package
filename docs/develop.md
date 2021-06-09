# 开发须知

# 项目目录结构

| 文件名                        | 描述                           |
| ----------------------------- | ------------------------------ |
| modmain.lua                   | 配置预加载资源与物品           |
| modinfo.lua                   | 描述信息，配置 mod 预览页面    |
| exported                      | 导出的文件                     |
| scripts                       |                                |
| scripts/prefabs               | 物品文件夹                     |
| scripts/components            | 组件，物品的功能是由组件提供的 |
| widgets                       | 界面相关内容                   |
| images                        |                                |
| images/inventoryimages        | 物品图片文件夹                 |
| images/inventoryimages/\*.tex | 物品编译图片                   |
| images/inventoryimages/\*.xml | 物品图片配置信息               |

# 开发目录结构

| 文件名          | 描述                                                       |
| --------------- | ---------------------------------------------------------- |
| exported_done   | 已经导出的文件                                             |
| gen             | 生成工具集                                                 |
| gen.cutTextXml  |                                                            |
| gen.foodPreview | 生成预览食物图片，用于 steam mod 页面                      |
| gen.seed        | 种子文件                                                   |
| gen.veggie      | 生成种子文件模板                                           |
| images_done     | 生成完成的图片，因为放在 images 下会被编译拖慢饥荒打开速度 |

# 开发 MOD

- [物品制作](./item.md)

## 替换 Symbol

https://www.it610.com/article/5028120.htm

## 动画队列结束

animqueueover

## 永远垂直

redlanternbody.lua

## 地图区块数据

TheWorld.topology.nodes
- type: NODE_TYPE.x
- poly
- tags
- cent [x, z]
- x
- y
- c
- neighbours
- area
- validedges: TheWorld.topology.edgeToNodes

TheWorld.topology.ids

## 找对象

simutil.lua

FindEntities(x, y, z, radius, musthavetags, nottags, hasoneoftags)

# apiUtils

提供了一些辅助方法

- aipPrint(...) 打印内容
- aipTypePrint(...) 打印内容，同时打印出类别
- aipGetModConfig(configName: string) 获取全局的 mod 配置信息
