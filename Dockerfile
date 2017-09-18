# -----------------------------------------------------------------------------
# $Id: $
# -----------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------------
# Name.......: $Filename: Dockerfile $
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Korn Shell wrapper strict for the Trivadis Recovery Utility 
# Notes......: See pod text below or perldoc of perl script $Filename: encode_config.ksh $
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# -----------------------------------------------------------------------------
# Modified :
# see SVN revision history for more information on changes/updates
# svn log $Filename: encode_config.ksh $
# -----------------------------------------------------------------------------
#
FROM oraclelinux:7-slim

MAINTAINER Stefan Oehrli <stefan.oehrli@trivadis.com>

ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz \
    JAVA_HOME=/usr/java/default