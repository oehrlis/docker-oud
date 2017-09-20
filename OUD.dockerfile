# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: OUD.dockerfile 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Dockerfile to build oud standalone base image
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
FROM oehrlis/tvd

# Maintainer
# ----------------------------------------------------------------------
MAINTAINER Stefan Oehrli <stefan.oehrli@trivadis.com>

#Common ENV
# ----------------------------------------------------------------------
ENV ORACLE_ROOT=/u00 \
    ORACLE_BASE=/u00/oracle \
    ORACLE_HOME_NAME=oud12.2.1.3.0 \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" 

# TODO depenance on install.rsp oraInst.loc
ENV ORACLE_HOME=$ORACLE_BASE/$ORACLE_HOME_NAME \
    OUI_RSP=$ORACLE_BASE/etc/install.rsp \
    OUI_LOC=$ORACLE_BASE/etc/oraInst.loc 

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV OUD_PKG=fmw_12.2.1.3.0_oud_Disk1_1of1.zip \
    OUD_JAR=fmw_12.2.1.3.0_oud.jar

# Copy packages
# ----------------------------------------------------------------------
COPY $OUD_PKG  $ORACLE_ROOT/

# Install 
# ----------------------------------------------------------------------
USER oracle
RUN cd $ORACLE_ROOT && \
# unpack jar file
    $JAVA_HOME/bin/jar xf $ORACLE_ROOT/$OUD_PKG && cd - && \
# install oud in silent mode
    $JAVA_HOME/bin/java -jar $ORACLE_ROOT/$OUD_JAR -silent \
        -responseFile $OUI_RSP -invPtrLoc $OUI_LOC \
        -jreLoc $JAVA_HOME -ignoreSysPrereqs -force \
        -novalidation ORACLE_HOME=$ORACLE_HOME \
        INSTALL_TYPE="Standalone Oracle Unified Directory Server (Managed independently of WebLogic server)" && \
    rm $ORACLE_ROOT/$OUD_JAR $ORACLE_ROOT/$OUD_PKG && \

# set default JAVA_HOME for oud
    echo "default.java-home=$JAVA_HOME" >> $ORACLE_HOME/oud/config/java.properties && \
    $ORACLE_HOME/oud/bin/dsjavaproperties
    
WORKDIR ${ORACLE_HOME}

# Define default command to start script.
# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]