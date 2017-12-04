# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Dockerfile to build OUD image
# Notes......: --
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# TODO.......:
# --
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

# Arguments for Oracle Installation
ARG ORACLE_ROOT
ARG ORACLE_DATA
ARG ORACLE_BASE

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV DOWNLOAD=/tmp/download \
    DOCKER_SCRIPTS=/opt/docker/bin \
    ORACLE_ROOT=${ORACLE_ROOT:-/u00} \
    ORACLE_DATA=${ORACLE_DATA:-/u01} \
    ORACLE_BASE=${ORACLE_BASE:-/u00/app/oracle} \
    ORACLE_HOME_NAME=fmw12.2.1.3.0 \
    OUD_INSTANCE=${OUD_INSTANCE:-oud_docker} \
    OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-/u01/instances} \
    OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE} \
    LDAP_PORT=${LDAP_PORT:-1389} \
    LDAPS_PORT=${LDAPS_PORT:-1636} \
    REP_PORT=${REP_PORT:-8989} \
    ADMIN_PORT=${ADMIN_PORT:-4444} \
    ADMIN_USER=${ADMIN_USER:-'Directory Manager'} \
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-""} \
    BASEDN=${BASEDN:-'dc=postgasse,dc=org'} \
    SAMPLE_DATA=${SAMPLE_DATA:-TRUE} \
    OUD_PROXY=${OUD_PROXY:-FALSE}

# copy all scripts to DOCKER_BIN
COPY scripts ${DOCKER_SCRIPTS}
COPY software ${DOWNLOAD}

# Java and OUD base environment setup via shell script to reduce layers and 
# optimize final disk usage
RUN ${DOCKER_SCRIPTS}/setup_java.sh MOS_USER=${MOS_USER} MOS_PASSWORD=${MOS_PASSWORD} && \
    ${DOCKER_SCRIPTS}/setup_oudbase.sh

# Switch to user oracle, oracle software as to be installed with regular user
USER oracle

# Instal OUD / OUDSM via shell script to reduce layers and optimize final disk usage
RUN ${DOCKER_SCRIPTS}/setup_oud.sh MOS_USER=${MOS_USER} MOS_PASSWORD=${MOS_PASSWORD}

# OUD admin and ldap ports as well the OUDSM console
EXPOSE ${LDAP_PORT} ${LDAPS_PORT} ${ADMIN_PORT} ${REP_PORT}

# Oracle data volume for OUD instance and configuration files
VOLUME ["${ORACLE_DATA}"]

# entrypoint for OUDSM domain creation, startup and graceful shutdown
ENTRYPOINT ["/opt/docker/bin/create_and_start_OUD_Instance.sh"]
CMD [""]
# --- EOF --------------------------------------------------------------