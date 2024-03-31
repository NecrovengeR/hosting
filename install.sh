#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
if [ "$(uname -m)" != "x86_64" ]
  then echo "Your system type needs to be x86_64"
  exit
fi
if [ "$(awk -F= '/^NAME/{print $2}' /etc/os-release)" != '"Ubuntu"' ]
  then echo "Only ubuntu is supported distro"
  exit
fi
WORKARG="false"
for arg in "$@"; do
  if [ "$arg" = "-nq" ]; then
    WORKARG="true"
  fi
done
export DEBIAN_FRONTEND=noninteractive
AUTH_FILE=/opt/clore-hosting/client/auth
if [ -x "$(command -v docker)" ]; then
  apt update -y
  if test -f "$AUTH_FILE"; then
    echo '...'
  else
    apt upgrade -y
  fi
else
    apt update -y
    apt install ca-certificates curl gnupg lsb-release tar speedtest-cli ufw -y
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    chmod a+r /etc/apt/keyrings/docker.gpg
    apt update -y
    apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
fi
if [ -x "$(command -v docker)" ]; then
  docker network create   --driver=bridge   --subnet=172.18.0.0/16   --ip-range=172.18.0.0/16   --gateway=172.18.0.1   clore-br0 &>/dev/null
  docker pull cloreai/ubuntu20.04-jupyter
  docker pull cloreai/proxy:0.2
else
  echo "docker instalation failure" && exit
fi
kernel_version=$(uname -r)
hive_str='hiveos'
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt update
apt install -y nvidia-docker2
apt remove nodejs -y
#curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
#apt install nodejs -y
if [ "$WORKARG" = "true" ]; then
  if test -f "$AUTH_FILE"; then
    echo ''
  else
    mkdir /opt/clore-hosting/ &>/dev/null
    echo '{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}' | sudo tee /etc/docker/daemon.json > /dev/null
    systemctl restart docker.service
  fi
elif test -f "$AUTH_FILE"; then
    read -p "You have already installed clore hosting software, do you want to upgrade to current version? (yes/no) " yn

    case $yn in 
    	yes ) echo ok, we will proceed;;
      y ) echo ok, we will proceed;;
    	no ) echo exiting...;
    		exit;;
      n ) echo exiting...;
    		exit;;
    	* ) echo invalid response;
    		exit 1;;
    esac
else
  mkdir /opt/clore-hosting/ &>/dev/null
  echo '{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}' | sudo tee /etc/docker/daemon.json > /dev/null
    systemctl restart docker.service
fi
mkdir /opt/clore-hosting/startup_scripts &>/dev/null
mkdir /opt/clore-hosting/wireguard &>/dev/null
mkdir /opt/clore-hosting/wireguard/configs &>/dev/null
mkdir /opt/clore-hosting/client &>/dev/null
tar -xvf clore-hosting.tar -C /opt/clore-hosting/client &>/dev/null
tar -xvf node-v16.18.1-linux-x64.tar.xz -C /opt/clore-hosting &>/dev/null
rm -rf /opt/clore-hosting/client/node_modules/ &>/dev/null
if [[ "$kernel_version" == *"$hive_str"* ]]; then
  docker pull cloreai/clore-hive-wireguard
  apt remove wireguard-dkms -y &>/dev/null
  dpkg -i /opt/clore-hosting/client/wireguard-dkms_1.0.20200623-hiveos-5.4.0.deb
fi
rm /opt/clore-hosting/client/wireguard-dkms_1.0.20200623-hiveos-5.4.0.deb &>/dev/null
rm /opt/clore-hosting/service.sh &>/dev/null
rm /opt/clore-hosting/clore.sh &>/dev/null
rm /etc/systemd/system/clore-hosting.service &>/dev/null
tee -a /opt/clore-hosting/service.sh > /dev/null <<EOT
#!/bin/bash
CLIENT_DIR=/opt/clore-hosting/client
NODE=/opt/clore-hosting/node-v16.18.1-linux-x64/bin/node
cd \$CLIENT_DIR
while true
do
if test -f "\$CLIENT_DIR/auth"; then
    \$NODE index.js -main true
fi
sleep 1
done
EOT
tee -a /opt/clore-hosting/clore.sh > /dev/null <<EOT
#!/bin/bash
cd /opt/clore-hosting/client
/opt/clore-hosting/node-v16.18.1-linux-x64/bin/node index.js "\$@"
EOT
tee -a /etc/systemd/system/clore-hosting.service > /dev/null <<EOT
[Unit]
Description=CLORE.AI Hosting service

[Service]
User=root
ExecStart=/opt/clore-hosting/service.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOT
chmod +x /opt/clore-hosting/service.sh
chmod +x /opt/clore-hosting/clore.sh
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
systemctl enable clore-hosting.service
systemctl enable docker.service
systemctl enable docker.socket
export PATH="/opt/clore-hosting/node-v16.18.1-linux-x64/bin/:$PATH"
if test -f "$AUTH_FILE"; then
  cd /opt/clore-hosting/client
#  npm update
  /opt/clore-hosting/node-v16.18.1-linux-x64/bin/node /opt/clore-hosting/node-v16.18.1-linux-x64/bin/npm update
  systemctl restart clore-hosting.service
  echo "Your machine is updated to latest hosting software (v4.0)"
else
  cd /opt/clore-hosting/client
#  npm update
  /opt/clore-hosting/node-v16.18.1-linux-x64/bin/node /opt/clore-hosting/node-v16.18.1-linux-x64/bin/npm update
  echo "------INSTALATION COMPLETE------"
  echo "For connection to clore ai use /opt/clore-hosting/clore.sh --init-token <token>"
  echo "and then reboot"
fi