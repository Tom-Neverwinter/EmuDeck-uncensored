#!/bin/bash

#variables
Eden_emuName="eden"
Eden_emuType="$emuDeckEmuTypeAppImage"
Eden_emuPath="$emusFolder/Eden.AppImage"

Eden_configFile="$HOME/.config/eden/qt-config.ini"
Eden_inputConfigFile="$HOME/.config/eden/input/emudeck.ini"

# https://github.com/eden-emu/eden/blob/master/src/core/file_sys/control_metadata.cpp#L41-L60
declare -A Eden_languages
Eden_languages=(
["ja"]=0
["en"]=1
["fr"]=2
["de"]=3
["it"]=4
["es"]=5
["zh"]=6
["ko"]=7
["nl"]=8
["pt"]=9
["ru"]=10
["tw"]=11) # TODO: not all langs but we need to switch to full lang codes to support those

# https://github.com/eden-emu/eden/blob/master/src/eden/configuration/configure_system.ui#L272-L309
declare -A Eden_regions
Eden_regions=(
["ja"]=0 # Japan
["en"]=1 # USA
["fr"]=2 # Europe
["de"]=2 # Europe
["it"]=2 # Europe
["es"]=2 # Europe
["zh"]=4 # China
["ko"]=5 # Korea
["nl"]=2 # Europe
["pt"]=2 # Europe
["ru"]=2 # Europe?
["tw"]=6 # Taiwan
) # TODO: split lang from region?

#cleanupOlderThings
Eden_cleanup() {
    echo "Begin Eden Cleanup"
    #Fixes repeated Symlink for older installations
}

#Install
Eden_install() {
  setMSG "Begin Eden Install"

  local showProgress=$1
  local releasesURL="https://git.eden-emu.dev/eden-ci/nightly/releases/"
  local releasePage
  local downloadURL
  local latestVer
  local lastVerFile="$emudeckFolder/eden.ver"

  releasePage=$(curl -fLs "$releasesURL") || return 1
  downloadURL=$(grep -Eo 'https://nightly\.eden-emu\.dev/[^"]*/Eden-Linux-[^"]*-steamdeck-clang-pgo\.AppImage' <<< "$releasePage" | head -n 1)

  if [[ -z "$downloadURL" ]]; then
      downloadURL=$(grep -Eo 'https://nightly\.eden-emu\.dev/[^"]*/Eden-Linux-[^"]*-steamdeck-gcc-standard\.AppImage' <<< "$releasePage" | head -n 1)
  fi

  if [[ -z "$downloadURL" ]]; then
      echo "Could not find a Steam Deck Eden AppImage in $releasesURL"
      return 1
  fi

  latestVer=$(basename "$downloadURL" | sed -E 's/^Eden-Linux-([^-]+)-.*$/\1/')

  installEmuAI "$Eden_emuName" "$Eden_emuName" "$downloadURL" "Eden" "AppImage" "$Eden_emuType" "$showProgress" "$lastVerFile" "$latestVer"
  return $?

  # Llamada a la API para obtener la última release
#   local response=$(curl -s "https://git.eden-emu.org/api/v1/repos/Eden/Eden/releases")
#
#   if installEmuBI "$Eden_emuName" "$( echo "$response" | jq -r '.[0].assets[] | select(.name | contains("Linux")) | .browser_download_url ' | head -n 1)" "$Eden_emuName" "tar.gz" "$showProgress"; then
#     mkdir -p "$emusFolder/eden"
#     tar -xvf "$emusFolder/$Eden_emuName.tar.gz" --strip-components=1 -C "$emusFolder/eden" && rm -rf "$HOME/Applications/$Eden_emuName.tar.gz"
#     chmod +x "$emusFolder/eden/eden"
#   else
#     return 1
#   fi

#     local success="false"
#     if installEmuAI "$Eden_emuName" "$(getReleaseURLGH "eden-appimage/eden-appimage" "AppImage")" "" "$showProgress" "" ""; then
#         success="true"
#     fi
#
#     if [ "$success" != "true" ]; then
#         return 1
#     fi

}

