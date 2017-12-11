#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: create_OUD_instance.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: Helper script to create the OUD instance 
# Notes......: Script to create an OUD instance. If configuration files are
#              provided, the will be used to configure the instance.
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ---------------------------------------------------------------------------
# Modified...: 
# see git revision history for more information on changes/updates
# TODO.......:
# ---------------------------------------------------------------------------
# - Customization -----------------------------------------------------------
export LDAP_PORT=${LDAP_PORT:-1389}                     # Default LDAP port
export LDAPS_PORT=${LDAPS_PORT:-1636}                   # Default LDAPS port
export REP_PORT=${REP_PORT:-8989}                       # Default replication port
export ADMIN_PORT=${ADMIN_PORT:-4444}                   # Default admin port
export ADMIN_USER=${ADMIN_USER:-'cn=Directory Manager'} # Default directory admin user
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-""}             # Default directory admin password
export BASEDN=${BASEDN:-'dc=postgasse,dc=org'}          # Default directory base DN
export SAMPLE_DATA=${SAMPLE_DATA:-'TRUE'}               # Flag to load sample data
export OUD_PROXY=${OUD_PROXY:-'FALSE'}                  # Flag to create proxy instance

# default folder for OUD instance init scripts
export OUD_INSTANCE_INIT=${OUD_INSTANCE_INIT:-$ORACLE_DATA/scripts}
# - End of Customization ----------------------------------------------------

echo "--- Setup OUD environment on volume ${ORACLE_DATA} --------------------"

# create instance and domain directories on volume
mkdir -v -p ${ORACLE_DATA}
mkdir -v -p ${ORACLE_DATA}/backup
mkdir -v -p ${ORACLE_DATA}/domains
mkdir -v -p ${ORACLE_DATA}/etc
mkdir -v -p ${ORACLE_DATA}/instances
mkdir -v -p ${ORACLE_DATA}/log
mkdir -v -p ${ORACLE_DATA}/scripts

# create oudtab file
OUDTAB=${ORACLE_DATA}/etc/oudtab
echo "# OUD Config File"                                > ${OUDTAB}
echo "#  1 : OUD Instance Name"                         >>${OUDTAB}
echo "#  2 : OUD LDAP Port"                             >>${OUDTAB}
echo "#  3 : OUD LDAPS Port"                            >>${OUDTAB}
echo "#  4 : OUD Admin Port"                            >>${OUDTAB}
echo "#  5 : OUD Replication Port"                      >>${OUDTAB}
echo "#---------------------------------------------"   >>${OUDTAB}
echo "${OUD_INSTANCE}:${LDAP_PORT}:${LDAPS_PORT}:${ADMIN_PORT}:${REP_PORT}" >>${OUDTAB}

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
    echo "    ----> Directory Admin : ${ADMIN_USER} "
    echo "    ----> Admin password  : $s"
    echo "---------------------------------------------------------------"
else
    s=${ADMIN_PASSWORD}
    echo "---------------------------------------------------------------"
    echo "    Oracle Unified Directory Server auto generated instance"
    echo "    admin password :"
    echo "    ----> Directory Admin : ${ADMIN_USER} "
    echo "    ----> Admin password  : $s"
    echo "---------------------------------------------------------------"
fi

# write password file
echo "$s" > ${ORACLE_DATA}/etc/${OUD_INSTANCE}_pwd.txt

echo "--- Create OUD instance --------------------------------------------------------"
echo "  OUD_INSTANCE      = ${OUD_INSTANCE}"
echo "  OUD_INSTANCE_BASE = ${OUD_INSTANCE_BASE}"
echo "  OUD_INSTANCE_HOME = ${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
echo "  LDAP_PORT         = ${LDAP_PORT}"
echo "  LDAPS_PORT        = ${LDAPS_PORT}"
echo "  REP_PORT          = ${REP_PORT}"
echo "  ADMIN_PORT        = ${ADMIN_PORT}"
echo "  ADMIN_USER        = ${ADMIN_USER}"
echo "  BASEDN            = ${BASEDN}"
echo "  OUD_PROXY         = ${OUD_PROXY}"
echo ""

# Normalize CREATE_INSTANCE
export OUD_PROXY=$(echo $OUD_PROXY| sed 's/^false$/0/gi')
export OUD_PROXY=$(echo $OUD_PROXY| sed 's/^true$/1/gi')

if [ ${OUD_PROXY} -eq 0 ]; then
# Create an directory
${ORACLE_BASE}/product/${ORACLE_HOME_NAME}/oud/oud-setup \
    --cli \
    --instancePath ${OUD_INSTANCE_HOME}/OUD \
    --adminConnectorPort ${ADMIN_PORT} \
    --rootUserDN "${ADMIN_USER}" \
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
    if [ $? -eq 0 ]; then
        echo "--- Successfully created OUD instance (${OUD_INSTANCE}) ------------------------"
        # Execute custom provided setup scripts
        ${DOCKER_SCRIPTS}/config_OUD_Instance.sh ${OUD_INSTANCE_INIT}/setup
    else
        echo "--- ERROR creating OUD instance (${OUD_INSTANCE}) ------------------------------"
        exit 1
    fi
fi
# --- EOF -------------------------------------------------------------------