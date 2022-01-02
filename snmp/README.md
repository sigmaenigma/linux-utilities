# If you need to install SNMP on a Raspberry Pi, and have the device info and Raspberry Pi logo appear in LibreNMS, these instructions get the job done. 

## Source: Took these instructions from Mike at https://youtu.be/jxiDgJBFV5E. These are available through this docs link as referenced in the video https://docs.google.com/document/d/1oVX70VXhAidAlaX0CmMb9WiqHFbhTLGOSasVbmuBX1I/edit
---
### Reference the distro.sh file and/or the snmpd.conf with the info below
---
# Install SNMP Daemon
Reference Site: https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html 
# Install the SNMP Daemon
1. ```sudo apt update```
2. ```sudo apt install snmpd```
3. Edit the config file
```sudo nano /etc/snmp/snmpd.conf```
4. Add the line:
```rocommunity public```
## Edit the following lines:
1. Comment the line ```agentAddress udp:127.0.0.1:161``` by adding a hash ( # ) in front of it so the line appears like this:
### ```#agentAddress udp:127.0.0.1:161```
2. Uncomment or remove the hash ( # ) from this line ```agentAddress #udp:161,udp6:[::1]:161``` so it appears like this:
```agentAddress udp:161,udp6:[::1]:161```
3. Restart the snmpd service ```sudo systemctl restart snmpd```
4. Add the device to LibreNMS
5. Wait 5-20 minutes to allow LibreNMS to collect some data about the device
6. DONE! Don’t forget to “Like” this video!

# OPTIONAL:  If you’d like the Raspberry Pi logo to display correctly, complete these steps.

## Add the “distro” file from LibreNMS
```
sudo touch /usr/bin/distro
sudo chmod +x /usr/bin/distro
sudo nano /usr/bin/distro
```
# Detects which OS and if it is Linux then it will detect which Linux Distribution.
Paste in the code for the distro file
```
#!/usr/bin/env bash

OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`

if [ "${OS}" = "SunOS" ] ; then
  OS=Solaris
  ARCH=`uname -p`
  OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"

elif [ "${OS}" = "AIX" ] ; then
  OSSTR="${OS} `oslevel` (`oslevel -r`)"

elif [ "${OS}" = "Linux" ] ; then
  KERNEL=`uname -r`

  if [ -f /etc/fedora-release ]; then
    DIST=$(cat /etc/fedora-release | awk '{print $1}')
    REV=`cat /etc/fedora-release | sed s/.*release\ // | sed s/\ .*//`
        
  elif [ -f /etc/redhat-release ] ; then
    DIST=$(cat /etc/redhat-release | awk '{print $1}')
    if [ "${DIST}" = "CentOS" ]; then
      DIST="CentOS"
      IGNORE_OS_RELEASE=1 # https://bugs.centos.org/view.php?id=8359
    elif [ "${DIST}" = "CloudLinux" ]; then
      DIST="CloudLinux"
    elif [ "${DIST}" = "Mandriva" ]; then
      DIST="Mandriva"
      PSEUDONAME=`cat /etc/mandriva-release | sed s/.*\(// | sed s/\)//`
      REV=`cat /etc/mandriva-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/oracle-release ]; then
      DIST="Oracle"
    elif [ -f /etc/rockstor-release ]; then
      DIST="Rockstor"
    else
      DIST="RedHat"
    fi

    PSEUDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
    REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`

  elif [ -f /etc/mandrake-release ] ; then
    DIST='Mandrake'
    PSEUDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
    REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`

  elif [ -f /etc/devuan_version ] ; then
    DIST="Devuan `cat /etc/devuan_version`"
    REV=""

  elif [ -f /etc/debian_version ] ; then
    DIST="Debian `cat /etc/debian_version`"
    REV=""
    if [ -f /usr/bin/lsb_release ] ; then
      ID=`lsb_release -i | awk -F ':' '{print $2}' | sed 's/	//g'`
    fi
    if [ "${ID}" = "Raspbian" ] ; then
      DIST="Raspbian `cat /etc/debian_version`"
    fi
    if [ -f /usr/bin/pveversion ]; then
      DIST="${DIST}/PVE `/usr/bin/pveversion | cut -d '/' -f 2`"
    fi
    
  elif [ -f /etc/gentoo-release ] ; then
    DIST="Gentoo"
    REV=$(tr -d '[[:alpha:]]' </etc/gentoo-release | tr -d " ")

  elif [ -f /etc/arch-release ] ; then
    DIST="Arch Linux"
    REV="" # Omit version since Arch Linux uses rolling releases
    IGNORE_LSB=1 # /etc/lsb-release would overwrite $REV with "rolling"
    
  elif [ -f /etc/photon-release ] ; then
    DIST=$(head -1 < /etc/photon-release)
    REV=$(sed -n -e 's/^.*PHOTON_BUILD_NUMBER=//p' /etc/photon-release)
    IGNORE_LSB=1 # photon os does not have /etc/lsb-release nor lsb_release

  elif [ -f /etc/openwrt_version ] ; then
    DIST="OpenWrt"
    REV=$(cat /etc/openwrt_version)

  elif [ -f /etc/pld-release ] ; then
    DIST=$(cat /etc/pld-release)
    REV=""

  elif [ -f /etc/SuSE-release ] ; then
    DIST=$(echo SLES $(grep VERSION /etc/SuSE-release | cut -d = -f 2 | tr -d " "))
    REV=$(echo SP$(grep PATCHLEVEL /etc/SuSE-release | cut -d = -f 2 | tr -d " "))
  fi

  if [ -x "$(command -v  awk)" ];  then # some distros do not ship with awk
    if [ "`uname -a | awk '{print $(NF)}'`" = "DD-WRT" ] ; then
      DIST="dd-wrt"
    fi
    if [ "`uname -a | awk '{print $(NF)}'`" = "ASUSWRT-Merlin" ] ; then
      DIST="ASUSWRT-Merlin"
      REV=`nvram show | grep buildno= | egrep -o '[0-9].[0-9].[0-9]'` > /dev/null 2>&1
    fi
  fi

  # try standardized os version methods
  if [ -f /etc/os-release -a "${IGNORE_OS_RELEASE}" != 1 ] ; then
    source /etc/os-release
    STD_DIST="$NAME"
    STD_REV="$VERSION_ID"
  elif [ -f /etc/lsb-release -a "${IGNORE_LSB}" != 1 ] ; then
    STD_DIST=$(lsb_release -si)
    STD_REV=$(lsb_release -sr)
  fi
  if [ -n "${STD_DIST}" ]; then
    DIST="${STD_DIST}"
  fi
  if [ -n "${STD_REV}" ]; then
    REV="${STD_REV}"
  fi

  if [ -n "${REV}" ]; then
    OSSTR="${DIST} ${REV}"
  else
    OSSTR="${DIST}"
  fi

elif [ "${OS}" = "Darwin" ] ; then
  if [ -f /usr/bin/sw_vers ] ; then
    OSSTR=`/usr/bin/sw_vers|grep -v Build|sed 's/^.*:.//'| tr "\n" ' '`
  fi

elif [ "${OS}" = "FreeBSD" ] ; then
  DIST=$(cat /etc/version | cut -d'-' -f 1)
  if [ "${DIST}" = "FreeNAS" ]; then
    OSSTR=`cat /etc/version | cut -d' ' -f 1`
  else
    OSSTR=`/usr/bin/uname -mior`
  fi
fi

echo ${OSSTR}
```
## Add the extended information to the snmpd.conf
1. ```sudo nano /etc/snmp/snmpd.conf```
2. Add the line:
```extend .1.3.6.1.4.1.2021.7890.1 distro /usr/bin/distro```
3. Restart the snmpd service
```sudo systemctl restart snmpd```
4. NOTE:  If you’ve already added the device to LibreNMS, edit the device and click “Rediscover”
5. DONE! Please like this video if you found it helpful and keep the discussion going in the comments!