#ApplyInitialSettings
Eden_init() {
    echo "Begin Eden Init"

	cp "$emudeckBackend/tools/launchers/eden.sh" "$toolsPath/launchers/eden.sh"
	chmod +x "$toolsPath/launchers/eden.sh"
    mkdir -p "$HOME/.config/eden"
    mkdir -p "$HOME/.local/share/eden"
	rsync -avhp "$emudeckBackend/configs/eden/config/." "$HOME/.config/eden"
	rsync -avhp "$emudeckBackend/configs/eden/data/." "$HOME/.local/share/eden"

    configEmuAI "$Eden_emuName" "config" "$HOME/.config/eden" "$emudeckBackend/configs/eden/config" "true"
    configEmuAI "$Eden_emuName" "data" "$HOME/.local/share/eden" "$emudeckBackend/configs/eden/data" "true"

    Eden_setEmulationFolder
    Eden_setupStorage
    Eden_setupSaves
    Eden_applyControllerLayout
    Eden_finalize
    Eden_addParser
    Eden_flushEmulatorLauncher
  	createDesktopShortcut   "$HOME/.local/share/applications/eden.desktop" \
							"Eden (AppImage)" \
							"${toolsPath}/launchers/eden.sh"  \
							"False"

	if [ -e "$ESDE_toolPath" ] || [ -f "${toolsPath}/$ESDE_downloadedToolName" ] || [ -f "${toolsPath}/$ESDE_oldtoolName.AppImage" ]; then
		Eden_addESConfig
	else
		echo "ES-DE not found. Skipped adding custom system."
	fi

    #Eden_setLanguage

}

#update
Eden_update() {
    echo "Begin Eden update"

    Eden_init
}

#ConfigurePaths
Eden_setEmulationFolder() {
    echo "Begin Eden Path Config"

    screenshotDirOpt='Screenshots\\screenshot_path='
    gameDirOpt='Paths\\gamedirs\\4\\path='
    dumpDirOpt='dump_directory='
    loadDir='load_directory='
    nandDirOpt='nand_directory='
    sdmcDirOpt='sdmc_directory='
    tasDirOpt='tas_directory='
    newScreenshotDirOpt='Screenshots\\screenshot_path='"${storagePath}/eden/screenshots"
    newGameDirOpt='Paths\\gamedirs\\4\\path='"${romsPath}/switch"
    newDumpDirOpt='dump_directory='"${storagePath}/eden/dump"
    newLoadDir='load_directory='"${storagePath}/switch/load"
    newNandDirOpt='nand_directory='"${storagePath}/eden/nand"
    newSdmcDirOpt='sdmc_directory='"${storagePath}/switch/sdmc"
    newTasDirOpt='tas_directory='"${storagePath}/eden/tas"

    sed -i "/${screenshotDirOpt}/c\\${newScreenshotDirOpt}" "$Eden_configFile"
    sed -i "/${gameDirOpt}/c\\${newGameDirOpt}" "$Eden_configFile"
    sed -i "/${dumpDirOpt}/c\\${newDumpDirOpt}" "$Eden_configFile"
    sed -i "/${loadDir}/c\\${newLoadDir}" "$Eden_configFile"
    sed -i "/${nandDirOpt}/c\\${newNandDirOpt}" "$Eden_configFile"
    sed -i "/${sdmcDirOpt}/c\\${newSdmcDirOpt}" "$Eden_configFile"
    sed -i "/${tasDirOpt}/c\\${newTasDirOpt}" "$Eden_configFile"

    #Setup Bios symlinks
    unlink "${biosPath}/eden/keys" 2>/dev/null
    unlink "${biosPath}/eden/firmware" 2>/dev/null

    mkdir -p "$HOME/.local/share/eden/keys/"
    mkdir -p "${storagePath}/switch/nand/system/Contents/registered/"
    mkdir -p "${biosPath}/eden"
    ln -sn "$HOME/.local/share/eden/keys/" "${biosPath}/eden/keys"
    ln -sn "${storagePath}/switch/nand/system/Contents/registered/" "${biosPath}/eden/firmware"
    touch "${storagePath}/switch/nand/system/Contents/registered/putfirmwarehere.txt"

}

