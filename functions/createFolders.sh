#!/bin/bash

createFolders(){
	#Folder creation... This code is repeated outside of this if for the yes zenity mode
	mkdir -p "$emulationPath"
	mkdir -p "$toolsPath"/launchers
	mkdir -p "$savesPath"
	mkdir -p "$romsPath"
	mkdir -p "$storagePath"
	mkdir -p "$biosPath"/yuzu
	mkdir -p "$biosPath"/citron
	mkdir -p "$biosPath"/eden
	mkdir -p "$biosPath"/ryujinx
	mkdir -p "$storagePath"/switch/load
	mkdir -p "$storagePath"/switch/sdmc
	mkdir -p "$storagePath"/switch/nand/user/Contents
	mkdir -p "$storagePath"/switch/nand/system/Contents/registered
	mkdir -p "$storagePath"/switch/patchesAndDlc
	mkdir -p "$biosPath"/HdPacks
	mkdir -p "$biosPath"/Mupen64plus/cache
	mkdir -p "$emulationPath"/hdpacks

	##Generate rom folders
	setMSG "Creating roms folder in $romsPath"
	##remove old readme.txt
	find "$romsPath" -name readme.txt -type f -delete -maxdepth 2

	sleep 3
	rsync -r --ignore-existing "$emudeckBackend/roms/" "$romsPath"
	#End repeated code
}
