#!/usr/bin/env bash

IP=127.0.0.1

if [ -d /vagrant ]; then
  LOG="/vagrant/logs/vault_${HOSTNAME}.log"
else
  LOG="vault.log"
fi

which vault &>/dev/null || {
  pushd /usr/local/bin
  [ -f vault_0.10.4_linux_amd64.zip ] || {
    sudo wget https://releases.hashicorp.com/vault/0.10.4/vault_0.10.4_linux_amd64.zip
  }
  sudo unzip vault_0.10.4_linux_amd64.zip
  sudo chmod +x vault
  popd
}


#lets kill past instance
sudo killall vault &>/dev/null

#lets delete old consul storage
sudo consul kv delete -recurse vault

#delete old token if present
[ -f /root/.vault-token ] && sudo rm /root/.vault-token

#start vault
sudo /usr/local/bin/vault server  -dev -dev-listen-address=${IP}:8200  &> ${LOG} &
echo vault started
sleep 3 

echo "vault token:"
cat /root/.vault-token
echo -e "\nvault token is on /root/.vault-token"
  
# enable secret KV version 1
sudo VAULT_ADDR="http://${IP}:8200" vault secrets enable -version=1 kv
  
# setup .bash_profile
grep VAULT_TOKEN ~/.bash_profile || {
  echo export VAULT_TOKEN=\`cat /root/.vault-token\` | sudo tee -a ~/.bash_profile
}

grep VAULT_ADDR ~/.bash_profile || {
  echo export VAULT_ADDR=http://${IP}:8200 | sudo tee -a ~/.bash_profile
}
