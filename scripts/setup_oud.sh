#!/bin/bash
# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: setup_oud.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.09.22
# Revision...: 
# Purpose....: Setup script for docker base image 
# Notes......: Requires MOS credentials in .netrc
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ----------------------------------------------------------------------
# Modified...: 
# see git revision history for more information on changes/updates
# TODO.......: 
# TODO Check for /opt/docker/bin/.netrc file and provide alterantive
# TODO parametize MOS credentials
# ----------------------------------------------------------------------

# get the MOS Credentials
MOS_USER="${1#*=}"
MOS_PASSWORD="${2#*=}"

# Download and Package Variables
# JAVA 1.8u144
export JAVA_URL="https://updates.oracle.com/Orion/Services/download/p26512979_180144_Linux-x86-64.zip?aru=21443434&patch_file=p26512979_180144_Linux-x86-64.zip"
export JAVA_PKG="p26512979_180144_Linux-x86-64.zip"

# Oracle Unified Directory 12.2.1.3
export FMW_OUD_URL="https://updates.oracle.com/Orion/Services/download/p26270957_122130_Generic.zip?aru=21504981&patch_file=p26270957_122130_Generic.zip"
export FMW_OUD_PKG="p26270957_122130_Generic.zip"
export FMW_OUD_JAR=fmw_12.2.1.3.0_oud.jar

# define environment variables
export ORACLE_ROOT=/u00             # oracle root directory
export ORACLE_DATA=/u01             # oracle data directory
export ORACLE_BASE=/u00/app/oracle  # oracle base directory
export JAVA_DIR=/usr/java           # java home location
export DOWNLOAD=/tmp/download       # temporary download directory
mkdir -p $DOWNLOAD
chmod 777 $DOWNLOAD

# create a .netrc if it does not exists
if [[ ! -z "$MOS_USER" ]]
then
    if [[ ! -z "$MOS_PASSWORD" ]]
    then
        echo "machine login.oracle.com login $MOS_USER password $MOS_PASSWORD" >/opt/docker/bin/.netrc
    else
        echo "MOS_PASSWORD is empty"
    fi
elif [ ! -e /opt/docker/bin/.netrc ]
then
    >&2 echo "================================================================================="
    >&2 echo "MOS_USER nor .netrc definend. Download from MOS will fail. "
    >&2 echo "Make sure to copy $JAVA_PKG and "
    >&2 echo "$FMW_OUD_PKG to software."
    >&2 echo "================================================================================="
fi

echo "--- Setup Oracle OFA environment -----------------------------------------------"
echo "--- Create groups for Oracle software"
# create oracle groups
groupadd --gid 1000 oinstall
groupadd --gid 1010 osdba
groupadd --gid 1020 osoper
groupadd --gid 1030 osbackupdba
groupadd --gid 1040 oskmdba
groupadd --gid 1050 osdgdba

echo "--- Create user oracle"
# create oracle user
useradd --create-home --gid oinstall --shell /bin/bash \
    --groups oinstall,osdba,osoper,osbackupdba,osdgdba,oskmdba \
    oracle

echo "--- Create OFA directory structure"
# create oracle directories
mkdir -p $ORACLE_ROOT
mkdir -p $ORACLE_DATA
mkdir -p $ORACLE_BASE
mkdir -p $ORACLE_BASE/etc
mkdir -p $ORACLE_BASE/local
mkdir -p $ORACLE_BASE/product

echo "--- Create response and inventory loc files"
# create an oraInst.loc file
echo "inventory_loc=$ORACLE_BASE/oraInventory" > $ORACLE_BASE/etc/oraInst.loc
echo "inst_group=oinstall" >> $ORACLE_BASE/etc/oraInst.loc

# create a generic response file for OUD/WLS
echo "[ENGINE]" > $ORACLE_BASE/etc/install.rsp
echo "Response File Version=1.0.0.0.0" >> $ORACLE_BASE/etc/install.rsp
echo "[GENERIC]" >> $ORACLE_BASE/etc/install.rsp
echo "DECLINE_SECURITY_UPDATES=true" $ORACLE_BASE/etc/install.rsp
echo "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false" >> $ORACLE_BASE/etc/install.rsp

