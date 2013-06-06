#!/bin/bash

# picuntu-da-server - 0.9
# This script partitions the usb flash drive, usb external drive, SD Card
# Copies the content of linuxroot into the same

# Release date: 20-Dec-12
#   Read the readme file for instructions
#
# Copyright Alok Sinha - asinha@g8.net
# Released under GPL V2

# Step 1: Do the basics
# Step 2: Get picuntu - download or get the path of file
# Step 3: Ask for device type - UG or MK etc
# Step 4: Ask for wpa-ssh, wpa-ssid
# Step 5: Ask for which disk needs to be formatted
# Step 6: Show user the data collected.
# Step 7: Make disk - Do the stuff needed to be done....
# Step 8: Copy picuntu files
# Step 9: Configure the new picuntu, with network data we have collected.
# Step 10 Cleanup...

trap 'echo you hit Ctrl-C/Ctrl-\, now exiting..; kill -9 $$' SIGINT SIGQUIT

function inst_pkg {
# Step 1: If not available wget, dialog - apt-get install them...
if [ -f /usr/bin/wget ] && [ -f /sbin/parted ]; 
	then
		WGET="Y"; 
	else
		echo "Trying to get wget and/or parted"
		apt-get --q -y install wget > /tmp/2 
		if [ -f /usr/bin/wget ]; 
		then
				WGET="Y"; 
		else
				clear
				echo "Wget or parted not available, cannot continue"
				exit_to_system
		fi
fi

if [ -f /usr/bin/dialog ]; 
	then
		rm -f /tmp/ubuntu 
	else
		echo "Trying to get dialog for nice menus"
		apt-get --q -y install dialog > /tmp/2 
		if [ -f /usr/bin/dialog ]; 
		then
				rm -f /tmp/ubuntu;
		else
				echo "dialog application not available, will use text menus only"
				touch /tmp/ubuntu;
		fi
fi

#	apt-get -qq -y install dialog wget parted > /tmp/2

	rm -f /tmp/2

}

function conf_var {

# Where you have downloaded the Picuntu Linuxroot
#	LXROOT="/mnt/disk2/Dev/rk3066-linux/picuntu-linuxroot-0.9/*"
#  LXROOT="/mnt/disk2/Dev/rk3066-linux/picuntu-linuxroot-0.9.tgz"

TMP_DL="/tmp/picuntu-dl"

# --------
# Picuntu download - Change this before every release. #
PIC_URL="http://rk3066-linux.googlecode.com/files/picuntu-linuxroot-0.9-RC2.1.tgz"
SHA_URL="http://code.google.com/p/rk3066-linux/downloads/detail?name=picuntu-linuxroot-0.9-RC2.1.tgz"
PIC_FIL="picuntu-linuxroot-0.9-RC2.1.tgz"

LXROOT="$TMP_DL"/"$PIC_FIL"

DIALOG="/usr/bin/dialog"

if [ -f /usr/bin/logger ]; then LGR="/usr/bin/logger"; else LGR="echo "; fi
	
# DO not change this...
	label=linuxroot; 
	fst="ext4"
# You will not need to worry about this, till the time you intend to connect a 2TB plus disk. After that,you need gpt
	ptype=msdos
# Temporary directory, where I would mount and unmount this drive
    TMOUNT="/tmp/picuntu"
    BACK_T="Pre-Picuntu 0.9 - RC2"

# Some scratchpad
		ETCIFACES="$TMOUNT/etc/network/interfaces"
		TMP_SCRATCH="/tmp/picuntu-scratch"
		TMP_SCRATCH1="/tmp/picuntu-scratch1"
		TMP_SCRATCH2="/tmp/picuntu-scratch2"


tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

	# File in which interface is defined
	IFACE_FILE="$TMOUNT/tmp/Card.picuntu"
	DEVI_FILE="$TMOUNT/tmp/Device.picuntu"
	MODU_FILE="$TMOUNT/tmp/Module.picuntu"
	SUPD_FILE="$TMOUNT/tmp/Supd.picuntu"
	
}
function chk-uid {
# function to check, if I am uid
if [[ $EUID -ne 0 ]]; 
	then
  		clear
		echo "You must be root to run this, it won't work otherwise" 2>&1
		echo
		echo
		return 0
	else
		return 1
fi
 }

