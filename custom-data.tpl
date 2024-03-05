#!/bin/sh

add-apt-repository ppa:deadsnakes/ppa
apt update
apt upgrade
apt install git python3.10-venv google-perftools ubuntu-drivers-common -y
ubuntu-drivers install
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.1-1_all.deb
apt install ./cuda-keyring_1.1-1_all.deb -y
apt update
apt install cuda-toolkit-12-3 -y
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
cd stable-diffusion-webui
python3.10 -m venv venv
chown -R ${user}:${user} /stable-diffusion-webui/
echo '${service}' > /etc/systemd/system/automatic1111.service
systemctl daemon-reload
systemctl enable automatic1111.service
reboot