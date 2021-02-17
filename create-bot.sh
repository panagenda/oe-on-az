#!/bin/bash
# This script deploys an Azure Bot application
# Example: ./create-bot.sh "pana-oe-rg" "westeurope" "my-oe.my-domain.com"
if [[ -z $1 || -z $2 || -z $3 ]]; then
    echo "usage: ./create-bot.sh <resource-group> <location> <hostname>"
    exit
fi

echo "Checking Azure environment"
az account show --query "environmentName" | grep -q Government
if [ $? -eq 0 ]; then
    echo "Aborting Bot deployment because it is not supported in a GCC tenant"
    exit 0
fi

# customer specifc configuration
resourceGroup=$1
location=$2
endpoint="https://$3:4443/bot/messages"

# fixed configuration
pricingTier=S1
name="pana-oe-bot-$RANDOM$RANDOM"
displayName="ACE OfficeExpert"
iconUrl="https://files.panagenda.com/OfficeExpert/bot-icons/ace_bot_icon_v2.png"

# create app
appId=$(az ad app create --display-name $name --available-to-other-tenants 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['appId'])")

# create bot
az bot create --appid "$appId" --kind registration --name "$name" --resource-group "$resourceGroup" --display-name "$displayName" --endpoint "$endpoint" --location "$location" --sku "$pricingTier"

# set icon url (can't be done with create command)
az bot update --name "$name" --resource-group "$resourceGroup" --icon-url $iconUrl

az bot msteams create --name "$name" --resource-group "$resourceGroup"
