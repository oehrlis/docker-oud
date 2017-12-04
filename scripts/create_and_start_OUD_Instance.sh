#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: create_and_start_OUD_Domain.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
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
function term_oud() {
    echo "---------------------------------------------------------------"
    echo "SIGTERM received, shutting down the server!"
    echo "---------------------------------------------------------------"
    ${INSTANCE_HOME}/OUD/bin/stop-ds
}

# ---------------------------------------------------------------------------
# SIGKILL handler
# ---------------------------------------------------------------------------
function kill_oud() {
    echo "---------------------------------------------------------------"
    echo "SIGKILL received, shutting down the server!"
    echo "---------------------------------------------------------------"
kill -9 $childPID
}

# Set SIGTERM handler
trap term_oud SIGTERM

# Set SIGKILL handler
trap kill_oud SIGKILL

# check if AdminServer.log does exists
ADD_DOMAIN=1
if [ ! -f ${INSTANCE_HOME}/OUD/config/config.ldif ]; then
    ADD_DOMAIN=0
fi

# Create Domain only if 1st execution
if [ ${ADD_DOMAIN} -eq 0 ]; then
echo "--- Setup OUD environment on volume --------------------------------------------"
    # create instance and domain directories on volume
    mkdir -v -p ${ORACLE_DATA}
    mkdir -v -p ${ORACLE_DATA}/backup
    mkdir -v -p ${ORACLE_DATA}/domains
    mkdir -v -p ${ORACLE_DATA}/etc
    mkdir -v -p ${ORACLE_DATA}/instances
    mkdir -v -p ${ORACLE_DATA}/log

    # create oudtab file
    OUDTAB=${ORACLE_DATA}/etc/oudtab
    echo "# OUD Config File"                                > ${OUDTAB}
    echo "#  1 : OUD Instance Name"                         >>${OUDTAB}
    echo "#  2 : OUD LDAP Port"                             >>${OUDTAB}
    echo "#  3 : OUD LDAPS Port"                            >>${OUDTAB}
    echo "#  4 : OUD Admin Port"                            >>${OUDTAB}
    echo "#  5 : OUD Replication Port"                      >>${OUDTAB}
    echo "#---------------------------------------------"   >>${OUDTAB}
    echo "${INSTANCE_NAME}:${LDAP_PORT}:${LDAP_PORT}:${ADMIN_PORT}:${REP_PORT}" >>${OUDTAB}

    # copy default config files
    cp ${ORACLE_BASE}/local/etc/*.conf ${ORACLE_DATA}/etc
    
    # generate a password
    if [ -z ${ADMIN_PASSWORD} ]; then
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
        echo "    Oracle Unified Directory Server auto generated instance"
        echo "    admin password :"
        echo "    ----> Directory Admin : cn=${ADMIN_USER} "
        echo "    ----> Admin password  : $s"
        echo "---------------------------------------------------------------"
    else
        s=${ADMIN_PASSWORD}
        echo "---------------------------------------------------------------"
        echo "    Oracle Unified Directory Server auto generated instance"
        echo "    admin password :"
        echo "    ----> Directory Admin : cn=${ADMIN_USER} "
        echo "    ----> Admin password  : $s"
        echo "---------------------------------------------------------------"
    fi

    # write password file
    echo "$s" > ${ORACLE_DATA}/etc/${INSTANCE_NAME}_pwd.txt

    echo "--- Create OUD instance --------------------------------------------------------"
    echo "  OUD_INSTANCE=${OUD_INSTANCE}"
    echo "  OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE}"
    echo "  OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
    echo "  LDAP_PORT=${LDAP_PORT}"
    echo "  LDAPS_PORT=${LDAPS_PORT}"
    echo "  REP_PORT=${REP_PORT}"
    echo "  ADMIN_PORT=${ADMIN_PORT}"
    echo "  ADMIN_USER=${ADMIN_USER}"
    echo "  BASEDN=${BASEDN}"
    # Create an directory
    ${ORACLE_BASE}/product/fmw12.2.1.3.0/oud/oud-setup \
        --cli \
        --instancePath ${OUD_INSTANCE_HOME}/OUD \
        --adminConnectorPort ${ADMIN_PORT} \
        --rootUserDN "cn=${ADMIN_USER}" \
        --rootUserPasswordFile ${ORACLE_DATA}/etc/${OUD_INSTANCE}_pwd.txt \
        --ldapPort ${LDAP_PORT} \
        --ldapsPort ${LDAPS_PORT} \
        --generateSelfSignedCertificate \
        --hostname $(hostname) \
        --baseDN ${BASEDN} \
        --addBaseEntry \
        --serverTuning jvm-default \
        --offlineToolsTuning autotune \
        --no-prompt \
        --noPropertiesFile
fi

# Start Admin Server and tail the logs
echo "---------------------------------------------------------------"
echo "    Start Oracle WebLogic Server OUD Instance:"
echo "---------------------------------------------------------------"
${INSTANCE_HOME}/OUD/bin/start-ds
touch ${INSTANCE_HOME}/OUD/logs/server.out
tail -f ${INSTANCE_HOME}/OUD/logs/server.out &

childPID=$!
wait $childPID