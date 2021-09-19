# .bashrc
# Omar McIver 2021.09.13
# Ansible Runner Environment

# User specific aliases and functions
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias cls='clear'
alias ll='ls -alF --color=auto'
alias ls='ls --color=auto'

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Ensure environment variables exist...
if [[ -z "$SUB" ]]; then
   echo "$(tput setaf 1)You must pass in a SUB environment variable with the Subscription name in. If using docker use '-e SUB=SubscriptionName'.$(tput sgr 0)"
   exit 1;
else
   echo "Setting up for Subscription: $SUB"
fi;

if [[ -z "$AKV" ]]; then
   echo "$(tput setaf 1)You must pass in an AKV environment variable with the Azure Key Vault name in. If using docker use '-e AKV=AzureKeyVaultName'.$(tput sgr 0)"
   exit 1;
else
   echo "Using Azure Key Vault for SSH keys: $AKV"
fi;

if [[ -z "$PSK" ]]; then
   echo "$(tput setaf 1)You must pass in a PSK environment variable with the Secret name with the Private SSH Key in. If using docker use '-e PSK=PrivateSSHKeySecretName'.$(tput sgr 0)"
   exit 1;
else
   echo "Getting the Private SSH Key from the secret named: $PSK"
fi;

if [[ -z "$PSP" ]]; then
   echo "$(tput setaf 1)You must pass in a PSP environment variable with the Secret name with the Private SSH Key Passphrase in. If using docker use '-e PSP=PrivateSSHKeyPassphraseSecretName'.$(tput sgr 0)"
   exit 1;
else
   echo "Getting the Private SSH Key Passphrase from the secret named: $PSP"
fi;

if [[ -z "$PUB" ]]; then
   echo "$(tput setaf 1)You must pass in a PUB environment variable with the Secret name with the Public SSH Key in. If using docker use '-e PUB=PublicSSHKeySecretName'.$(tput sgr 0)"
   exit 1;
else
   echo "Getting the Public SSH Key from the secret named: $PUB"
fi;

# Set SSH_HOME and ensure it exists
export SSH_HOME="/root/.ssh"
mkdir $SSH_HOME

# Setting to allow Ansible to get Azure Private IPs
export AZURE_USE_PRIVATE_IP=true

# User must authenticate with Azure to be able to access the KeyVault...
az login
az provider register -n Microsoft.KeyVault

# Download the Secrets
az account set -s "$SUB"
az keyvault secret download --vault-name $AKV --name $PSK  -f $SSH_HOME/private-ssh
az keyvault secret download --vault-name $AKV --name $PSP  -f $SSH_HOME/private-ssh-pass
az keyvault secret download --vault-name $AKV --name $PUB  -f $SSH_HOME/public-ssh

chmod 0400 $SSH_HOME/private-*
eval `ssh-agent -s`

expect <<EOD
spawn ssh-add "$SSH_HOME/private-ssh"
expect "Enter passphrase for"
send "$(cat $SSH_HOME/private-ssh-pass)\n";
sleep 1
interact
EOD
rm -rf $SSH_HOME/private-ssh-pass

clear
cd ~
./help
ssh-add -l