function conf_devel {
# Function to set up variables for working on development platform
# ------

# Setting variables
CUR_VER="RC3"
DIR_NAME="picuntu-linuxroot-0.9"

#PIC_FILE="picuntu-linuxroot-0.9-RC3.tgz"
PIC_FIL="$DIR_NAME-$CUR_VER.tgz"
#read -p "$PIC_FIL"
#Over-ride Setup Values for PIC_URL, SHA_URL, PIC_FIL
PIC_URL="http://192.168.1.112/$PIC_FIL"
SHA_URL="http://192.168.1.112/sha1.html"
DEV_PATH="/mnt/disk2/Dev/rk3066-linux/"
# Make tgz file

# cd /mnt/disk2/Dev/rk3066-linux/picuntu-linuxroot-0.9
cd "$DEV_PATH/$DIR_NAME"

# tar -czf ../picuntu-linuxroot-0.9-RC3.tgz .
tar -czf ../$PIC_FIL .


# Make sure, the link to the /var/www
rm -rf "/var/www/$PIC_FIL"
# ln -s /mnt/disk2/Dev/rk3066-linux/picuntu-linuxroot-0.9-RC3.tgz /var/www/picuntu-linuxroot-0.9-RC3.tgz
ln -s "$DEV_PATH/$PIC_FIL" "/var/www/$PIC_FIL"

# Make sha1 file in /var/www
SH_MSG1='<span id="sha1">'
SH_MSG2=`sha1sum "$DEV_PATH/$PIC_FIL" | cut -d " " -f1 `
SH_MSG3="</span>"
SH_MSG="$SH_MSG1$SH_MSG2$SH_MSG3"
echo $SH_MSG > /var/www/sha1.html

# kill -9 $$

}
function rst_lxroot {
# Resets the value of LXROOT
TMP_DL="/tmp/picuntu-dl"
LXROOT="$TMP_DL"/"$PIC_FIL"
}

function chk_sum {
# Checks the integrity of the downloaded file


if [ "$DO_CHK" == "NO" ];
	then
		TITLE="$TITLE: Check skipped"
		MSG="You chose to force us not to checksum the file..
Hope, you know what you are doing"
		SHA_CHK="0"
	else 
		TITLE="Result of check sum"
		echo "Please wait.... checking file integrity..."
		WEB_SUM=`wget -q "$SHA_URL" -O $TMP_SCRATCH ; grep sha1 $TMP_SCRATCH | cut -d '>' -f2 | cut -d '<' -f1`
		FIL_SUM=`sha1sum $LXROOT | cut -d ' ' -f1`
		MSG="Expected: $WEB_SUM"
		MSG="$MSG 
Actual  : $FIL_SUM"
		if [ "$WEB_SUM" == "$FIL_SUM" ]; 
		then
			TITLE="$TITLE:  Success"
			SHA_CHK="0"
		else
			TITLE="$TITLE: Failed"
			SHA_CHK="1"	
		fi
	
fi

show_info "$TITLE" "$MSG"
}

function chk_mount {
	# Check if the $TMOUNT directory exists already, clean it up
	cd /
	if [ ! -d $TMOUNT ]; then 	mkdir -p $TMOUNT; else echo "Directory $TMOUNT exists. Cannot continue. Check and remove $TMOUNT";exit; fi


}
function plog {
# Function to write log in the /var/log/syslog

echo $1
$LGR $1

}

function show_info {
if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_show_info "$1" "$2"
	else
		txt_show_info "$1" "$2"
fi
	}
function txt_show_info {
# =================================
	echo ""
	echo ""
	echo "                     ---=== $1 ===---"
	echo ""
	echo "$2"
	read -p "Enter to continue..."
	
}
function dia_show_info {
# =================================
$DIALOG --cr-wrap --backtitle "$BACK_T" --title "$1"  --msgbox "$2" 0 0  

}


