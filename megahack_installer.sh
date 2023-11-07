#!/bin/bash
clear
echo "MegaHack Pro Installer for Linux"
echo ""

if [ "$DEBUG" == "1" ]; then
   echo "Debug logging enabled!"
fi

# check for required packages
missing_packages=false
if ! hash unzip 2>/dev/null; then echo "unzip is not installed!"; missing_packages=true; fi
if ! hash 7z 2>/dev/null; then echo "p7zip is not installed!"; missing_packages=true; fi
if ! hash xclip 2>/dev/null; then echo "xclip is not installed, you will have to manually copy the MegaHack path!"; fi

echo ""
if [ $missing_packages == true ] ; then
   echo "You are missing some programs."
   echo "Please install them using your distro's package manager to continue."
   echo "Additional information can be found above."
   exit 0
fi

echo "(most terminals support drag and drop)"
read -p "Please enter the path to your MegaHack Pro .zip / .7z file: " megahack_zip
echo ""
if ! [ -f "$megahack_zip" ]; then
   echo "Could not find the file you specified!"
   exit
fi

echo "Finding your steam path ..."
if [ -f "$HOME/.steampid" ]; then
   steam_pid=`cat $HOME/.steampid`
   echo "Steam PID: $steam_pid"
   possible_path=`readlink -e /proc/$steam_pid/cwd`
fi

if ! [ -d "$possible_path" ]; then
   echo "Steam is not running, couldn't find directory from process"
   echo "Searching manually, this can take a few seconds ..."
   possible_path=`find ~ -name 'steamapps' | grep -v compatdata | sed 's/steamapps//g'`
fi

steam_path=""
if ! [ -z "$possible_path" ]; then
   echo "Is this your Steam path?: $possible_path"
   echo ""
   read -p "[Y/n] :" answer
   if [ "${answer,,}" == "y" ] || [ "${answer}" == "" ]; then
      steam_path="$possible_path"
   fi
   if [ "${answer,,}" == "n" ]; then
      echo ""
      read -p "Please enter your Steam path: " in_path
      steam_path="$in_path"
   fi
else
   echo ""
   read -p "Please enter your Steam path: " in_path
   steam_path="$in_path"
fi

steam_path=${steam_path%/}
echo "Using Steam path: $steam_path"

# find proton version
if [ -d "${steam_path}/steamapps/common/Proton - Experimental" ]; then proton_dir="${steam_path}/steamapps/common/Proton - Experimental"; fi
if [ -d "${steam_path}/steamapps/common/Proton 7.0" ]; then proton_dir="${steam_path}/steamapps/common/Proton 7.0"; fi
if [ -d "${steam_path}/compatibilitytools.d/GE-Proton7-43" ]; then proton_dir="${steam_path}/compatibilitytools.d/GE-Proton7-43"; fi # preferred version; more stable

if [ ! -d "${proton_dir}" ]; then
   echo "You dont have Proton Experimental, Proton 7.0 or GE-Proton7-43 installed!"
   echo "Please set Geometry Dash to use either one of those versions (GE preferred)"
   echo "To do that, go to GD's Steam page, click \"Properties\" > \"Compatibility\", enable \"Force the use of a specific Steam Play compatibility tool\" and select Proton 7.0 or Proton Experimental!"
   echo "Proton GE has to be installed manually, use Proton 7.0 or Experimental if you are unsure how to do that."
   echo "You have to start Geometry Dash at least once after changing it for Steam to download the new Proton version."
   exit 1
fi

echo "Using ${proton_dir}"

# clear temporary files
rm -rf "/tmp/megahack" 2>/dev/null
mkdir "/tmp/megahack" 2>/dev/null

echo "Extracting MegaHack Patcher ..."
echo "$megahack_zip"
if [[ $megahack_zip == *.zip ]]; then
   echo "zip"
   unzip "$megahack_zip" -d /tmp/megahack
else
   if [[ $megahack_zip == *.7z ]]; then
      echo "7z"
      7z x "$megahack_zip" -o/tmp/megahack
   else
      echo "unsupported file type"
      exit
   fi
