#! /bin/bash

# Author: Le0xFF
# Script name: VoidLinuxInstaller.sh
# Github repo: https://github.com/Le0xFF/VoidLinuxInstaller
#
# Description: My first attempt at creating a bash script, trying to converting my gist into a bash script. Bugs are more than expected.
#              https://gist.github.com/Le0xFF/ff0e3670c06def675bb6920fe8dd64a3
#
# Version: 1.0.0

# Variables

user_drive=''
encrypted_partition=''
encrypted_name=''
vg_name=''
lv_root_name=''
lv_root_size=''
lv_home_name=''
boot_partition=''

# Functions

function check_if_bash {

  if [[ "$(ps -p $$ | tail -1 | awk '{print $NF}')" != "bash" ]] ; then
    echo -e -n "Please run this script with bash shell: \"bash VoidLinuxInstaller.sh\".\n"
    exit 1
  fi

}

function check_if_run_as_root {

  if [[ "${UID}" != "0" ]] ; then
    echo -e -n "Please run this script as root.\n"
    exit 1
  fi

}

function check_if_chroot_exists {

  if [[ ! -e "${HOME}/chroot.sh" ]] ; then
    echo -e -n "Please be sure that "${HOME}"/chroot.sh exists.\n"
    exit 1
  fi
  
}

function check_if_uefi {

  if ! cat /proc/mounts | grep efivar &> /dev/null ; then
    if ! mount -t efivarfs efivarfs /sys/firmware/efi/efivars/ &> /dev/null ; then
      echo -e -n "Please run this script only on a UEFI system."
      exit 1
    fi
  fi

}

function intro {

  clear

  echo -e -n "     pQQQQQQQQQQQQppq    \n"
  echo -e -n "     p               Q          Void Linux installer script\n"
  echo -e -n "      pppQppQppppQ    Q  \n"
  echo -e -n " {{{{{            p    Q        My first attempt at creating a bash script.\n"
  echo -e -n "{    {   dpppppp   p    Q       Bugs and unicorns farts are expected.\n"
  echo -e -n "{   {   p       p   p   Q\n"
  echo -e -n "{   {   p       Q   p   Q       This script try to automate what my gist describes.\n"
  echo -e -n "{   {   p       Q   p   Q       Link to the gist: https://gist.github.com/Le0xFF/ff0e3670c06def675bb6920fe8dd64a3\n"
  echo -e -n "{    {   ppppppQ   p    Q\n"
  echo -e -n " {    {            ppppQ        This script will install Void Linux, with LVM, BTRFS, with separated /home partition,\n"
  echo -e -n "  {    {{{{{{{{{{{{             with Full Disk Encryption using LUKS1/2 and it will enable trim on SSD. So please don't use this script on old HDD.\n"
  echo -e -n "   {               {     \n"
  echo -e -n "    {{{{{{{{{{{{{{{{            Press any key to begin with the process.\n"
  
  read -n 1 key

  clear
  
}

function set_keyboard_layout {
  
  while true; do

    echo -e -n "#######################################\n"
    echo -e -n "# VLI #     Keyboard layout change    #\n"
    echo -e -n "#######################################\n"
  
    echo -e -n "\nDo you want to change your keyboard layout? (y/n): "
    read -n 1 yn
  
    if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then

      echo -e -n "\n\nPress any key to list all the keyboard layouts.\nMove with arrow keys and press \"q\" to exit the list."
      read -n 1 key
      echo
  
      ls --color=always -R /usr/share/kbd/keymaps/ | grep "\.map.gz" | sed -e 's/\..*$//' | less --RAW-CONTROL-CHARS --no-init
  
      while true ; do
  
        echo
        read -p "Choose the keyboard layout you want to set and press [ENTER] or just press [ENTER] to keep the one currently set: " user_keyboard_layout
  
        if [[ -z "${user_keyboard_layout}" ]] ; then
          echo -e -n "\nNo keyboard layout selected, keeping the previous one.\n\n"
          read -n 1 -r -p "Press any key to continue..." key
          clear
          break 2
        else
          if loadkeys ${user_keyboard_layout} 2> /dev/null ; then
            echo -e -n "\nKeyboad layout set to \"${user_keyboard_layout}\".\n\n"
            read -n 1 -r -p "Press any key to continue..." key
            clear
            break 2
          else
            echo -e "\nNot a valid keyboard layout, please try again."
          fi
        fi
    
      done
    
    elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
      echo -e -n "\n\nKeeping the last selected keyboard layout.\n\n"
      read -n 1 -r -p "Press any key to continue..." key
      clear
      break
    
    else
      echo -e -n "\nPlease answer y or n.\n\n"
      read -n 1 -r -p "Press any key to continue..." key
      clear
    fi
  
  done
  
}