# Action functions
function mk_picuntu_disk {
 # This is where the disk things are done
	clear
	umount $disk  1>&2
	umount "$disk"1  1>&2
	umount "$disk"2  1>&2
	
	echo "Picuntu disk maker for linux"
	# print the current partition(s) state
	parted $disk print 
	
	echo "Check if this is the correct partition you want to destroy."
	echo "Exit this script, run again if you want to change."
	echo "Giving you ten seconds to rethink."
	sleep 10
	echo "Last chance to change your mind."
#	read -p "Press Enter if you want to proceed, CTRL-C to exit"

	# create a gpt or msdos partition table (depending on $ptype variable defined above)
	echo "Creating partition table......"
	parted -a optimal $disk mklabel $ptype ; 
	echo "sleeping for 5 seconds, before you build a new partition it"
	sleep 5

	# create the partition, starting at 1MB which may be better
	# with newer disks
	echo "Creating desired partition"	
	parted -a optimal -- $disk unit compact mkpart primary $fst "1" "-1" 
	echo "sleeping for 5 seconds... before you format it."
	sleep 5

	# format it
	echo "Formatting the disk"	
	mke2fs -j -v -L "$label" ${disk}1 && echo "OK. Filesystem created... now to get PicUntu on it"

	# Now upgrading the filesystem to ext4, since parted does not know about it.
	tune2fs -O extents,uninit_bg,dir_index "$disk"1
	e2fsck -fpDC0 "$disk"1

	# 
	clear
	echo "Finally this is what we have made"
	echo ""
	echo ""
	parted $disk print 
	echo ""
	echo ""
#	read -p "Press Enter to continue or CTRL-C to abort"
	}
function chk_disk {
DISK_ERR="FALSE"
DSK_LBL=`blkid "$disk"1 | cut -d '"' -f2` 
FS_TYP=`blkid "$disk"1 | cut -d '"' -f6`
# echo "$DSK_LBL $FS_TYP"
if [ "$DSK_LBL" == "linuxroot"  -a  "$FS_TYP" == "ext4" ]; 
	then 
		DISK_ERR="FALSE"; 
	else 
		DISK_ERR="TRUE"; 
fi

}
function cp_picuntu {
		# mount the new drive
		mount -t $fst "$disk"1 $TMOUNT
#		read -p "Mounted on $TMOUNT. Press enter to continue" 
		echo "Copying contents of $LXROOT into $disk disk"
#		get_tar_progress "/mnt/disk2/Dev/rk3066-linux/picuntu-linuxroot-0.9-RC3.tgz" "/root/tmp"
		read -p "Untarring from $LXROOT"
		read -p "Into $TMOUNT"
		# Now trying new way - user does not have to unzip the tar file
		get_tar_progress "$LXROOT" "$TMOUNT"
		echo "Files have been copied, but not yet written to disk... will now sync."
		echo "This would take some time .. hold on."
		sync		
		sync
	}

function conf_interfaces {

	    # Insert networking modules
		if [ ! $MODU == "1" ]; 
			then
				echo "$MODU" >> "$TMOUNT"/etc/modules
		fi

		echo $IFACE > $IFACE_FILE
		echo $DEVI > $DEVI_FILE
		echo $MODU > $MODU_FILE
		echo $SUPP_DEV > $SUPD_FILE

		# Setting some flags
		echo $IFACE > $TMOUNT/tmp/Card.picuntu
		echo $DEVI > $TMOUNT/tmp/Device.picuntu
		echo $MODU > $TMOUNT/tmp/Module.picuntu

		# Removing all lines from /etc/network/interface related to iface to be removed.
		awk -v pat="$IFACE_REM" '$0 ~ pat {while(getline && $0 != ""){}}1' "$ETCIFACES" > "$TMP_SCRATCH"
		cat "$TMP_SCRATCH" > "$ETCIFACES"
		rm -f "$TMP_SCRATCH"

		# First extracting the $iface from the current file
		awk -v pat="$IFACE" '$0 ~ pat {while(getline && $0 != ""){}}1' "$TMOUNT"/etc/network/interfaces > "$TMP_SCRATCH1"

      # Creating /etc/network/interfaces
		echo "" > $TMP_SCRATCH
		echo "auto $IFACE" >> $TMP_SCRATCH
		echo "iface $IFACE inet dhcp" >> $TMP_SCRATCH
		echo "      wpa-ssid $SSID" >> $TMP_SCRATCH
		echo "      wpa-psk $PSK" >> $TMP_SCRATCH
		echo "" >> $TMP_SCRATCH
		echo "" >> $TMP_SCRATCH
		cat "$TMP_SCRATCH1" > "$TMP_SCRATCH2"
		cat "$TMP_SCRATCH" >> "$TMP_SCRATCH2" 
		cat "$TMP_SCRATCH2" > "$TMOUNT"/etc/network/interfaces; 
		rm -f "$TMP_SCRATCH1"; rm -f "$TMP_SCRATCH"; rm -f "$TMP_SCRATCH2"
		
}