#SetLanguage
Eden_setLanguage(){
    setMSG "Setting Eden Language"
    local language=$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)
    languageOpt="language_index="
    languageDefaultOpt="language_index\\\\default="
    newLanguageDefaultOpt="language_index\\\\default=false" # we need those or else itll reset
    regionOpt="region_index="
    regionDefaultOpt="region_index\\\\default="
    newRegionDefaultOpt="region_index\\\\default=false"
	#TODO: call this somewhere, and input the $language from somewhere (args?)
	if [[ -f "${Eden_configFile}" ]]; then
		if [ ${Eden_languages[$language]+_} ]; then
            newLanguageOpt='language_index='"${Eden_languages[$language]}"
            newRegionOpt='region_index='"${Eden_regions[$language]}"
            changeLine "$languageOpt" "$newLanguageOpt" "$Eden_configFile"
            changeLine "$languageDefaultOpt" "$newLanguageDefaultOpt" "$Eden_configFile"
            changeLine "$regionOpt" "$newRegionOpt" "$Eden_configFile"
            changeLine "$regionDefaultOpt" "$newRegionDefaultOpt" "$Eden_configFile"
		fi
	fi
}

#SetupSaves
Eden_setupSaves() {
    echo "Begin Eden save link"
    unlink "${savesPath}/eden/saves" 2>/dev/null # Fix for previous bad symlink2>/dev/null
    linkToSaveFolder eden saves "${storagePath}/eden/nand/user/save/"
    linkToSaveFolder eden profiles "${storagePath}/eden/nand/system/save/8000000000000010/su/avators/"
}

#SetupStorage
Eden_setupStorage() {
    echo "Begin Eden storage config"
    mkdir -p "${storagePath}/eden/dump"
    mkdir -p "${storagePath}/eden/nand"
    mkdir -p "${storagePath}/eden/screenshots"
    mkdir -p "${storagePath}/eden/tas"
    Switch_setupYuzuFamilySharedStorage eden
    #Symlink to saves for CloudSync
    ln -sn "${storagePath}/eden/nand/system/save/8000000000000010/su/avators/" "${savesPath}/eden/profiles"
}

#WipeSettings
Eden_wipe() {
    echo "Begin Eden delete config directories"
    rm -rf "$HOME/.config/eden"
    rm -rf "$HOME/.local/share/eden"
}

#Uninstall
Eden_uninstall() {
    echo "Begin Eden uninstall"
    removeParser "nintendo_switch_eden.json"
    rm -rf "$Eden_emuPath"
    find "$emusFolder" -maxdepth 1 -iname "eden*.AppImage" -exec rm -f {} +
}

