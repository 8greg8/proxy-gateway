#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -e

# Paths
SECRETS_DIR="/data/secrets"
KEYTAB="/etc/$AD_USER.keytab"

# Get user and password
# Create keytab
echo "***"
echo "Creating keytab"
{
    echo "addent -password -p ${AD_USER} -k 1 -e aes256-sha1"
    sleep 1
    echo "$(cat "${SECRETS_DIR}/ad_pass")"
    sleep 1
    echo "wkt ${KEYTAB}"
} | ktutil
echo "***"
echo ""

# kinit
echo "***"
echo "Executing kinit"
kinit -kt $KEYTAB $AD_USER
klist
echo "***"
echo ""

# Run cron job to renew TGT every 5 hours
echo "***"
echo "Starting cron jobs"
crond
echo "***"
echo ""

# Run cntlm
echo "***"
echo "Starting cntlm-gss"
echo "***"
echo ""
/usr/sbin/cntlm -v -f -a gss -c "${CNTLM_CONFIG:-/etc/cntlm.conf}"
