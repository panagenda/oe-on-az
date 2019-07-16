#!/bin/bash
# This script is to configure the OE appliance

set -e

# exports secrets if available; export manually otherwise
if [ -f "./creds.sh" ]; then
  source ./creds.sh
fi

# customize those if needed
export rg="pana-oe-rg"
export rgtf="pana-oe-tf-rg"
export secGroup="panaoe-secgroup"

az account set --subscription $subscriptionId

# get vault
export vaultName=$(az keyvault list --subscription=$subscriptionId -g $rgtf -o tsv | awk '{print $3}')

## extract and export secrets
export spSecret=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sp-secret -o tsv | awk '{print $5}')
export spId=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sp-id -o tsv | awk '{print $5}')

# login with service principal
az login --service-principal -u $spId -p $spSecret --tenant $tenantId

if test $? -ne 0
then
    echo "unable to login..."
	exit
else
    echo "login done..."
fi

# get public ip
export mypublicIp=$(dig +short myip.opendns.com @resolver1.opendns.com.)

# create network policy inbound rule
az network nsg rule create -g $rg --nsg-name $secGroup -n oe-config --priority 200 \
  --source-address-prefixes $mypublicIp --source-port-ranges "*" \
  --destination-address-prefixes '10.0.0.0/16' --destination-port-ranges 22 --access Allow \
  --protocol Tcp

if test $? -ne 0
then
    echo "unable to create security policy..."
	exit
else
    echo "security policy created..."
fi

export publicIp=$(terraform output | grep public_ip_address | awk '{print $3}')

#configure appliance
set +e
ssh -o "StrictHostKeyChecking no" root@$publicIp '/opt/panagenda/appdata/setup/setup.sh'

if test $? -ne 0
then
    echo "unable to configure appliance..."
	# no exit
else
    echo "appliance configured..."
fi

# delete network rule
az network nsg rule delete -g $rg --nsg-name $secGroup -n oe-config

if test $? -ne 0
then
    echo "unable to delete the security policy..."
	exit
else
    echo "security policy deleted..."
fi

# force logout
az logout  
