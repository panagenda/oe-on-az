#!/bin/bash
# This script is to configure the OE appliance
# Example: ./config.sh "my-oe.my-domain.com" "Europe/Berlin" "my-oe-secret" "my-root-password"

set -e

# exports secrets if available; export manually otherwise
if [ -f "./creds.sh" ]; then
  source ./creds.sh
fi

# customize those if needed
export rg="pana-oe-rg"
export rgtf="pana-oe-tf-rg"
export secGroup="panaoe-secgroup"

# get input

if [ -z $1 ]; then
    echo "Please provide all required parameters."
    exit
fi
if [ -z $2 ]; then
    echo "Please provide all required parameters."
    exit
fi
if [ -z $3 ]; then
    echo "Please provide all required parameters."
    exit
fi
if [ -z $4 ]; then
    echo "Please provide all required parameters."
    exit
fi

export hostname=$1
export timezone=$2
export secret=$3
export rootPsw=$4

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

# get ip
export ip=$(terraform output | grep ip_address | awk '{print $3}')

configureAccess () {
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
}

configureAppliance () {
#configure appliance
set +e
echo "Please provide the root password"
ssh -o "StrictHostKeyChecking no" root@$ip "echo $hostname >> /etc/hostname && \
 hostnamectl set-hostname $hostname && \
 timedatectl set-timezone $timezone && \
 /opt/panagenda/appdata/setup/setup.sh $hostname $secret && \
 echo $rootPsw | passwd --stdin root"

if test $? -ne 0
then
    echo "unable to configure appliance..."
	# no exit
else
    echo "appliance configured..."
fi
}

removeAccess () {
# delete network rule
az network nsg rule delete -g $rg --nsg-name $secGroup -n oe-config

if test $? -ne 0
then
    echo "unable to delete the security policy..."
	exit
else
    echo "security policy deleted..."
fi
}

# get network policy groups
export nsg=$(az network nsg list --resource-group $rg --subscription $subscriptionId | grep -i $secGroup | wc -l | awk '{print $1}')

# runs functions
if test $nsg -ge 1
then
    configureAccess
    configureAppliance
    removeAccess
else
    configureAppliance
fi
