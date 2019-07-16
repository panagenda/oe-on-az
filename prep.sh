#!/bin/bash

# Run this script to configure all everything to use TF

set -e

# exports secrets if available; export manually otherwise
if [ -f "./creds.sh" ]; then
  source ./creds.sh
fi

az account set --subscription $subscriptionId

# customize those if needed
export rg="pana-oe-tf-rg"
export location="West Europe"
export sku="Standard_LRS"
export vaultName="oevault$RANDOM$RANDOM"
export saName="panaoesa$RANDOM$RANDOM"
export scName="panaoesc$RANDOM$RANDOM"
export spName="pana-oe-sp-$RANDOM$RANDOM"

# creates a new resource group which will be used for the vault and TF state
az group create --name "$rg" \
    --location "$location" \
    --subscription="$subscriptionId"

if test $? -ne 0
then
    echo "resource group couldn't be created..."
	exit
else
    echo "resource group created..."
fi

# creates a vault to store secrets
az keyvault create --name "$vaultName" \
    --resource-group $rg \
    --location "$location" \
    --subscription=$subscriptionId

if test $? -ne 0
then
    echo "vault couldn't be created..."
	exit
else
    echo "vault created..."
fi

# creates storage account used by TF
az storage account create --resource-group $rg \
    --name $saName \
    --sku $sku \
    --encryption-services blob \
    --subscription=$subscriptionId

if test $? -ne 0
then
    echo "storage account couldn't be created..."
	exit
else
    echo "storage account created..."
fi

# gets storage account key
export accountKey=$(az storage account keys list --subscription=$subscriptionId --resource-group $rg --account-name $saName --query [0].value -o tsv )

# creats storage container used by TF
az storage container create --name $scName --account-name $saName --account-key $accountKey

if test $? -ne 0
then
    echo "storage container couldn't be created..."
	exit
else
    echo "storage container created..."
fi

# saves secrets to vault
az keyvault secret set --vault-name $vaultName \
    --name "sa-key" \
    --value "$accountKey"
az keyvault secret set --vault-name $vaultName \
    --name "sa-name" \
    --value "$saName"
az keyvault secret set --vault-name $vaultName \
    --name "sc-name" \
    --value "$scName"

if test $? -ne 0
then
    echo "secrets couldn't be saved..."
	exit
else
    echo "secrets are saved in vault..."
fi

# creates a service principal
# only valid for 1 year. unable to define years due to a bug https://github.com/Azure/azure-cli/issues/700
export sp=$(az ad sp create-for-rbac --name $spName --role="Contributor" --scopes="/subscriptions/$subscriptionId" -o tsv)

if test $? -ne 0
then
    echo "service principal couldn't be created..."
	exit
else
    echo "service principal created..."
fi
# gets id and secret
export spSecret=$(echo $sp | awk '{print $4}')
export spId=$(echo $sp | awk '{print $1}')

# save secrets to vault
az keyvault secret set --vault-name $vaultName \
    --name "sp-id" \
    --value "$spId"
az keyvault secret set --vault-name $vaultName \
    --name "sp-secret" \
    --value "$spSecret"

if test $? -ne 0
then
    echo "secrets couldn't be saved..."
	exit
else
    echo "secrets are saved in vault..."
fi

# add azure ad permission 
az ad app permission add --id $spId --api 00000002-0000-0000-c000-000000000000 --api-permissions 1cda74f2-2616-4834-b122-5cb1b07f8a59=Role
if test $? -ne 0
then
    echo "api permissions couldn't be added..."
	exit
else
    echo "api permissions added..."
fi

az ad app permission add --id $spId --api 00000002-0000-0000-c000-000000000000 --api-permissions 78c8a3c8-a07e-4b9e-af1b-b5ccab50a175=Role
if test $? -ne 0
then
    echo "api permissions couldn't be added..."
	exit
else
    echo "api permissions added..."
fi

#greant permissions if possible
az ad app permission grant --id $spId --api 00000002-0000-0000-c000-000000000000
if test $? -ne 0
then
    echo "api permissions couldn't be granted..."
	exit
else
    echo "api permissions granted..."
fi

echo ""
echo "-----"
echo "You need to manually grant api permissions for application $spName with id $spId"
