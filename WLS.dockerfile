# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: WLS.dockerfile 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Dockerfile to build wls infrastructure base image
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
    ORACLE_HOME_NAME=fmw12.2.1.3.0 \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" 

# TODO depenance on install.rsp oraInst.loc
ENV ORACLE_HOME=$ORACLE_BASE/$ORACLE_HOME_NAME \
    OUD_RSP=$ORACLE_BASE/etc/install.rsp \
    OUI_LOC=$ORACLE_BASE/etc/oraInst.loc 

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV FMW_PKG=fmw_12.2.1.3.0_infrastructure_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.3.0_infrastructure.jar

# Copy packages
# ----------------------------------------------------------------------
COPY $FMW_PKG  $ORACLE_ROOT/

# Install 
# ----------------------------------------------------------------------
USER oracle
RUN cd $ORACLE_ROOT && \
# unpack jar file
    $JAVA_HOME/bin/jar xf $ORACLE_ROOT/$FMW_PKG && cd - && \
# start installation
    $JAVA_HOME/bin/java -jar $ORACLE_ROOT/$FMW_JAR -silent \
        -responseFile $OUD_RSP -invPtrLoc $OUI_LOC \
        -jreLoc $JAVA_HOME -ignoreSysPrereqs -force \
        -novalidation ORACLE_HOME=$ORACLE_HOME \
        INSTALL_TYPE="WebLogic Server" && \
    rm $ORACLE_ROOT/$FMW_JAR $ORACLE_ROOT/$FMW_PKG

WORKDIR ${ORACLE_HOME}

# Define default command to start script.
# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]