# change permissions and ownership
chmod a+xr $ORACLE_ROOT $ORACLE_DATA
chown oracle:oinstall -R $ORACLE_ROOT $ORACLE_DATA

echo "--- Upgrade OS and install additional Packages ---------------------------------"
# update existing packages
yum upgrade -y

# install basic packages util-linux, libaio 
yum install -y libaio procps-ng util-linux hostname which unzip zip tar sudo

# add oracle to the sudoers
echo "oracle  ALL=(ALL)   NOPASSWD: ALL" >>/etc/sudoers

# Download Server JRE 8u144 package if it does not exist /tmp/download
if [ ! -e $DOWNLOAD/$JAVA_PKG ]
then
    
    echo "--- Download Server JRE 8u144 from MOS -----------------------------------------"
    curl --netrc-file /opt/docker/bin/.netrc --cookie-jar $DOWNLOAD/cookie-jar.txt \
    --location-trusted $JAVA_URL -o $DOWNLOAD/$JAVA_PKG
else
    echo "--- Use local copy of $DOWNLOAD/$JAVA_PKG --------------------------------------"
fi

echo "--- Install Server JRE 8u144 ---------------------------------------------------"
# create java default folder
mkdir -p $JAVA_DIR

# unzip and untar Server JRE
if [[ $DOWNLOAD/$JAVA_PKG =~ \.zip$ ]]
then
    unzip -p $DOWNLOAD/$JAVA_PKG *tar* |tar zx -C $JAVA_DIR
else
    tar zxf $DOWNLOAD/$JAVA_PKG -C $JAVA_DIR
fi

# set the JAVA alternatives directories and links
export JAVA_DIR=$(ls -1 -d /usr/java/*)
ln -s $JAVA_DIR /usr/java/latest
ln -s $JAVA_DIR /usr/java/default
alternatives --install /usr/bin/java java $JAVA_DIR/bin/java 20000 
alternatives --install /usr/bin/javac javac $JAVA_DIR/bin/javac 20000
alternatives --install /usr/bin/jar jar $JAVA_DIR/bin/jar 20000

# Download Oracle Unified Directory 12.2.1.3.0 if it doesn't exist /tmp/download
if [ ! -e $DOWNLOAD/$FMW_OUD_PKG ]
then
    echo "--- Download Oracle Unified Directory 12.2.1.3.0 from OTN ----------------------"
    curl --netrc-file /opt/docker/bin/.netrc --cookie-jar $DOWNLOAD/cookie-jar.txt \
    --location-trusted $FMW_OUD_URL -o $DOWNLOAD/$FMW_OUD_PKG
else
    echo "--- Use local copy of $DOWNLOAD/$FMW_OUD_PKG ----------------"
fi

echo "--- Install Oracle Unified Directory 12.2.1.3.0 --------------------------------"
cd $DOWNLOAD
$JAVA_HOME/bin/jar xf $DOWNLOAD/$FMW_OUD_PKG
cd -

# Install OUD in silent mode
sudo -u oracle java -jar $DOWNLOAD/$FMW_OUD_JAR -silent \
    -responseFile $ORACLE_BASE/etc/install.rsp \
    -invPtrLoc $ORACLE_BASE/etc/oraInst.loc \
    -ignoreSysPrereqs -force \
    -novalidation ORACLE_HOME=$ORACLE_BASE/product/fmw12.2.1.3.0 \
    INSTALL_TYPE="Standalone Oracle Unified Directory Server (Managed independently of WebLogic server)"

# clean up
echo "--- Clean up yum cache and temporary download files ----------------------------"
yum clean all
rm -rf /var/cache/yum
rm -rf $DOWNLOAD
rm /opt/docker/bin/.netrc
echo "=== Done runing $0 ==================================="