fi

# find out where megahack is
megahack_dir=`ls /tmp/megahack`
if [ "$DEBUG" == "1" ]; then
   echo "-- contents of /tmp/megahack --"
   echo "$megahack_dir"
   echo "-- -- -- -- -- - -- -- -- -- --"
fi

megahack_dir="/tmp/megahack/$megahack_dir"

megahack_dir_contents=`ls "$megahack_dir"`

if [ "$DEBUG" == "1" ]; then
   echo "MegaHack Directory: $megahack_dir"
   echo " -- Contents --"
   echo "$megahack_dir_contents"
   echo " -- -- -- -- --"
fi

megahack_exe=`echo "$megahack_dir_contents" | grep ".exe"`

echo "Extracted MegaHack"
echo "Directory: $megahack_dir"
echo "Installer Executable: $megahack_exe"
echo ""

echo " - Starting installation process - "

if [ "$DEBUG" == "1" ]; then echo "cd ${steam_path}/steamapps/compatdata/322170/pfx"; fi
cd "${steam_path}/steamapps/compatdata/322170/pfx"

STEAM_COMPAT_DATA_PATH="${steam_path}/steamapps/compatdata/322170" WINEPREFIX="$PWD" steam-run "${proton_dir}/proton" runinprefix regedit /tmp/megahack/tmp.reg

if ! [ "$DEBUG" == "1" ]; then clear; fi
echo "Starting MegaHack installer ..."
echo ""
echo "To install, press CTRL+V when you are in the exe selection window and click \"Open\""

# copy path to gd exe
gd_exe_path=$(echo "Z:${steam_path}/steamapps/common/Geometry Dash/GeometryDash.exe" | sed 's:/:\\:g')

echo "Path to GD exe: $gd_exe_path"

if hash xclip 2>/dev/null; then
   echo "$gd_exe_path" | xclip -selection c
   echo "Copied path to clipboard!"
else
   echo "xclip is not installed, please copy the path manually"
fi
echo ""

echo "WARNING! If you want to install MegaHack v7, you will either have to"
echo "use MHv6's libcurl.dll OR add 'WINEDLLOVERRIDES=\"Xinput9_1_0=n,b\" %command%'"
echo "to Geometry Dash's start options in Steam OR MEGAHACK WON'T WORK!"
echo "Do you wan't to use v6's libcurl.dll method?"
read -p "[Y/n] :" answer_libcurl
   if [ "${answer_libcurl,,}" == "y" ] || [ "${answer_libcurl}" == "" ]; then
      use_v6_libcurl=1
fi

if [ "$DEBUG" == "1" ]; then
   echo "Starting MegaHack:"
   echo "STEAM_COMPAT_DATA_PATH=\"${steam_path}/steamapps/compatdata/322170\" WINEPREFIX=\"$PWD\" \"${proton_dir}/proton\" runinprefix \"${megahack_dir}/${megahack_exe}\""
fi

STEAM_COMPAT_DATA_PATH="${steam_path}/steamapps/compatdata/322170" WINEPREFIX="$PWD" steam-run "${proton_dir}/proton" runinprefix "${megahack_dir}/${megahack_exe}"

if [ "$use_v6_libcurl" == "1" ]; then
   echo "Warning: using v6's libcurl.dll to load!"
   # this allows megahack v7 to load
   cd "${steam_path}/steamapps/common/Geometry Dash"
   rm libcurl.dll
   echo "Downloading v6 libcurl.dll"
   wget -O "/tmp/megahack/libcurl.dll" "https://raw.githubusercontent.com/RoootTheFox/Linux-MegaHack-Installer/main/libcurl.dll"
   cp "/tmp/megahack/libcurl.dll" .
   mv hackproldr.dll absoluteldr.dll
fi

echo ""
echo "Cleaning up ..."
rm -rf "/tmp/megahack" 2>/dev/null
echo ""
echo "If you followed the steps in the installer, MegaHack Pro should now be installed!"
echo "Have fun!"
echo ""

sleep 0.2
exit 0