Eden_setupControls() {
    if [ ! -f "$Eden_configFile" ]; then
        return 0
    fi

    local button_a="${1:-0}"
    local button_b="${2:-1}"
    local button_x="${3:-2}"
    local button_y="${4:-3}"
    local guid="03000000de280000ff11000001000000"

    updateOrAppendConfigLine "$Eden_configFile" "enable_all_controllers=" "enable_all_controllers=true"
    updateOrAppendConfigLine "$Eden_configFile" "enable_all_controllers\\default=" "enable_all_controllers\\default=false"

    for player in 0 1 2 3 4; do
        local prefix="player_${player}"

        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_a=" "${prefix}_button_a=\"engine:sdl,port:${player},guid:${guid},button:${button_a}\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_a\\default=" "${prefix}_button_a\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_b=" "${prefix}_button_b=\"engine:sdl,port:${player},guid:${guid},button:${button_b}\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_b\\default=" "${prefix}_button_b\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_ddown=" "${prefix}_button_ddown=\"engine:sdl,port:${player},guid:${guid},direction:down,hat:0\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_ddown\\default=" "${prefix}_button_ddown\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_dleft=" "${prefix}_button_dleft=\"engine:sdl,port:${player},guid:${guid},direction:left,hat:0\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_dleft\\default=" "${prefix}_button_dleft\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_dright=" "${prefix}_button_dright=\"engine:sdl,port:${player},guid:${guid},direction:right,hat:0\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_dright\\default=" "${prefix}_button_dright\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_dup=" "${prefix}_button_dup=\"engine:sdl,port:${player},guid:${guid},direction:up,hat:0\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_dup\\default=" "${prefix}_button_dup\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_home=" "${prefix}_button_home=\"engine:sdl,port:${player},guid:${guid},button:8\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_home\\default=" "${prefix}_button_home\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_l=" "${prefix}_button_l=\"engine:sdl,port:${player},guid:${guid},button:4\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_l\\default=" "${prefix}_button_l\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_lstick=" "${prefix}_button_lstick=\"engine:sdl,port:${player},guid:${guid},button:9\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_lstick\\default=" "${prefix}_button_lstick\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_minus=" "${prefix}_button_minus=\"engine:sdl,port:${player},guid:${guid},button:6\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_minus\\default=" "${prefix}_button_minus\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_plus=" "${prefix}_button_plus=\"engine:sdl,port:${player},guid:${guid},button:7\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_plus\\default=" "${prefix}_button_plus\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_r=" "${prefix}_button_r=\"engine:sdl,port:${player},guid:${guid},button:5\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_r\\default=" "${prefix}_button_r\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_rstick=" "${prefix}_button_rstick=\"engine:sdl,port:${player},guid:${guid},button:10\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_rstick\\default=" "${prefix}_button_rstick\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_screenshot=" "${prefix}_button_screenshot=[empty]"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_screenshot\\default=" "${prefix}_button_screenshot\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_sl=" "${prefix}_button_sl=\"engine:sdl,port:${player},guid:${guid},button:4\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_sl\\default=" "${prefix}_button_sl\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_sr=" "${prefix}_button_sr=\"engine:sdl,port:${player},guid:${guid},button:5\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_sr\\default=" "${prefix}_button_sr\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_x=" "${prefix}_button_x=\"engine:sdl,port:${player},guid:${guid},button:${button_x}\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_x\\default=" "${prefix}_button_x\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_y=" "${prefix}_button_y=\"engine:sdl,port:${player},guid:${guid},button:${button_y}\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_y\\default=" "${prefix}_button_y\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_zl=" "${prefix}_button_zl=\"engine:sdl,port:${player},guid:${guid},axis:2,threshold:0.500000,invert:+\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_zl\\default=" "${prefix}_button_zl\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_zr=" "${prefix}_button_zr=\"engine:sdl,port:${player},guid:${guid},axis:5,threshold:0.500000,invert:+\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_button_zr\\default=" "${prefix}_button_zr\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_connected=" "${prefix}_connected=true"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_connected\\default=" "${prefix}_connected\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_lstick=" "${prefix}_lstick=\"engine:sdl,port:${player},guid:${guid},axis_x:0,offset_x:-0.000000,axis_y:1,offset_y:0.000000,invert_x:+,invert_y:+,deadzone:0.150000\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_lstick\\default=" "${prefix}_lstick\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_motionleft=" "${prefix}_motionleft=[empty]"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_motionleft\\default=" "${prefix}_motionleft\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_motionright=" "${prefix}_motionright=[empty]"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_motionright\\default=" "${prefix}_motionright\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_rstick=" "${prefix}_rstick=\"engine:sdl,port:${player},guid:${guid},axis_x:3,offset_x:-0.000000,axis_y:4,offset_y:0.000000,invert_x:+,invert_y:+,deadzone:0.150000\""
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_rstick\\default=" "${prefix}_rstick\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_type=" "${prefix}_type=0"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_type\\default=" "${prefix}_type\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_vibration_enabled=" "${prefix}_vibration_enabled=true"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_vibration_enabled\\default=" "${prefix}_vibration_enabled\\default=false"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_vibration_strength=" "${prefix}_vibration_strength=100"
        updateOrAppendConfigLine "$Eden_configFile" "${prefix}_vibration_strength\\default=" "${prefix}_vibration_strength\\default=false"
    done

    if [ -f "$Eden_inputConfigFile" ]; then
        updateOrAppendConfigLine "$Eden_inputConfigFile" "button_a=" "button_a=\"button:${button_a},guid:${guid},port:0,engine:sdl\""
        updateOrAppendConfigLine "$Eden_inputConfigFile" "button_b=" "button_b=\"button:${button_b},guid:${guid},port:0,engine:sdl\""
        updateOrAppendConfigLine "$Eden_inputConfigFile" "button_x=" "button_x=\"button:${button_x},guid:${guid},port:0,engine:sdl\""
        updateOrAppendConfigLine "$Eden_inputConfigFile" "button_y=" "button_y=\"button:${button_y},guid:${guid},port:0,engine:sdl\""
        updateOrAppendConfigLine "$Eden_inputConfigFile" "type\\default=" "type\\default=false"
    fi
}

