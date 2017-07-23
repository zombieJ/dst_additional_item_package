rm -rf package/
mkdir -p package/images/inventoryimages
mkdir -p package/minimap

cp -r anim package/
cp -r images/inventoryimages/*.tex package/images/inventoryimages/
cp -r images/inventoryimages/*.xml package/images/inventoryimages/
cp -r minimap/*.tex package/minimap
cp -r minimap/*.xml package/minimap
cp -r scripts package/
cp modicon.tex package/
cp modicon.xml package/
cp modinfo.lua package/
cp modmain.lua package/

sed -i 's/"(DEV MODE)",//g' package/modinfo.lua
sed -i 's/name = "Additional Item Package DEV"/name = "Additional Item Package"/g' package/modinfo.lua
sed -i 's/TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package DEV"/TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package"/g' package/modmain.lua