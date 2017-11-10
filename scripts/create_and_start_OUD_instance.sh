#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: createAndStartOUDSMDomain.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Build script for docker image 
# Notes......: Script does look for the AdminServer.log. If it does not exist
#              it assume that the container is started the first time. A new
#              OUDSM domain will be created.
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# TODO.......:
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# SIGTERM handler
# ---------------------------------------------------------------------------
function term_wls() {
    echo "---------------------------------------------------------------"
    echo "SIGTERM received, shutting down the server!"
    echo "---------------------------------------------------------------"
    su - oracle -c "${DOMAIN_HOME}/bin/stopWebLogic.sh"
}

# ---------------------------------------------------------------------------
# SIGKILL handler
# ---------------------------------------------------------------------------
function kill_wls() {
    echo "---------------------------------------------------------------"
    echo "SIGKILL received, shutting down the server!"
    echo "---------------------------------------------------------------"
kill -9 $childPID
}

# Set SIGTERM handler
trap term_wls SIGTERM

# Set SIGKILL handler
trap kill_wls SIGKILL

# check if AdminServer.log does exists
ADD_DOMAIN=1
if [ ! -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ $ADD_DOMAIN -eq 0 ]; then
    if [ -z $ADMIN_PASSWORD ]; then
        # Auto generate Oracle WebLogic Server admin password
        while true; do
            s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 8 | head -n 1)
            if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
                break
            else
                echo "Password does not Match the criteria, re-generating..."
            fi
        done
        echo "---------------------------------------------------------------"
        echo "    Oracle WebLogic Server Auto Generated OUDSM Domain:"
        echo "    ----> 'weblogic' admin password: $s"
        echo "---------------------------------------------------------------"
    else
        s=${ADMIN_PASSWORD}
        echo "---------------------------------------------------------------"
        echo "    Oracle WebLogic Server Auto Generated OUDSM Domain:"
        echo "    ----> 'weblogic' admin password: $s"
        echo "---------------------------------------------------------------"
    fi 
    sed -i -e "s|ADMIN_PASSWORD|$s|g" /opt/docker/bin/create_OUDSM.py

    # Create an empty domain
    su - oracle -c "/u00/app/oracle/product/fmw12.2.1.3.0/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /opt/docker/bin/create_OUDSM.py"
    su - oracle -c "${DOMAIN_HOME}/bin/setDomainEnv.sh" 
fi

# Start Admin Server and tail the logs
echo "---------------------------------------------------------------"
echo "    Start Oracle WebLogic Server OUDSM Domain:"
echo "---------------------------------------------------------------"
su - oracle -c "${DOMAIN_HOME}/startWebLogic.sh"
su - oracle -c "touch ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log"
tail -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log &

childPID=$!
wait $childPID