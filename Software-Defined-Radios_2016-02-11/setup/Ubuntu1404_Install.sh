#!/bin/bash
# To enable and disable tracing use:  set -x (On) set +x (Off)

# =========================
# Author:          Jon Zeolla (JZeolla, JonZeolla)
# Last update:     2016-01-24
# File Type:       Bash Script
# Version:         0.1
# Repository:      https://github.com/JonZeolla/Development
# Description:     This is a bash script to set up Ubuntu 14.04 for the Steel City InfoSec SDR Lab
#
# Notes
# - This script has not been tested yet - focusing on Ubuntu 14.04 as of 2016-01-24
# - Anything that has a placeholder value is tagged with TODO.
#
# =========================

function update_terminal() {
  clear
  
  # Set the status for the current stage appropriately
  if [[ ${exitstatus} == 0 ]]; then
    status+=('1')
  else
    status+=('0')
  fi
  
  # Provide the user with the status of all completed steps until this point
  for x in ${status[@]}; do
    if [[ ${status[${x}]} == 0 ]]; then
      echo ${success[${x}]}
    else
      echo ${failure[${x}]}
    fi
  done
  
  # Update the user with a quick description of the next step
  case ${#status[@]} in
    1)
      echo -e "Updating apt and all currently installed packages..."
      ;;
    2)
      echo -e "Installing some SDR lab package requirements"
      ;;
    3)
      echo -e "Installing pybombs"
      ;;
    4)
      echo -e "Installing the SDR lab packages"
      ;;
    *)
      echo -e "ERROR:    Unknown error"
      ;;
}
# Prepare the user 
clear
echo -e "\nBeware, this script takes a long time to run\nPlease do not start this unless you have sufficient time to finish it\nIt could take anywhere from 30 minutes to multiple hours, depending on your machine\n\n"
sleep 2s

# Set up arrays
declare -a status
success=("INFO:     Successfully updated apt and all currently installed packages","INFO:     Successfully installed SDR lab package requirements","INFO:     Successfully installed pybombs","INFO:     Successfully installed gqrx","\nINFO:     Succesfully set up machine for the SDR lab")
failure=("ERROR:    Issue updating apt and all currently installed packages","ERROR:    Issue installing SDR lab package requirements","ERROR:    Issue installing pybombs","ERROR:    Issue installing gqrx","\nERROR:    Issue while setting up the machine for the SDR lab")

# Gather the current user
declare -r usrCurrent="${SUDO_USER:-$USER}"

if [[ $usrCurrent == "sdr" ]]; then
        cecho "It appears that you're using the SDR lab machine.  This may already be setup, but there is no harm in running it a second time"
else
        isBrian=false
fi

# Re-synchronize the package index files, then install the newest versions of all packages currently installed
sudo apt-get -y -qq update && sudo apt-get -y -qq upgrade
exitstatus=$?
update_terminal

# Install dependancies for pybombs packages
sudo apt-get -y -qq install git libboost-all-dev qtdeclarative5-dev libqt5svg5-dev swig python-scipy
exitstatus=$?
update_terminal

# Pull down pybombs
git clone -q --recursive https://github.com/pybombs/pybombs.git
exitstatus=$?
update_terminal

# Configure pybombs
cd pybombs
cat > /home/${usrCurrent}/pybombs/config.dat <<EOL
[config]
gituser = ${usrCurrent}
gitcache = 
gitoptions = 
prefix = /home/${usrCurrent}/target
satisfy_order = deb,src
forcepkgs = 
forcebuild = gnuradio,uhd,gr-air-modes,gr-osmosdr,gr-iqbal,gr-fcdproplus,uhd,rtl-sdr,osmo-sdr,hackrf,gqrx,bladeRF,airspy
timeout = 30
cmakebuildtype = RelWithDebInfo
builddocs = OFF
cc = gcc
cxx = g++
makewidth = 4
EOL

# Install gqrx and its dependancies
./pybombs install gqrx
exitstatus=$?
update_terminal

# Add the pybombs-installed binaries to your path, if necessary
if ! grep -q /home/${usrCurrent}/target/bin "~${usrCurrent}/.bashrc";
  echo -e "\nPATH=\$PATH:/home/${usrCurrent}/target/bin" >> ~${usrCurrent}/.bashrc
  source ~${usrCurrent}/.bashrc
fi
update_terminal

# End the script
exit
