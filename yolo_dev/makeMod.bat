del yolo.iwd
del mod.ff

xcopy braxi ..\..\raw\braxi /SY
xcopy fx ..\..\raw\fx /SY
xcopy images ..\..\raw\images /SY
xcopy maps ..\..\raw\maps /SY
xcopy materials ..\..\raw\materials /SY
xcopy sound ..\..\raw\sound /SY
xcopy soundaliases ..\..\raw\soundaliases /SY
xcopy ui_mp ..\..\raw\ui_mp /SY
xcopy weapons ..\..\raw\weapons /SY
xcopy xanim ..\..\raw\xanim /SY
xcopy xmodel ..\..\raw\xmodel /SY
xcopy xmodelparts ..\..\raw\xmodelparts /SY
xcopy xmodelsurfs ..\..\raw\xmodelsurfs /SY
copy /Y mod.csv ..\..\zone_source

7za a -r -tzip yolo.iwd images
7za a -r -tzip yolo.iwd weapons

cd ..\..\bin
linker_pc.exe -language english -compress -cleanup mod
cd ..\mods\yolo_dev
copy ..\..\zone\english\mod.ff


pause