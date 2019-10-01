echo "Clean up..."
rm -rf package/

echo "Create related folder..."
mkdir -p package/images/inventoryimages
mkdir -p package/minimap

echo "Copy resourse..."
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

echo "Replace DEV mark..."
sed -i 's/"(DEV MODE)",//g' package/modinfo.lua
sed -i 's/name = "Additional Item Package DEV"/name = "Additional Item Package"/g' package/modinfo.lua
sed -i 's/TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package DEV"/TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE = "Additional Item Package"/g' package/modmain.lua

if [[ -z $1 ]]; then
	echo "Done! You can add additional folder path to copy the tmp folder out."
else
	echo "Copy generated package to $1"

	echo " - cleanup..."
	rm -rf $1

	echo " - copy..."
	cp -r package $1

	echo " - add name mark..."
	sed -i 's/name = "Additional Item Package"/name = "Additional Item Package (output)"/g' $1/modinfo.lua

	echo " - done!"
fi