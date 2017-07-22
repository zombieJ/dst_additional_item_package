rm -rf package/
mkdir -p package/images/inventoryimages
cp -r anim package/
cp -r images/inventoryimages/*.tex package/images/inventoryimages/
cp -r images/inventoryimages/*.xml package/images/inventoryimages/
cp -r scripts package/
cp modicon.tex package/
cp modicon.xml package/
cp modinfo.lua package/
cp modmain.lua package/