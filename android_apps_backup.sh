#!/bin/sh

# Verify Only single device is connected
getConnectedDeviceList(){
    count=0
    $1 | (while read line
    do
        if [ ! "$line" = "" ] && [ `echo $line | awk '{print $2}'` = "device" ]
        then
            (( count++ ))
            device=`echo $line | awk '{print $1}'`
            echo "$count. $device"      
            # echo "$count. $device $@ ..."      
            # adb -s $device $@        
        fi        
    done
    return $count)
}

# Verify if single device is connected or else exit 
verifySingleDevice(){
    if [ $device_count = 0 ]; then
        echo "No devices connected"
        exit
    elif [ $device_count -gt 1 ]; then 
        echo "$device_count devices connected. Only one device allowed"
        exit
    else 
        echo "Device connected"
    fi
}

# Log a list of all apps to a file
logAllApps(){
    echo "Logging installed 3rd party apps..."
    file=$backup_dir"/app_log.txt"
    touch $file
    adb shell pm list packages > $file
    echo "Logged at: "$file
}

# Backup APK files of all third party applications
backupThirdPartyAPKs(){
    third_party_apps_command="adb shell pm list packages -3 -f"
    echo "APKs Backup started..."
    app_dir=$backup_dir"/apps/"
    mkdir $app_dir

    file=$backup_dir"/app_log.txt"

    count=0
    $third_party_apps_command | (while read line
    do   
        if [ ! "$line" = "" ] && [ "$(cut -d':' -f1 <<<"$line")" = "package" ]
        then
            (( count++ ))        
            pkgName="$(cut -d':' -f2 <<<"$line")" 
            from_path=`echo $pkgName | sed 's|\(.*\)/.*|\1|'`"/base.apk"
            app_name=`echo echo $pkgName | sed 's/.*=//' | tr . _`
            to_path=$app_dir""$app_name".apk"
            adb pull $from_path $to_path                       
        fi                
    done
    echo "Backed up "$count" APKs at: "$app_dir)
}


#############
# Actual Script Starts here
#############

echo "Reading connected devices..."
devices="adb devices"
timestamp=`date +"%Y-%m-%d_%H-%M-%S"`

# get working directory
current_dir=$(pwd)
script_dir=$(dirname $0)
backup_dir=$current_dir`echo /backup_`$timestamp

# Get device count & Verify
getConnectedDeviceList "$devices"
device_count=$?
verifySingleDevice device_count

# Create directory for backup
mkdir $backup_dir

# Log all app package names
logAllApps

# Backup APKs
backupThirdPartyAPKs