Eden_applyControllerLayout() {
    if [ "$controllerLayout" == "bayx" ] || [ "$controllerLayout" == "baxy" ]; then
        Eden_setBAYXstyle
    else
        Eden_setABXYstyle
    fi
}

#setABXYstyle
Eden_setABXYstyle() {
    Eden_setupControls 0 1 2 3
}

#setBAYXstyle
Eden_setBAYXstyle() {
    Eden_setupControls 1 0 3 2
}

#WideScreenOn
Eden_wideScreenOn() {
    echo "NYI"
}

#WideScreenOff
Eden_wideScreenOff() {
    echo "NYI"
}

#BezelOn
Eden_bezelOn() {
    echo "NYI"
}

#BezelOff
Eden_bezelOff() {
    echo "NYI"
}

#finalExec - Extra stuff
Eden_finalize() {
    echo "Begin Eden finalize"
    Eden_cleanup
}

Eden_IsInstalled() {
    local appimage
    appimage=$(find "$emusFolder" -maxdepth 1 -iname "eden*.AppImage" -print -quit 2>/dev/null)
    if [ -n "$appimage" ] || /usr/bin/flatpak list --app --columns=application 2>/dev/null | grep -iq "eden"; then
        echo "true"
    else
        echo "false"
    fi
}


Eden_resetConfig() {
    Eden_init &>/dev/null && echo "true" || echo "false"
}



Eden_setResolution(){

	case $edenResolution in
		"720P") multiplier=2; docked="false";;
		"1080P") multiplier=2; docked="true";;
		"1440P") multiplier=3; docked="false";;
		"4K") multiplier=3; docked="true";;
		*) echo "Error"; return 1;;
	esac

	RetroArch_setConfigOverride "resolution_setup" $multiplier "$Eden_configFile"
	RetroArch_setConfigOverride "use_docked_mode" $docked "$Eden_configFile"
}

Eden_flushEmulatorLauncher(){


	flushEmulatorLaunchers "eden"

}

Eden_addESConfig(){

    ESDE_junksettingsFile
    ESDE_addCustomSystemsFile
    ESDE_setEmulationFolder

	if [[ $(grep -rnw "$es_systemsFile" -e 'switch') == "" ]]; then
		xmlstarlet ed -S --inplace --subnode '/systemList' --type elem --name 'system' \
		--var newSystem '$prev' \
		--subnode '$newSystem' --type elem --name 'name' -v 'switch' \
		--subnode '$newSystem' --type elem --name 'fullname' -v 'Nintendo Switch' \
		--subnode '$newSystem' --type elem --name 'path' -v '%ROMPATH%/switch' \
		--subnode '$newSystem' --type elem --name 'extension' -v '.nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI' \
		--subnode '$newSystem' --type elem --name 'commandB' -v "%EMULATOR_RYUJINX% %ROM%" \
		--insert '$newSystem/commandB' --type attr --name 'label' --value "Ryujinx (Standalone)" \
		--subnode '$newSystem' --type elem --name 'commandV' -v "%INJECT%=%BASENAME%.esprefix %EMULATOR_EDEN% -f -g %ROM%" \
		--insert '$newSystem/commandV' --type attr --name 'label' --value "Eden (Standalone)" \
		--subnode '$newSystem' --type elem --name 'platform' -v 'switch' \
		--subnode '$newSystem' --type elem --name 'theme' -v 'switch' \
		-r 'systemList/system/commandB' -v 'command' \
		-r 'systemList/system/commandV' -v 'command' \
		"$es_systemsFile"

		xmlstarlet fo "$es_systemsFile" > "$es_systemsFile".tmp && mv "$es_systemsFile".tmp "$es_systemsFile"
	fi
	#Custom Systems config end

	ESDE_refreshCustomEmus
}


Eden_addParser(){
  addParser "nintendo_switch_eden.json"
}