# Util functions
function cleanup {
		# unmount the drive
			sleep 5
			echo "About to unmount and delete $TMOUNT"
			umount $TMOUNT
			
# For debugging, to be uncommented
			umount "$disk"1
			eject "$disk"1
}

function wget_picuntu {
# Function to download picuntu 
	clear
	echo "Please wait, downloading PicUntu"
	mkdir -p $TMP_DL
	/usr/bin/wget "$PIC_URL" -O "$LXROOT"
}
function get_picuntu {
		PIC_ERR="FALSE"
		cd /tmp
		get_yesno "Download picuntu" "Have you already downloaded picuntu? "
		DL="$?"
		if [ ! "$DL" -eq 0 ]; 
			then
				SHA_CHK="1"
				while [ ! $SHA_CHK -eq 0 ]
				do
					rst_lxroot
					wget_picuntu
					chk_sum
				done
			else
				
				get_inp "Picuntu location" "In which dir is $PIC_FIL located ?: [ $TMP_DL ]"
				if [ $INP=="" ]; then INP="$TMP_DL"; fi
				LXROOT="$INP"/"$PIC_FIL"
				if [ ! -f "$LXROOT" ];
					then 
						echo  "$LXROOT not found"
						PIC_ERR="TRUE"
					else 
						echo "Found file $LXROOT"
						chk_sum
						if [ $SHA_CHK -eq 0 ]; 
							then
								echo "Check sum of file ok"
							else
								echo "Check sum of file not ok"
								PIC_ERR="TRUE"
								return
						fi
				fi 
		fi		
}

function dia_box {
# Call dia_box_time  "Title to display" "Message to display"
dialog  --backtitle $BACK_T \
--title "$1" \
--msgbox "\n $2" 20 50

}

function dia_yesno {
# before you call this function set the followin two vaiables
# YNTITLE with the title of the box
# YNMSG with the message in the box
# Returns If yes - returns 0;If no - returns1; If escaped - returns 255  
$DIALOG --backtitle "$BACK_T" --title "$1" --clear --yesno "$2" 10 50
return $?
}
function txt_yesno {
	echo ""
	echo "               ---=== $1 ===--- "
	echo ""
	echo ""
	read -p "$2 [Y/n]: " YN
	if [ "$YN" == "n" ] || [ "$YN" == "N" ]; 
	then
		return 1
	else
		return 0
	fi
}
function get_yesno {

if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_yesno "$1" "$2"
	else
		txt_yesno "$1" "$2"
fi

}

function dia_m_yesno {
# before you call this function set the followin two vaiables
# YNTITLE with the title of the box
# YNMSG with the message in the box
# Returns If yes - returns 0;If no - returns1; If escaped - returns 255  
$DIALOG --backtitle "$BACK_T" --title "$1" --yes-label "$3" --no-label "$4" --clear --yesno "$2" 21 60
return $?
}
function txt_m_yesno {
	echo ""
	echo "               ---=== $1 ===--- "
	echo "$2"
	read -p "$5" YN

	if [ "$YN" == "n" ] || [ "$YN" == "N" ]; 
	then
		return 1
	else
		return 0	
	fi
}
function get_m_yesno {

if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_m_yesno "$1" "$2" "$3" "$4"
	else
		txt_m_yesno "$1" "$2" "$3" "$4"
fi
}



function dia_inp {
# Function to take input from user, and return in single INP variable

$DIALOG --backtitle "$BACK_T" \
			--title "$1" --clear \
			--inputbox "$2 $3" 16 51 2> $tempfile

retval=$?

case $retval in
  0)
	INP=`cat $tempfile`
    ;;
  1)
    INP=""
    ;;
  255)
  	 INP=""
	 ;;
esac

}
function txt_inp {
# Function to take input from user, and return in single $? variable
	echo ""
	echo "               ---=== $1 ===--- "
	echo ""
	echo "$2"
read -p "$3" INP 

	
}
function get_inp {
if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_inp "$1" "$2" "$3"
	else
		txt_inp "$1" "$2" "$3"
fi
}


