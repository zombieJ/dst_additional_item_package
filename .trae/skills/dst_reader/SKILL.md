---
name: "dst_reader"
description: "读取DST游戏基础API和模组文件。开发模组时调用，优先从游戏源码查找API参考，然后读取模组文件进行开发。"
---

# DST Reader

## 功能
- 读取DST游戏基础API源码作为开发依赖参考
- 读取和分析模组文件
- 解析游戏API函数、组件、事件等基础代码
- 分析模组结构和内容
- 提取模组中的物品、配方、组件等信息
- **验证游戏方法是否存在**：在使用游戏API方法前，必须检查对应游戏文件确保方法存在

## 游戏基础源码路径
游戏基础脚本目录：`D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts`

## 适用场景
- 当用户需要查看游戏API文档或源码时
- 当用户需要了解某个游戏函数的实现时
- 当用户需要查找游戏组件的定义时
- 当用户需要参考游戏原有功能实现时
- 当用户需要查看模组文件内容时
- 当用户需要分析模组中的特定元素时
- **当需要使用游戏方法时，必须先验证方法是否存在**

## 使用方法
1. 调用dst_reader技能
2. 指定需要查找的API、函数、组件或文件路径
3. 技能会优先从游戏基础源码目录查找相关代码
4. 如果游戏源码中没有找到，再查找模组目录中的文件
5. **验证方法存在性**：在使用任何游戏方法前，读取对应游戏文件并搜索方法定义

## API查找优先级
1. 游戏基础源码：`D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts`
2. 模组目录：当前工作目录

## 方法验证规则
**重要**：在使用游戏的任何方法前，必须执行以下验证步骤：

1. 确定方法所属的组件或模块（如 `edible`、`eater`、`health` 等）
2. 读取对应的游戏源码文件（如 `components/edible.lua`）
3. 在文件中搜索方法定义（如 `function Edible:OnEaten`）
4. 确认方法存在后才能在代码中使用

### 验证示例
要使用 `edible` 组件的 `OnEaten` 方法：
1. 读取文件：`D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts\components\edible.lua`
2. 搜索：`function Edible:OnEaten`
3. 确认方法存在后，才能在代码中调用或重写此方法

## 支持的文件类型
- .lua 文件：游戏API和模组主要代码文件
- .xml 文件：模组配置文件
- .json 文件：模组数据文件
- .txt 文件：模组说明文件

## 常用游戏API目录
- `components/`：游戏组件定义
- `prefabs/`：游戏预制体定义
- `stategraphs/`：状态机定义
- `brains/`：AI行为定义
- `widgets/`：UI组件定义

## 示例
要查找某个游戏组件的实现：
1. 调用dst_reader技能
2. 指定组件名称：health
3. 技能会返回 `D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts\components\health.lua` 的内容
4. **验证方法**：搜索 `function Health:` 确认需要的方法存在

要查找某个游戏预制体的实现：
1. 调用dst_reader技能
2. 指定预制体名称：torch
3. 技能会返回 `D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts\prefabs\torch.lua` 的内容

要使用某个游戏方法：
1. 确定方法所属组件（如 `edible` 组件的 `OnEaten` 方法）
2. 读取游戏源码：`components/edible.lua`
3. 搜索方法定义：`function Edible:OnEaten`
4. 确认方法存在后，在代码中使用