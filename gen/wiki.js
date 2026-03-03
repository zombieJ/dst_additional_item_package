// 将掌上饥荒数据导出一份

(async () => {
    async function getData(url) {
        const ret = await fetch(url);
        return await ret.json();
    }

    const ret = await getData('https://fireleaves.cn/mods/single?id=6045d32fe3a3fb1f530b75c0');
    console.log(ret.tagList);

    const typeMap = {
        materials: 'materials',
        natures: 'nature',
        foods: 'food',
        '': 'food',
        animals: 'anim',
    };

    const tagInfoPromises = ret.tagList.map(async tag => {
        const type = typeMap[tag.type];
        const url = `https://fireleaves.cn/${type}?version=DST&tagId=${tag._id}`;
        const list = await getData(url);
        console.log(url, type, tag, JSON.stringify(list));

        const itemMap = {
            materials: 'material',
            natures: 'nature',
            foods: 'food',
            '': 'food',
            animals: 'anim',
        };

        return {
            name: tag.name,
            type,
            list: await Promise.all(list.map(async item => await getData(
                `https://fireleaves.cn/${itemMap[tag.type]}/single?id=${item._id}`
            ))),
        };
    });

    const data = await Promise.all(tagInfoPromises);
    console.log(data);
})();