function dia_wifi {
# TO change to dialog
# This is where, we collect the SSID and the password
# =========
#		clear
		TITLE="Select Interface"
		MSG=" Select what interface will you be using to connect."
		MSG="$MSG      You can change all these configuration later, using PicUntu menumode"
		PRMPT="
		Will you be connecting '(U)sb ethernet' or using 'Internal (W)ifi' [u/W]:"
		$DIALOG --backtitle "$BACK_T" \
			--title "$TITLE" \
			--radiolist "$MSG" 20 60 5 \
			"Wifi" "Internal Wifi" ON \
			"USB Net" "USB network usbnet0" off 2> $tempfile

INP=`cat $tempfile`
		
		if [ ! "$INP" == "USB Net" ];
			then

	#		read -p "SSID string of the Access point: " SSID
	#		echo ""
	#		read -p "Password to connect to Access Point: " PSK

	$DIALOG --ok-label "Submit" \
	  --backtitle "$BACK_T" \
	  --title "Wifi Details" \
	  --form "Enter details" \
15 50 0 \
	"Access Point SSID:" 1 1	"" 	1 20 20 0 \
	"Password :"    2 1	""  	2 20 20 0 \
2> $tempfile

			SSID=`sed -n 1p "$tempfile"`
			PSK=`sed -n 2p "$tempfile"`
		else
			IFACE="usbnet0"
			IFACE_REM="eth0"
			MODU="1"
			MODU_REM="usbnet"
			DEVI="USBNET"
		fi
	
	# ================================
	
}
function txt_wifi {

# This is where, we collect the SSID and the password
# =========
#		clear
		echo ""
		echo ""
		echo ""
		echo "                 ---=== Picuntu network pre-install script ===---"
		echo ""
		echo "  Recommended: Select the following, if you want to connect internal wifi initially"
		echo "                You can change all these configuration later, using PicUntu menumode"
		echo ""
		read -p "Will you be connecting '(U)sb ethernet' or using 'Internal (W)ifi' [u/W]: " INP
		if [ ! "$INP" == "u" ];
			then
			read -p "SSID string of the Access point: " SSID
			echo ""
			read -p "Password to connect to Access Point: " PSK
		else
			IFACE="usbnet0"
			IFACE_REM="eth0"
			MODU="1"
			MODU_REM="usbnet"
			DEVI="USBNET"
		fi
	
	# ================================
	
}
function get_wifi {
if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_wifi "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
	else
		txt_wifi "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
fi

}


function dia_select_device {
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --backtitle "$BACK_T" \
	--title "PicUntu - Select your device" --clear \
        --radiolist "More may be added later...  " 20 61 6 \
        "UG802"  "UG802: Complete support" ON \
        "MK808"    "MK808: Complete support" Off \
        "MX1"    "iMito MX1: No wireless support. Read Docs to use" OFF\
        "Generic"   "You are on your own :)" off  2> $tempfile

retval=$?

DEVI=`cat $tempfile`
case $DEVI in
  "UG802" )
	IFACE="wlan0"
	MODU="8188eu"
	MODU_REM="bcm40181"
	SUPP_DEV="Yes"
	IFACE_REM="eth0"
    ;;
  "MK808" )
	IFACE="eth0"
	IFACE_REM="wlan0"
	MODU="bcm40181"
	MODU_REM="8188"
	SUPP_DEV="Yes"
    ;;
  "MX1" )
	SUPP_DEV="No"
    ;;
  "Others" )
  	SUPP_DEV="No"
    ;;
esac


return $retval

}
function txt_select_device {
 #==== This is where we ask, what device user is running
		clear
		echo "                 ---=== Picuntu network pre-install script ===---"
		echo "What device are you planning to run PicUntu on"
		echo "1. MK808"
		echo "2. UG802"
		#echo "3. Use USB ethernet"
		echo "Select 2, if you have MX1 or other similar device"
		echo ""
		read -p "Enter (1,[2]) : " space
				case $space in
		[1])
			IFACE="eth0"
			IFACE_REM="wlan0"
			MODU="bcm40181"
			MODU_REM="8188"
			DEVI="MK808"
		  ;;
		[2])
			IFACE="wlan0"
			IFACE_REM="eth0"
			MODU="8188eu"
			MODU_REM="bcm40181"
			DEVI="UG802"
		  ;;