function check_and_connect_to_internet {
  
  while true; do

    echo -e -n "#######################################\n"
    echo -e -n "# VLI #   Setup internet connection   #\n"
    echo -e -n "#######################################\n"

    echo -e "\nChecking internet connectivity..."

    if ! ping -c2 8.8.8.8 &> /dev/null ; then
      echo -e -n "\nNo internet connection found.\n\n"
      read -n 1 -r -p "Do you want to connect to the internet? (y/n): " yn
    
      if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then

        while true ; do

          echo -e -n "\n\nDo you want to use wifi? (y/n): "
          read -n 1 yn
    
          if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
      
            if [[ -e /var/service/NetworkManager ]] ; then
        
              while true; do
                echo
                echo
                read -n 1 -r -p "Is your ESSID hidden? (y/n): " yn
            
                if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
                  echo
                  echo
                  nmcli device wifi
                  echo
                  nmcli --ask device wifi connect hidden yes
                  echo
                  read -n 1 -r -p "Press any key to continue..." key
                  clear
                  break 2
                elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
                  echo
                  echo
                  nmcli device wifi
                  echo
                  nmcli --ask device wifi connect
                  echo
                  read -n 1 -r -p "Press any key to continue..." key
                  clear
                  break 2
                else
                  echo -e -n "\nPlease answer y or n."
                fi
            
              done
          
            else
            
            ### UNTESTED ###
            
              while true; do
            
                echo
                echo
                ip a
                echo
          
                echo -e -n "Enter the wifi interface and press [ENTER]: "
                read wifi_interface
            
                if [[ ! -z "${wifi_interface}" ]] ; then
            
                  echo -e "\nEnabling wpa_supplicant service..."
              
                  if [[ -e /var/service/wpa_supplicant ]] ; then
                    echo -e "\nService already enabled, restarting..."
                    sv restart {dhcpcd,wpa_supplicant}
                  else
                    echo -e "\nCreating service, starting..."
                    ln -s /etc/sv/wpa_supplicant /var/service/
                    sv restart dhcpcd
                    sleep 1
                    sv start wpa_supplicant
                  fi

                  echo -e -n "\nEnter your ESSID and press [ENTER]: "
                  read wifi_essid

                  if [[ ! -d /etc/wpa_supplicant/ ]] ; then
                    mkdir -p /etc/wpa_supplicant/
                  fi

                  echo -e "\nGenerating configuration files..."
                  wpa_passphrase "${wifi_essid}" | tee /etc/wpa_supplicant/wpa_supplicant.conf
                  wpa_supplicant -B -c /etc/wpa_supplicant/wpa_supplicant.conf -i "${wifi_interface}"
                  break 2
                else
                  echo -e "\nPlease input a valid wifi interface."
                fi
              done
            fi

            if ping -c2 8.8.8.8 &> /dev/null ; then
              echo -e -n "\nSuccessfully connected to the internet.\n\n"
              read -n 1 -r -p "Press any key to continue..." key
              clear
            fi
            break

          elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
            echo -e -n "\n\nPlease connect your ethernet cable and wait a minute before pressing any key."
            read -n 1 key
            clear
            break

          else
            echo -e -n "\nPlease answer y or n."
          fi

        done

      elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
        echo -e -n "\n\nNot connecting to the internet.\n\n"
        read -n 1 -r -p "Press any key to continue..." key
        clear
        break
      else
        echo -e -n "\nPlease answer y or n.\n\n"
        read -n 1 -r -p "Press any key to continue..." key
        clear
      fi

    else
      echo -e -n "\nAlready connected to the internet.\n\n"
      read -n 1 -r -p "Press any key to continue..." key
      clear
      break
    fi

  done

}

