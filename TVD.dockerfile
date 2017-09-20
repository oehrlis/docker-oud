# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: TVD.dockerfile 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Dockerfile to build a base image for oud, wls and oudsm
# Notes......: --
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# TODO.......:
# - avoid temporary oud jar file in image
# - add oud or base env
# ----------------------------------------------------------------------

# Pull base image
# ----------------------------------------------------------------------
FROM oracle/serverjre:8

# Maintainer
# ----------------------------------------------------------------------
MAINTAINER Stefan Oehrli <stefan.oehrli@trivadis.com>

#Common ENV
# ----------------------------------------------------------------------
ENV ORACLE_ROOT=/u00 \
    ORACLE_BASE=/u00/oracle

ENV ORACLE_HOME=$ORACLE_BASE/$ORACLE_HOME_NAME \
    OUI_RSP=$ORACLE_BASE/etc/install.rsp \
    OUI_LOC=$ORACLE_BASE/etc/oraInst.loc 

# Setup subdirectory for FMW install package and container-scripts
# ----------------------------------------------------------------------
RUN mkdir -p $ORACLE_ROOT && \ 
    chmod a+xr $ORACLE_ROOT && \
# create oracle user
    useradd -b $ORACLE_ROOT -d $ORACLE_BASE -m -s /bin/bash oracle && \
    chown oracle:oracle -R $ORACLE_ROOT && \
# install libaio and update OS
    yum install -y libaio && \
    yum clean all && \
    rm -rf /var/cache/yum

# Prepare oracle environment 
# ----------------------------------------------------------------------
USER oracle
RUN  mkdir -p $ORACLE_BASE/etc $ORACLE_BASE/local && \

# create an oraInst.loc file
    echo "inventory_loc=$ORACLE_BASE/oraInventory" > $OUI_LOC && \
    echo "inst_group=oinstall" >> $OUI_LOC && \

# create a response file
    echo "[ENGINE]" > $OUI_RSP && \
    echo "Response File Version=1.0.0.0.0" >> $OUI_RSP && \
    echo "[GENERIC]" >> $OUI_RSP && \
    echo "DECLINE_SECURITY_UPDATES=true" >> $OUI_RSP && \
    echo "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false" >> $OUI_RSP

WORKDIR ${ORACLE_HOME}

# Define default command to start script.
# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]