#! /bin/bash

# Variables

user_drive=''

# Functions

function check_if_bash () {

  if [[ "$(ps -p $$ | tail -1 | awk '{print $NF}')" != "bash" ]] ; then
    echo "Please run this script with bash shell: \"bash VoidLinuxInstaller.sh\"."
    exit 1
  fi

}

function check_if_run_as_root () {

  if [[ "${UID}" != "0" ]]; then
	  echo "Please run this script as root."
	  exit 1
  fi

}

function set_keyboard_layout () {
  
  while true; do
  
    echo
    read -n 1 -r -p "Do you want to change your keyboard layout? (y/n): " yn
  
    if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then

      echo -e -n "\n\nPress any key to list all the keyboard layouts, move with arrow keys and press \"q\" to exit the list."
      read -n 1 key
      echo
  
      ls --color=always -R /usr/share/kbd/keymaps/ | grep "\.map.gz" | sed -e 's/\..*$//' | less --RAW-CONTROL-CHARS --no-init
  
      while true ; do
  
        echo
        read -p "Choose the keyboard layout you want to set and press [ENTER] or press [ENTER] to keep the one currently set: " user_keyboard_layout
  
        if [[ -z "${user_keyboard_layout}" ]] ; then
          echo -e "\nNo keyboard layout selected, keeping the previous one."
          break
        else
      
          if loadkeys ${user_keyboard_layout} 2>/dev/null ; then
            echo -e "\nKeyboad layout set to \"${user_keyboard_layout}\"."
            break
          else
            echo -e "\nNot a valid keyboard layout, please try again.\n"
          fi
      
        fi
    
      done
    
      break
  
    elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
      echo -e "\n\nKeeping the previous keyboard layout."
      break
    
    else
      echo -e "\nPlease answer y or n."
    fi
  
  done
  
}

function check_and_connect_to_internet () {

  declare wifi_interface
  declare wifi_essid
  declare wifi_passphrase
  
  while true; do
  
    echo -e "\nChecking internet connectivity..."
    
    if ! ping -c2 8.8.8.8 &> /dev/null ; then
      echo -e -n "\nNo internet connection found. Do you want to use wifi? (y/n): "
      read -n 1 yn
    
      if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
      
        if [[ -e /var/service/NetworkManager ]] ; then
        
          while true; do
          
            echo
            read -n 1 -r -p "Is your ESSID hidden? (y/n): " yn
            
            if [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
              echo
              echoHote
              nmcli device wifi
              echo
              nmcli --ask device wifi connect hidden yes
              break
            elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
              echo
              echo
              nmcli device wifi
              echo
              nmcli --ask device wifi connect
              break
            fi
            
          done
          
        else
          
          ### UNTESTED ###
          
          echo
          ip a
          echo
          
          while true; do
          
            echo -e -n "\nEnter the wifi interface and press [ENTER]: "
            read wifi_interface
            
            if [[ ! -z "${wifi_interface}" ]] ; then
            
              echo -e "\nEnabling wpa_supplicant service..."
              
              if [[ -e /var/service/wpa_supplicant ]] ; then
                echo -e "\nService already enabled, restarting..."
                sv restart {dhcpcd,wpa_supplicant}
              else
                echo -e "\nCreating service, starting..."
                ln -s /etc/sv/wpa_supplicant /var/service/
                sv restart {dhcpcd,wpa_supplicant}
              fi
            
              echo -e -n "\nEnter your ESSID and press [ENTER]: "
              read wifi_essid
              
              if [[ -d /etc/wpa_supplicant/ ]] ; then
                continue
              else
                mkdir -p /etc/wpa_supplicant/
              fi
              
              echo -e "\nGenerating configuration files..."
              wpa_passphrase "${wifi_essid}" | tee /etc/wpa_supplicant/wpa_supplicant.conf
              wpa_supplicant -B -c /etc/wpa_supplicant/wpa_supplicant.conf -i "${wifi_interface}"
              
              break
              
            else
              echo -e "\nPlease input a valid wifi interface."
            fi
            
          done
          
        fi
      
        if ping -c2 8.8.8.8 &> /dev/null ; then
          echo -e "\nSuccessfully connected to the internet."
        fi
        
        break
        
      elif [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
        echo -e -n "\nPlease connect your ethernet cable and wait a minute before pressing any key."
        read -n 1 -r wait
      
      else
        echo -e "\nPlease answer y or n."
      fi
      
    else
      echo -e "\nAlready connected to the internet."
      break
    fi

  done

}

function disk_wiping () {
  
  while true; do
  
    echo -e "\nPrinting all the connected drive(s):\n"
    lsblk -p
  
    echo
    read -r -p "Which drive do you want to use? Please enter the full path (i.e. /dev/sda): " user_drive
    
    if [[ ! -e "${user_drive}" ]] ; then
      echo -e "\nPlease select a valid drive."
      
    else
      echo -e "\nYou selected ${user_drive}."
      echo -e "\nTHIS DRIVE WILL BE FORMATTED, EVERY DATA INSIDE WILL BE ERASED."
      read -r -p "Are you sure you want to continue? (y/n and [ENTER]): " yn
    
      if [[ "${yn}" == "n" ]] || [[ "${yn}" == "N" ]] ; then
        echo -e "\nAborting, select another drive."
      elif [[ "${yn}" == "y" ]] || [[ "${yn}" == "Y" ]] ; then
        echo -e "\nWiping the drive...."
        wipefs -a "${user_drive}"
        break
      else
        echo -e "\nPlease answer y or n."
      fi
    
    fi
  
  done
}

# Main

check_if_bash
check_if_run_as_root
set_keyboard_layout
check_and_connect_to_internet
disk_wiping
