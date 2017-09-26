# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile 
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
FROM oraclelinux:7-slim

# Maintainer
# ----------------------------------------------------------------------
MAINTAINER Stefan Oehrli <stefan.oehrli@trivadis.com>

# Arguments for MOS Download
ARG MOS_USER
ARG MOS_PASSWORD

# copy all scripts to DOCKER_BIN
ADD scripts /opt/docker/bin/
ADD software /tmp/download

# image setup via shell script to reduce layers and optimize final disk usage
RUN /opt/docker/bin/setup_oud.sh MOS_USER=$MOS_USER MOS_PASSWORD=$MOS_PASSWORD

# OUD admin and ldap ports
EXPOSE 1389 1636 4444 8989

# Oracle data volume for OUD instance and configuration files
VOLUME ["/u01"]