#		[3])
#			IFACE="usbnet0"
#			IFACE_REM="eth0"
#			MODU="1"
#			MODU_REM="usbnet"
#			DEVI="USBNET"
#		  ;;
		*)
			IFACE="wlan0"
			IFACE_REM="eth0"
			MODU="8188eu"
			MODU_REM="bcm40181"
			DEVI="UG802"
		  ;;

		esac

}
function get_select_device {
if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_select_device "$1" "$2"
	else
		txt_select_device "$1" "$2"
fi

}

function get_disk {
if [ ! -f "/tmp/ubuntu" ];
	then 
		echo "dia"
		dia_disk "$1" "$2"
	else
		echo "get"
		txt_disk "$1" "$2"
fi
DISK_ERR="FALSE"
parted "$disk" print
 if [ $? -eq 0 ]; 
 	then 
 		DISK_ERR="FALSE"; 
 	else  
 		DISK_ERR="TRUE"; 
 fi
 echo "Disk err= $DISK_ERR" 
}
function txt_disk {
# And finally let's find out, what dev he wants to use for picuntu rootfs
	## IMPORTANT - please check this below, otherwise your partition will be destroyed
	## IMPORTANT: Check again, this MUST be the device on which your flash drive/usb drive is mounted, that will be formatted,partitioned clean
	
		echo ""
		echo ""
		echo ""
		echo "                 ---=== Picuntu pre-install Disk selection ===---"
		echo ""
		echo ""
		echo "Which device you want to format/repartition for PicUntu?"
		read -p "(no need to give specific partition) [Default /dev/sdc]: "  disk
		if [ ! "$disk" ];
			then
			 disk="/dev/sdc"
		fi

}
function dia_disk {
# And finally let's find out, what dev he wants to use for picuntu rootfs
	## IMPORTANT - please check this below, otherwise your partition will be destroyed
	## IMPORTANT: Check again, this MUST be the device on which your flash drive/usb drive is mounted, that will be formatted,partitioned clean
		get_inp "$TITLE" "$MSG" "$PRMPT"
		disk=$INP
		if [ ! "$disk" ];
			then
			 disk="/dev/sdc"
		fi
		
}

function get_tar_progress {
if [ ! -f "/tmp/ubuntu" ];
	then 
		dia_tar_progress "$1" "$2"
	else
		txt_tar_progress "$1" "$2"
fi

}
function txt_tar_progress {
	pv -n "$1" | tar xzf - -C "$2" 2>&1
}
function dia_tar_progress {

(pv -n "$1" | tar xzf - -C "$2" ) 2>&1 | dialog --gauge "Extracting file..." 6 50

}

function patch_picuntu {

	# DONE
	# function to patch picuntu-da-server, for any errors _I_ may have made... :(
#	sed -i 's/dialog  -cr-wrap/dialog --cr-wrap/g' "$TMOUNT/usr/local/picuntu/picuntu-da-server.sh"
	
	# DONE
	# there is an exit command, stupidly left behind by me
#	sed -i 's/^exit//g' "$TMOUNT/usr/local/picuntu/picuntu-da-server.sh"

	# DONE
	# There seems to be a problem with LGR/plog
#	sed -i 's/LGR \$1/LGR \"\$1\"/g' "$TMOUNT/usr/local/picuntu/picuntu-da-server.sh"

	# DONE
	# What is a plogger ??? grrr...
#	sed -i 's/plogger/plog/g' "$TMOUNT/usr/local/picuntu/picuntu-da-server.sh"
	echo ""
}

function exit_to_system {
	kill -9 $$
}

