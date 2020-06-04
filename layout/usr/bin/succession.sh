#!/bin/bash
#TextEnding=`\e[0m"`
#RedText=`"\e[1;31m`
#GreenText=`"\e[1;32m`
echo -e "\e[1;32mWelcome to SuccessionCLI! Written by Samg_is_a_Ninja and Hassan’s Tech (demhademha)\e[0m"
echo -e "\e[1;32mSpecial thanks to pwn20wnd (mountpoint and rsync args) and wh0ba (storage space utils)\e[0m"
sleep 3
checkRoot=`whoami`
if [ $checkRoot != "root" ]; then
    echo -e "\e[1;31mSuccessionCLI needs to be run as root. Please \"su\" and try again. Alternatively, try \"ssh root@[IP Address]\"\e[0m"
    exit
fi
mkdir -p /private/var/mobile/Media/Succession/
#Contact helper tool to get iOS version and device model
ProductVersion=`SuccessionCLIhelper --deviceVersion`
#we are now going to get the product buildversion for example, 17c54 and set it as a variable   
ProductBuildVersion=`SuccessionCLIhelper --deviceBuildNumber`
#we now get the machine ID, (for example iPhone9,4), and store it as a variable
DeviceIdentifier=`SuccessionCLIhelper --deviceModel`
#we now need to get the actual device identifier for example, iPad 7,11 is iPad 7th generation 
curl --silent 'https://api.ipsw.me/v4/devices' -o /private/var/mobile/Media/Succession/devices.json
DeviceName=`SuccessionCLIhelper --deviceCommonName`
rm /private/var/mobile/Media/Succession/devices.json
#We’ll print these values that we have retrieved  
echo ""
echo -e "\e[1;32mYour $DeviceIdentifier aka $DeviceName is running iOS version $ProductVersion build $ProductBuildVersion\e[0m"
if [[ $ProductVersion == "9"* ]]; then
    if [[ $DeviceIdentifier == "iPhone8,1" ]] || [[ $DeviceIdentifier == "iPhone8,2" ]]; then
        echo -e "\e[1;31mSuccession is disabled: the iPhone 6s cannot be activated on iOS 9.\e[0m"
    fi
fi
curl --silent https://raw.githubusercontent.com/Samgisaninja/samgisaninja.github.io/master/motd-cli.plist -o /private/var/mobile/Media/Succession/motd.plist
shouldIRun=`SuccessionCLIhelper --shouldIRun`
if [[ $shouldIRun == "false" ]]; then
    echo -e "\e[1;31mFor your safety, Succession has been remotely disabled. Please try again at a later time.\e[0m"
fi
remoteMessage=`SuccessionCLIhelper --getMOTD`
if [[ $remoteMessage != "No MOTD" ]]; then
    echo $remoteMessage
fi
rm /private/var/mobile/Media/Succession/motd.plist
echo -e "\e[1;32mPlease make sure this information is accurate before continuing. Press enter to confirm or exit if inaccurate.\e[0m"
read varblank
shouldExtractIPSW=true
shouldDownloadIPSW=true
if [ -f /private/var/mobile/Media/Succession/rfs.dmg ]; then
    while true; do
        read -p $'\e[1;32mDetected provided rootfilesystem disk image, would you like to use it? (y/n) \e[0m' yn
        case $yn in
            [Yy]* ) shouldExtractIPSW=false; break;;
            [Nn]* ) shouldExtractIPSW=true; break;;
            * ) echo -e "\e[1;31mPlease answer yes or no.\e[0m";;
        esac
    done
fi
if ! $shouldExtractIPSW; then
    rm -rf /private/var/mobile/Media/Succession/ipsw*
    shouldDownloadIPSW=false
fi
if [ -f /private/var/mobile/Media/Succession/ipsw.ipsw ]; then
    while true; do
        read -p $'\e[1;32mDetected provided ipsw, would you like to use it? (y/n) \e[0m' yn
        case $yn in
            [Yy]* ) shouldDownloadIPSW=false; break;;
            [Nn]* ) shouldDownloadIPSW=true; break;;
            * ) echo -e "\e[1;31mPlease answer yes or no.\e[0m";;
        esac
    done
