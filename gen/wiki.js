// 将掌上饥荒数据导出一份

(async () => {
    async function getData(url) {
        const ret = await fetch(url);
        return await ret.json();
    }

    const ret = await getData('https://fireleaves.cn/mods/single?id=6045d32fe3a3fb1f530b75c0');
    console.log(ret);
})();