function do_main {
# The main function
 
 # TOdo - do not proceed if the system does not have parted
 # Set a flag with no wget, so do not offer to download from net,jump to install from local file
 # Set a flag /tmp/ubuntu - for use or not use of dialog

 inst_pkg

 if [ "$DO_TXT" == "YES" ]; 
	then 
		touch /tmp/ubuntu; 
	else 
		rm -f /tmp/ubuntu; 
	fi
 
#read -p  "Step 1: complete"

# Step 2: Get picuntu - download or get the path of file
	get_picuntu
	while [ "$PIC_ERR" == "TRUE" ]; 
	do
		 get_picuntu "File not found. "; 
	done
# Todo: IT should PROCEED, ONLY if file found, else quit
#read -p  "Step 2: complete"


ALLRPT=1
while [ $ALLRPT -eq 1 ]
do

	# Step 3: Ask for device type - UG or MK etc
		get_select_device
#		read -p  "Step 3: complete"
	
	# Step 4: Ask for wpa-ssh, wpa-ssid
	# TO make dia script
		get_wifi
#		read -p  "Step 4: complete"
		
	# Step 5: Ask for which disk to be used
	# Step 5
	RPT=1
	while [ $RPT -eq 1 ]
	do
		# TO make dia script
		TITLE="PicUntu pre-install script"
		MSG="Which device you want to use for PicUntu?"
		MSG="$MSG 
		All data on this disk will be lost"
		PRMPT="(no need to give specific partition) [Default /dev/sdc]:"
		get_disk "$TITLE" "$MSG" "$PRMPT"
		while [ "$DISK_ERR" == "TRUE" ]
		do 
			get_disk
		done	
	
		RPT=0
		# Ask user if disk to be formatted.
		get_m_yesno "Pre-picuntu" "Do you want $disk to be formatted? [Y/n]" "Format disk" "Copy over" 
		# IF user said, disk is NOT to be formatted.. then 
		YY="$?"

		if [ "$YY" -eq 1 ] ; 
		then
			# check if the given disk has FS/linuxroot
				chk_disk
				# IF no error,
				if [ "$DISK_ERR" == "FALSE" ]; 
				then
						#  Set flag to "NO Format"
						PIC_FMT="N"
				else
						# IF error
					# Ask him if he would
					MSG="
It appears that the disk is missing correct disklabel, or suitable filesystem.
Would you like PicUntu to format the disk or would you want to choose another disk.
"
					get_m_yesno "Disk error. Filesystem not ready" "$MSG" "Format" "Select Another"		
					XX=$?
					if [ "$XX" -eq 0 ];
					then
							PIC_FMT="Y"
					elif [ "$XX" -eq 1 ];
						then 
							RPT=1
					else
							exit_to_system
					fi
				fi						
		else
				PIC_FMT="Y"
		fi  
	done
#	read -p  "Step 5: complete"

# Setting this flag so that user may select to start over.
ALLRPT=0	
	# Step 6: Show user the data collected.
	TITLE="Show collected information"
	MSG="Current configuration"
	MSG="
	$MSG 
	1. Device= $DEVI" 
	MSG="$MSG 
	2. Internal radio= $IFACE"
	MSG="$MSG 
	3. SSID= $SSID"
	MSG="$MSG 
	4. WiFi password= $PSK"
	MSG="$MSG 
	5. Module to use= $MODU"
	MSG="$MSG 
	6. Device on which to install= $disk"
	MSG="$MSG 
	7. Format the disk= $PIC_FMT"
	MSG="$MSG 
	
	Esc to exit program
	"
	PRMPT="Is this ok [ Y/n ]"
	get_m_yesno "$TITLE" "$MSG" "ACCEPT" "Start Over" "$PRMPT"
ALLRPT=$?	
#echo $ALLRPT
#exit
# If user presses escape, quit the program
if [ "$ALLRPT" -eq 255 ]; 
	then
		exit_to_system
	else
		echo ""
fi
done
# GO back to select everything again, if the user wants Start over
# read -p  "Step 6: complete"


# Step 7: Make disk - Do the stuff needed to be done....
 # Keep doing, till disk error gone
if [ "$PIC_FMT" == "Y" ]; 
	then
		mk_picuntu_disk
fi
# read -p  "Step 7: complete"

# Step 8: Copy picuntu files
	cp_picuntu 
# read -p  "Step 8: complete"


# Step 9: Configure the new picuntu, with network data we have collected.
	conf_interfaces
	patch_picuntu
# read -p  "Step 9: complete"


# Step 10 Cleanup...
# cleaning up after the work
	cleanup
# read -p "Step 10: complete"

} 
# ---------------------------- All function definition, above this line
# Main program starts now 



rm -rf /tmp/picuntu

# Step 1: Do the basics
 ARG="$1"
 chk-uid
 conf_var
 chk_mount
 
HST=`hostname`
if [ "$HST" == "monster" ];
	then
		echo "Development machine"
		conf_devel
fi
	

case $ARG in

'--text')
	DO_TXT="YES"
	do_main
	;;
'--nochecksum')
	DO_CHK="NO"
	do_main
	;;	
'--help')
	read -p "Help mode selected"
	echo $HLP
	;;
*)
	DO_TXT="NO"
	do_main
	;;
esac

# ----------------------------------------------------