fi

if $shouldDownloadIPSW; then
    echo -e "\e[1;32mSuccession will download the correct IPSW for your device: press enter to proceed\e[0m"
    #print a warning message 
    echo -e "\e[1;32mOnce you press enter again, Succession will begin the download\e[0m"  
    echo -e "\e[1;32mDO NOT LEAVE TERMINAL\e[0m"
    echo -e "\e[1;32mDO NOT POWER OFF YOUR DEVICE\e[0m"  
    read varblank2   
    echo -e "\e[1;32mDownloading IPSW...\e[0m" 
    # Clean up any files from previous runs
    rm -rf /private/var/mobile/Media/Succession/*
    #we download the ipsw from apple’s servers through ipsw.me’s api
    #TODO: add pzb to just download what we need instead of the entire IPSW
    curl  -# -L -o /private/var/mobile/Media/Succession/partial.ipsw http://api.ipsw.me/v2.1/$DeviceIdentifier/$ProductBuildVersion/url/dl
    #now that the download is complete, rename "partial.ipsw" to "ipsw.ipsw"
    mv /private/var/mobile/Media/Succession/partial.ipsw /private/var/mobile/Media/Succession/ipsw.ipsw
fi
if $shouldExtractIPSW; then
    #we create a new directory to put the ipsw that is going to be extracted   
    # Clean up partially extracted ipsws from previous runs
    rm -rf /private/var/mobile/Media/Succession/ipsw/*
    # If this is the first run, we need a destination folder to dump to
    mkdir -p /private/var/mobile/Media/Succession/ipsw/
    # 7z is a much faster and more advanced zip tool, and most devices will have it.
    pathToSevenZ=`which 7z`
    if [ -x $pathToSevenZ ]; then
        echo -e "\e[1;32mVerifying IPSW...\e[0m"
        7z x -o/private/var/mobile/Media/Succession/ipsw /private/var/mobile/Media/Succession/ipsw.ipsw BuildManifest.plist
        buildManifestString=$(</private/var/mobile/Media/Succession/ipsw/BuildManifest.plist)
        if grep -q "$ProductBuildVersion" "/private/var/mobile/Media/Succession/ipsw/BuildManifest.plist"; then
            echo -e "\e[1;32mIPSW verified, extracting root filesystem...\e[0m"
            nameOfDMG=`7z l /private/var/mobile/Media/Succession/ipsw.ipsw | grep "dmg" | sort -k 4 | awk 'END {print $NF}'`
            7z x -o/private/var/mobile/Media/Succession/ipsw /private/var/mobile/Media/Succession/ipsw.ipsw $nameOfDMG
            echo -e "\e[1;32mMoving extracted files...\e[0m"
            mv /private/var/mobile/Media/Succession/ipsw/$nameOfDMG /private/var/mobile/Media/Succession/rfs.dmg
        else
            versionCheckOverride=false
            echo -e "\e[1;31m**********WARNING!**********\e[0m"
            echo -e "\e[1;31mThe IPSW provided does not appear to match the iOS version of this device\e[0m"
            echo -e "\e[1;31mATTEMPTING TO CHANGE YOUR iOS VERSION USING THIS TOOL WILL RESULT IN A BOOTLOOP\e[0m"
            while true; do
                read -p $'\e[1;31mWould you like to override this check and continue anyway? (y/n) \e[0m' yn
                case $yn in
                    [Yy]* ) versionCheckOverride=true; break;;
                    [Nn]* ) versionCheckOverride=false; break;;
                    * ) echo -e "\e[1;31mPlease answer yes or no.\e[0m";;
                esac
            done
            if $versionCheckOverride; then
                    echo -e "\e[1;31mVersion check overridden, continuing as if nothing went wrong...\e[0m"
                    nameOfDMG=`7z l /private/var/mobile/Media/Succession/ipsw.ipsw | grep "dmg" | sort -k 4 | awk 'END {print $NF}'`
                    7z x -o/private/var/mobile/Media/Succession/ipsw /private/var/mobile/Media/Succession/ipsw.ipsw $nameOfDMG
                    echo moving extracted files...
                    mv /private/var/mobile/Media/Succession/ipsw/$nameOfDMG /private/var/mobile/Media/Succession/rfs.dmg
            else
                    echo -e "\e[1;32mGood choice. Succession will now quit.\e[0m"
                    exit
            fi
        fi
    else 
        #we now navigate to the directory that we just created in order to save our extracted ipsw there after unzipping it 
        echo -e "\e[1;32mExtracting IPSW...\e[0m"  
        cd /private/var/mobile/Media/Succession/ipsw/
        unzip /private/var/mobile/Media/Succession/ipsw.ipsw
        cd ~
        echo -e "\e[1;32mVerifying IPSW...\e[0m"
        if grep -q "$ProductBuildVersion" "/private/var/mobile/Media/Succession/ipsw/BuildManifest.plist"; then
            echo -e "\e[1;32mIPSW verified, moving files...\e[0m"
            dmg=`ls -S /private/var/mobile/Media/Succession/ipsw/ | head -1`
            mv /private/var/mobile/Media/Succession/ipsw/$dmg /private/var/mobile/Media/Succession/rfs.dmg
        else
            versionCheckOverride=false
            echo -e "\e[1;31m**********WARNING!**********\e[0m"
            echo -e "\e[1;31mThe IPSW provided does not appear to match the iOS version of this device\e[0m"
            echo -e "\e[1;31mATTEMPTING TO CHANGE YOUR iOS VERSION USING THIS TOOL WILL RESULT IN A BOOTLOOP\e[0m"
            while true; do
                read -p $'\e[1;31mWould you like to override this check and continue anyway? (y/n) \e[0m' yn
                case $yn in
                    [Yy]* ) versionCheckOverride=true; break;;
                    [Nn]* ) versionCheckOverride=false; break;;
                    * ) echo -e "\e[1;31mPlease answer yes or no.\e[0m";;
                esac
            done
            if $versionCheckOverride; then
                    echo -e "\e[1;31mVersion check overridden, continuing as if nothing went wrong...\e[0m"
                    dmg=`ls -S /private/var/mobile/Media/Succession/ipsw/ | head -1`
                    mv /private/var/mobile/Media/Succession/ipsw/$dmg /private/var/mobile/Media/Succession/rfs.dmg
            else
                    echo -e "\e[1;32mGood choice. Succession will now quit.\e[0m"
                    exit
            fi
        fi
    fi 
    # Clean up
    rm -rf /private/var/mobile/Media/Succession/ipsw/
    rm /private/var/mobile/Media/Succession/ipsw.ipsw
fi
echo "\e[1;32mRootfilesystem dmg successfully extracted!\e[0m" 
if grep -q "apfs" "/private/etc/fstab"; then
    echo -e "\e[1;32mDetected APFS filesystem!\e[0m"
    filesystemType="apfs"
else if grep -q "hfs" "/private/etc/fstab"; then
    echo -e "\e[1;32mDetected HFS+ filesystem!\e[0m"
    filesystemType="hfs"
else
    echo -e "\e[1;31mError! Unable to detect filesystem type.\e[0m"
    exit
fi
if [ -f /usr/bin/hdik ]; then
    hdikOutput=`hdik /private/var/mobile/Media/Succession/rfs.dmg`
    echo $hdikOutput
else if [ -f /usr/bin/attach ]; then
    attachOutput=`attach /private/var/mobile/Media/Succession/rfs.dmg`
    echo $attachOutput
fi
mkdir -p /private/var/mnt/succ/
#mount -t $filesystemType -o ro $attachedDiskPath /private/var/mnt/succ/
#SuccessionCLIhelper --beginRestore
exit 0