function disk_wiping {
  
  while true; do
  
    echo
    read -n 1 -r -p "Do you want to wipe any drive? (y/n): " yn
    echo
    
    if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
      
      out="0"
      
      while [ ${out} -eq "0" ] ; do
      
        echo -e "\nPrinting all the connected drives:\n"
        lsblk -p
    
        echo -e -n "\nWhich drive do you want to wipe?\nPlease enter the full drive path (i.e. /dev/sda): "
        read user_drive
      
        if [[ ! -e "${user_drive}" ]] ; then
          echo -e "\nPlease select a valid drive."
      
        else
          while true; do
          echo -e "\nDrive selected for wiping: ${user_drive}"
          echo -e "\nTHIS DRIVE WILL BE WIPED, EVERY DATA INSIDE WILL BE LOST."
          read -r -p "Are you sure you want to continue? (y/n and [ENTER]): " yn
        
          if [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
            echo -e "\nAborting, select another drive."
            break
          elif [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
            if cat /proc/mounts | grep "${user_drive}" &> /dev/null ; then
              echo -e -n "\nDrive already mounted.\nChanging directory to "${HOME}" and unmounting every partition before wiping...\n"
              cd $HOME
              umount -l "${user_drive}"?*
              echo -e -n "\nDrive unmounted successfully.\n"
            fi

            echo -e -n "\nWiping the drive...\n"
            wipefs -a "${user_drive}"
            echo -e -n "\nDrive successfully wiped.\n"
            out="1"
            break
          else
            echo -e "\nPlease answer y or n."
          fi
          done
        fi
      done
      
    elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
      echo -e "\nNo additional changes were made."
      break
    
    else
      echo -e "\n\nPlease answer y or n."
    fi
  
  done
}

function disk_partitioning {
  
  while true; do
    
    echo
    read -n 1 -r -p "Do you want to partition any drive? (y/n): " yn
    echo
    
    if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
      
      out1="0"
      
      while [ "${out1}" -eq "0" ] ; do
    
        if [[ ! -z "${user_drive}" ]] ; then

          if cat /proc/mounts | grep "${user_drive}" &> /dev/null ; then
            echo -e -n "\nDrive already mounted.\nChanging directory to "${HOME}" and unmounting every partition before partitioning...\n"
            cd $HOME
            umount -l "${user_drive}"?*
            echo -e -n "\nDrive unmounted successfully.\n"
          fi
        
          out="0"
      
          while [ "${out}" -eq "0" ] ; do
          
            echo -e -n "\nSuggested disk layout:"
            echo -e -n "\n- GPT as disk label type for UEFI systems;"
            echo -e -n "\n- Less than 1 GB for /boot/efi as first partition [EFI System];"
            echo -e -n "\n- Rest of the disk for / as second partition [Linux filesystem]."
            echo -e -n "\n\nThose two will be physical partition.\nYou don't need to create a /home partition now because it will be created later as a logical one.\n"
          
            echo -e -n "\nDrive selected for partitioning: ${user_drive}\n\n"
          
            read -r -p "Which tool do you want to use? (fdisk/cfdisk/sfdisk): " tool
      
            case "${tool}" in
              fdisk)
                fdisk "${user_drive}"
                sync
                break
                ;;
              cfdisk)
                cfdisk "${user_drive}"
                sync
                break
                ;;
              sfdisk)
                sfdisk "${user_drive}"
                sync
                break
                ;;
              *)
                echo -e -n "\nPlease select only one of the three suggested tools.\n"
                ;;
            esac
            
          done
          
          while true; do
            echo
            lsblk -p "${user_drive}"
            echo
            read -n 1 -r -p "Is this the desired partition table? (y/n): " yn
          
            if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
              echo -e -n "\n\nDrive partitioned, keeping changes.\n"
              out="1"
              out1="1"
              break
            elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
              echo -e -n "\n\nPlease partition your drive again.\n"
              break
            else
              echo -e "\n\nPlease answer y or n."
            fi
          done
          
        else
      
          out="0"
      
          while [ ${out} -eq "0" ] ; do
        
            echo -e "\nPrinting all the connected drive(s):\n"
            lsblk -p
            echo
          
            echo -e -n "\nWhich drive do you want to partition?\nPlease enter the full drive path (i.e. /dev/sda): "
            read user_drive
    
            if [[ ! -e "${user_drive}" ]] ; then
              echo -e "\nPlease select a valid drive."
      
            else
          
              while true; do
              echo -e "\nYou selected ${user_drive}."
              echo -e "\nTHIS DRIVE WILL BE PARTITIONED, EVERY DATA INSIDE WILL BE LOST."
              read -r -p "Are you sure you want to continue? (y/n and [ENTER]): " yn
          
              if [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
                echo -e "\nAborting, select another drive."
                break
              elif [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
                if cat /proc/mounts | grep "${user_drive}" &> /dev/null ; then
                  echo -e -n "\nDrive already mounted.\nChanging directory to "${HOME}" and unmounting every partition before selecting it for partitioning...\n"
                  cd $HOME
                  umount -l "${user_drive}"?*
                  echo -e -n "\nDrive unmounted successfully.\n"
                fi

                echo -e "\nCorrect drive selected, back to tool selection..."
                out="1"
                break
              else
                echo -e "\nPlease answer y or n."
              fi
              done
            
            fi
          
          done
        
        fi
      
      done
    
    elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
      echo -e "\nNo additional changes were made."
      break
    
    else
      echo -e "\nPlease answer y or n."
    
    fi
  
  done
  
}

function disk_encryption {

  out="0"

  while [ "${out}" -eq "0" ]; do
  
    echo -e -n "\nPrinting all the connected drives:\n\n"
    lsblk -p
    
    echo -e -n "\nWhich / [root] partition do you want to encrypt?\nPlease enter the full partition path (i.e. /dev/sda1): "
    read encrypted_partition
      
    if [[ ! -e "${encrypted_partition}" ]] ; then
      echo -e -n "\nPlease select a valid partition.\n"
      
    else
      while true; do
        echo -e -n "\nYou selected: ${encrypted_partition}.\n\n"
        read -r -p "Is this correct? (y/n and [ENTER]): " yn
        
        if [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e -n "\nAborting, select another partition.\n"
          break
        elif [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          echo -e -n "\nCorrect partition selected.\n"

          echo -e -n "\nKeep in mind that GRUB LUKS version 2 support is still limited.\n(https://savannah.gnu.org/bugs/?55093)\nChoosing it could result in an unbootable system.\nIt's strongly recommended to use LUKS version 1.\n"

          while true ; do
            echo -e -n "\nWhich LUKS version do you want to use? (1/2 and [ENTER]): "
            read ot
            if [[ "${ot}" == "1" ]] || [[ "${ot}" == "2" ]] ; then
              echo -e -n "\nUsing LUKS version "${ot}".\n\n"
              cryptsetup luksFormat --type=luks"${ot}" "${encrypted_partition}"
              break
            else
              echo -e -n "\nPlease enter 1 or 2.\n"
            fi
          done

          out1="0"

          while [ "${out1}" -eq "0" ] ; do
            echo -e -n "\nEnter a name for the encrypted partition without any spaces (i.e. MyEncryptedLinuxPartition): "
            read encrypted_name
            if [[ -z "${encrypted_name}" ]] ; then
              echo -e -n "\nPlease enter a valid name.\n"
            else
              while true ; do
                echo -e -n "\nYou entered: "${encrypted_name}".\n\n"
                read -n 1 -r -p "Is this the desired name? (y/n): " yn
          
                if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
                  echo -e -n "\n\nPartition will now be mounted as: /dev/mapper/"${encrypted_name}"\n\n"
                  cryptsetup open "${encrypted_partition}" "${encrypted_name}"
                  out1="1"
                  break
                elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
                  echo -e -n "\n\nPlease select another name.\n"
                  break
                else
                  echo -e "\n\nPlease answer y or n."
                fi
              done
            fi
          done

          out="1"
          break
        else
          echo -e -n "\nPlease answer y or n.\n"
        fi
      done

    fi
    
  done
 
}

function lvm_creation {

  echo -e -n "\nCreating logical partitions wih LVM.\n"

  out='0'

  while [ "${out}" -eq "0" ]; do

    echo -e -n "\nEnter a name for the volume group without any spaces (i.e. MyLinuxVolumeGroup): "
    read vg_name
    
    if [[ -z "${vg_name}" ]] ; then
      echo -e -n "\nPlease enter a valid name.\n"
    else
      while true ; do
        echo -e -n "\nYou entered: "${vg_name}".\n\n"
        read -n 1 -r -p "Is this the desired name? (y/n): " yn
        
        if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          echo -e -n "\n\nVolume group will now be mounted as: /dev/mapper/"${vg_name}"\n\n"
          vgcreate "${vg_name}" /dev/mapper/"${encrypted_name}"
          out="1"
          break
        elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e -n "\n\nPlease select another name.\n"
          break
        else
          echo -e "\n\nPlease answer y or n."
        fi
      done
    fi

  done

  out='0'

  while [ "${out}" -eq "0" ]; do

    echo -e -n "\nEnter a name for the logical root partition without any spaces and its size.\nBe sure to make no errors (i.e. MyLogicLinuxRootPartition 100G): "
    read lv_root_name lv_root_size
    
    if [[ -z "${lv_root_name}" ]] || [[ -z "${lv_root_size}" ]] ; then
      echo -e -n "\nPlease enter valid values.\n"
    else
      while true ; do
        echo -e -n "\nYou entered: "${lv_root_name}" and "${lv_root_size}".\n\n"
        read -n 1 -r -p "Are these correct? (y/n): " yn
          
        if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          echo -e -n "\n\nLogical volume "${lv_root_name}" of size "${lv_root_size}" will now be created.\n\n"
          lvcreate --name "${lv_root_name}" -L "${lv_root_size}" "${vg_name}"
          out="1"
          break
        elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e -n "\n\nPlease select other values.\n"
          break
        else
          echo -e "\n\nPlease answer y or n."
        fi
      done
    fi

  done

  out='0'

  while [ "${out}" -eq "0" ]; do

    echo -e -n "\nEnter a name for the logical home partition without any spaces.\nIts size will be the remaining free space (i.e. MyLogicLinuxHomePartition): "
    read lv_home_name
    
    if [[ -z "${lv_home_name}" ]] ; then
      echo -e -n "\nPlease enter a valid name.\n"
    else
      while true ; do
        echo -e -n "\nYou entered: "${lv_home_name}".\n\n"
        read -n 1 -r -p "Is this the desired name? (y/n): " yn
          
        if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          echo -e -n "\n\nLogical volume "${lv_home_name}" will now be created.\n\n"
          lvcreate --name "${lv_home_name}" -l +100%FREE "${vg_name}"
          out="1"
          break
        elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e -n "\n\nPlease select another name.\n"
          break
        else
          echo -e "\n\nPlease answer y or n."
        fi
      done
    fi

  done

}

function create_filesystems {
  
  echo -e -n "\nFormatting partitions with proper filesystems.\n\nEFI partition will be formatted as FAT32.\nRoot and home partition will be formatted as BTRFS.\n"

  out1='0'

  while [ "${out1}" -eq "0" ]; do

    echo
    lsblk -p "${user_drive}"
    echo

    echo -e -n "\nWhich partition will be the /boot/efi partition?\n"
    read -r -p "Please enter the full partition path (i.e. /dev/sda1): " boot_partition
    
    if [[ ! -e "${boot_partition}" ]] ; then
      echo -e "\nPlease select a valid drive."
      
    else
          
      while true; do
        echo -e "\nYou selected: ${boot_partition}."
        echo -e "\nTHIS PARTITION WILL BE FORMATTED, EVERY DATA INSIDE WILL BE LOST."
        read -r -p "Are you sure you want to continue? (y/n and [ENTER]): " yn
          
        if [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e "\nAborting, select another partition."
          break
        elif [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          if cat /proc/mounts | grep "${boot_partition}" &> /dev/null ; then
            echo -e -n "\nPartition already mounted.\nChanging directory to "${HOME}" and unmounting it before formatting...\n"
            cd $HOME
            umount -l "${boot_partition}"
            echo -e -n "\nDrive unmounted successfully.\n"
          fi

          echo -e -n "\nCorrect partition selected.\n"

          out='0'
          
          while [ "${out}" -eq "0" ]; do

            echo -e -n "\nEnter a label for the boot partition without any spaces (i.e. MYBOOTPARTITION): "
            read boot_name
    
            if [[ -z "${boot_name}" ]] ; then
              echo -e -n "\nPlease enter a valid name.\n"
            else
              while true ; do
                echo -e -n "\nYou entered: "${boot_name}".\n\n"
                read -n 1 -r -p "Is this the desired name? (y/n): " yn
          
                if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
                  echo -e -n "\n\nBoot partition "${boot_partition}" will now be formatted as FAT32 with "${boot_name}" label.\n\n"
                  mkfs.vfat -n "${boot_name}" -F 32 "${boot_partition}"
                  out="1"
                  break
                elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
                  echo -e -n "\n\nPlease select another name.\n"
                  break
                else
                  echo -e "\n\nPlease answer y or n."
                fi
              done
            fi
        
          done

          out1="1"
          break
        else
          echo -e "\nPlease answer y or n."
        fi
      done

    fi

  done

  out='0'

  while [ "${out}" -eq "0" ]; do

    echo -e -n "\nEnter a label for the root partition without any spaces (i.e. MyRootPartition): "
    read root_name
    
    if [[ -z "${root_name}" ]] ; then
      echo -e -n "\nPlease enter a valid name.\n"
    else
      while true ; do
        echo -e -n "\nYou entered: "${root_name}".\n\n"
        read -n 1 -r -p "Is this the desired name? (y/n): " yn
          
        if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          echo -e -n "\n\nRoot partition /dev/mapper/"${vg_name}"-"${lv_root_name}" will now be formatted as BTRFS with "${root_name}" label.\n\n"
          mkfs.btrfs -L "${root_name}" /dev/mapper/"${vg_name}"-"${lv_root_name}"
          out="1"
          break
        elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e -n "\n\nPlease select another name.\n"
          break
        else
          echo -e "\n\nPlease answer y or n."
        fi
      done
    fi

  done

  out='0'

  while [ "${out}" -eq "0" ]; do

    echo -e -n "\nEnter a label for the home partition without any spaces (i.e. MyHomePartition): "
    read home_name
    
    if [[ -z "${home_name}" ]] ; then
      echo -e -n "\nPlease enter a valid name.\n"
    else
      while true ; do
        echo -e -n "\nYou entered: "${home_name}".\n\n"
        read -n 1 -r -p "Is this the desired name? (y/n): " yn
          
        if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
          echo -e -n "\n\nHome partition /dev/mapper/"${vg_name}"-"${lv_home_name}" will now be formatted as BTRFS with "${home_name}" label.\n\n"
          mkfs.btrfs -L "${home_name}" /dev/mapper/"${vg_name}"-"${lv_home_name}"
          out="1"
          break
        elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
          echo -e -n "\n\nPlease select another name.\n"
          break
        else
          echo -e "\n\nPlease answer y or n."
        fi
      done
    fi

  done

}

function create_btrfs_subvolumes {

  echo -e -n "\nBTRFS subvolumes will now be created with default options.\n\n"
  echo -e -n "Default options:\n"
  echo -e -n "- rw\n"
  echo -e -n "- noatime\n"
  echo -e -n "- ssd\n"
  echo -e -n "- compress=zstd\n"
  echo -e -n "- space_cache=v2\n"
  echo -e -n "- commit=120\n"

  echo -e -n "\nSubvolumes that will be created:\n"
  echo -e -n "- /@\n"
  echo -e -n "- /@snapshots\n"
  echo -e -n "- /home/@home\n"
  echo -e -n "- /var/cache/xbps\n"
  echo -e -n "- /var/tmp\n"
  echo -e -n "- /var/log\n"

  echo -e -n "\nIf you prefer to change any option, please quit this script NOW and modify it according to you tastes.\n\n"
  read -n 1 -r -p "Press any key to continue or Ctrl+C to quit now..." key

  echo -e -n "\n\nThe root partition you selected (/dev/mapper/"${vg_name}"-"${lv_root_name}") will now be mounted to /mnt.\n"
  if cat /proc/mounts | grep /mnt &> /dev/null ; then
    echo -e -n "Everything mounted to /mnt will now be unmounted...\n"
    cd $HOME
    umount -l /mnt
    echo -e -n "\nDone.\n"
  fi

  echo -e -n "\nCreating BTRFS subvolumes and mounting them to /mnt...\n"

  export BTRFS_OPT=rw,noatime,ssd,compress=zstd,space_cache=v2,commit=120
  mount -o "${BTRFS_OPT}" /dev/mapper/"${vg_name}"-"${lv_root_name}" /mnt
  mkdir /mnt/home
  mount -o "${BTRFS_OPT}" /dev/mapper/"${vg_name}"-"${lv_home_name}" /mnt/home
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@snapshots
  btrfs subvolume create /mnt/home/@home
  umount /mnt/home
  umount /mnt
  mount -o "${BTRFS_OPT}",subvol=@ /dev/mapper/"${vg_name}"-"${lv_root_name}" /mnt
  mkdir /mnt/home
  mkdir /mnt/.snapshots
  mount -o "${BTRFS_OPT}",subvol=@home /dev/mapper/"${vg_name}"-"${lv_home_name}" /mnt/home/
  mount -o "${BTRFS_OPT}",subvol=@snapshots /dev/mapper/"${vg_name}"-"${lv_root_name}" /mnt/.snapshots/
  mkdir -p /mnt/boot/efi
  mount -o rw,noatime "${boot_partition}" /mnt/boot/efi/
  mkdir -p /mnt/var/cache
  btrfs subvolume create /mnt/var/cache/xbps
  btrfs subvolume create /mnt/var/tmp
  btrfs subvolume create /mnt/var/log

  echo -e -n "\nDone.\n"

}

function install_base_system_and_chroot {

  while true ; do
  
    echo -e -n "\nSelect which architecture do you want to use:\n\n"
    
    select user_arch in x86_64 musl ; do
      case "${user_arch}" in
        x86_64)
          echo -e -n "\n"${user_arch}" selected.\n"
          ARCH="${user_arch}"
          break 2
          ;;
        musl)
          echo -e -n "\n"${user_arch}" selected.\n"
          echo -e -n "\nWARNING: This was not tested at all, so expect unexpected behaviours.\n"
          ARCH="${user_arch}"
          break 2
          ;;
        *)
          echo -e -n "\nPlease select one of the two architectures.\n"
          ;;
      esac
    done

  done

  echo -e -n "\nInstalling base system...\n"
  export REPO=https://repo-default.voidlinux.org/current
  XBPS_ARCH="${ARCH}" xbps-install -Suy xbps
  XBPS_ARCH="${ARCH}" xbps-install -Sy -r /mnt -R "$REPO" base-system btrfs-progs cryptsetup grub-x86_64-efi lvm2 grub-btrfs grub-btrfs-runit NetworkManager bash-completion nano
  
  echo -e -n "\nMounting folders for chroot...\n"
  for dir in sys dev proc ; do
    mount --rbind /$dir /mnt/$dir
    mount --make-rslave /mnt/$dir
  done
  
  echo -e -n "\nCopying /etc/resolv.conf...\n"
  cp -L /etc/resolv.conf /mnt/etc/

  echo -e -n "\nCopying /etc/wpa_supplicant/wpa_supplicant.conf...\n"
  cp -L /etc/wpa_supplicant/wpa_supplicant.conf /mnt/etc/wpa_supplicant/

  echo -e -n "\nChrooting...\n"
  cp "${HOME}"/chroot.sh /mnt/root/
  BTRFS_OPTS="${BTRFS_OPTS}" boot_partition="${boot_partition}" encrypted_partition="${encrypted_partition}" encrypted_name="${encrypted_name}" vg_name="${vg_name}" lv_root_name="${lv_root_name}" lv_home_name="${lv_home_name}" user_drive="${user_drive}" PS1='(chroot) # ' chroot /mnt/ /bin/bash "${HOME}"/chroot.sh

}

function outro {

  echo -e -n "\nAfter rebooting into the new installed system, be sure to:\n"
  echo -e -n "- Change your hostname in /etc/hostname\n"
  echo -e -n "- Modify /etc/rc.conf according to the official documentation\n"
  echo -e -n "- Uncomment the right line in /etc/default/libc-locales\n"
  echo -e -n "- Add the same uncommented line in /etc/locale.conf\n"
  echo -e -n "- Run \"xbps-reconfigure -fa\"\n"
  echo -e -n "- Reboot\n"
  echo -e -n "\nEverything's done, goodbye.\n\n"

  rm -f /mnt/home/root/chroot.sh

}

# Main

check_if_bash
check_if_run_as_root
check_if_chroot_exists
check_if_uefi
intro
set_keyboard_layout
check_and_connect_to_internet
disk_wiping
disk_partitioning
disk_encryption
lvm_creation
create_filesystems
create_btrfs_subvolumes
install_base_system_and_chroot
outro
exit
