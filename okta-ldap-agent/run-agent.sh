#!/usr/bin/env bash

set -e

# hacky way to wait for the LDAP server to start
sleep 5

. /opt/Okta/OktaLDAPAgent/scripts/defs.sh

# check if the agent has already been configured
if [ ! -f "${ConfigFile}" ]; then
  $JAVA -Dagent_home="${AgentInstallPrefix}" -Dlogback.configurationFile="${AgentInstallPrefix}/conf/logback.xml" -Dfile.encoding=UTF8 -jar "${AgentJar}" \
        -mode "register" \
        -orgUrl "${OKTA_URL}" \
        -ldapHost "${LDAP_HOST}" \
        -ldapPort "${LDAP_PORT}" \
        -ldapAdminDN "${LDAP_ADMIN_USERNAME}" \
        -ldapAdminPassword "${LDAP_ADMIN_PASSWORD}" \
        -baseDN "${LDAP_ROOT}" \
        -configFilePath "${ConfigFile}" \
        -noInstance "true" \
        -proxyEnabled "" \
        -proxyHost "" \
        -proxyPort "" \
        -proxyUser "" \
        -proxyPassword "" \
        -ldapUseSSL "" \
        -ldapSSLPort "" \
        -sslPinningEnabled ""
fi

#Start the Agent
$JAVA -Dagent_home="$AgentInstallPrefix" -Dlogback.configurationFile="$AgentInstallPrefix/conf/logback.xml" -Dfile.encoding=UTF8 -jar "${AgentJar}" \
  -mode "normal" \
  -configFilePath "${ConfigFile}"
