# -----------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------------
# Name.......: Dockerfile 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Dockerfile to build oud image 
# Notes......: --
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# -----------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# TODO.......:
# - avoid temporary oud jar file in image
# - add oud or base env
# -----------------------------------------------------------------------------
#
FROM oraclelinux:7-slim

MAINTAINER Stefan Oehrli <stefan.oehrli@trivadis.com>

# Build Argumet variables
ARG ORACLE_BASE=/u00/app/oracle
ARG ORACLE_HOME_NAME=oud12.2.1.3.0

# Environment variables required for this build (do NOT change)
ENV JAVA_PKG=jdk-8u*-linux-x64.tar.gz \
    OUD_PKG=fmw_*_oud.jar

# Use second ENV so that variable get substituted
ENV ORACLE_HOME=$ORACLE_BASE/product/$ORACLE_HOME_NAME \
    OUD_RSP=$ORACLE_BASE/etc/install_oud.rsp \
    OUI_LOC=$ORACLE_BASE/etc/oraInst.loc 

# copy and unpack java package
ADD $JAVA_PKG $ORACLE_BASE/product

# update base linux, install package and create oud user
RUN yum -y upgrade && \
    yum clean all && \
    rm -rf /var/cache/yum && \

# add user and group
    groupadd -r oud && \
    useradd -g oud oud && \

# set ownership to user oud
    chown -R oud:oud $ORACLE_BASE

# run as oud user as of now
USER oud

# copy oud packages
COPY $OUD_PKG $ORACLE_BASE/install/

# just check a few things
RUN export JAVA_HOME=$(ls -d $ORACLE_BASE/product/jdk*) && \
    mkdir -p $ORACLE_BASE/etc $ORACLE_BASE/local && \

# create an oraInst.loc file
    echo "inventory_loc=$ORACLE_BASE/oraInventory" > $OUI_LOC && \
    echo "inst_group=oinstall" >> $OUI_LOC && \

# create a response file
    echo "[ENGINE]" > $OUD_RSP && \
    echo "Response File Version=1.0.0.0.0" >> $OUD_RSP && \
    echo "[GENERIC]" >> $OUD_RSP && \
    echo "ORACLE_HOME=$ORACLE_HOME" >> $OUD_RSP && \
    echo "INSTALL_TYPE=Standalone Oracle Unified Directory Server (Managed independently of WebLogic server)" >> $OUD_RSP && \
    echo "DECLINE_SECURITY_UPDATES=true" >> $OUD_RSP && \
    echo "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false" >> $OUD_RSP && \

# install oud in silent mode
    $JAVA_HOME/bin/java -jar $ORACLE_BASE/install/$OUD_PKG \
       -silent -responseFile $OUD_RSP \
       -jreLoc $JAVA_HOME \
       -invPtrLoc $ORACLE_BASE/etc/oraInst.loc && \

# set default JAVA_HOME for oud
    echo "default.java-home=$JAVA_HOME" >> $ORACLE_HOME/oud/config/java.properties && \
    $ORACLE_HOME/oud/bin/dsjavaproperties

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]