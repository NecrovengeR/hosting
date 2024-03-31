## Setup CLORE.AI hosting on HiveOS

##### System requirements:
* Minimum 32 GB disk
* 4 GB RAM (ideally 16 GB+ ram, becouse it is in most time necessary for most AI workloads)
* NVIDIA GPU (if multiple per system, they all need to be the same model)
* Nvidia driver version 515.86.01

##### Talk about the workloads:
On clore.ai marketplace users will be able to rent your system for various workloads, some workloads like 3D rendering or ai training will most of the time benefit from faster CPU and more RAM, it is not required by us, but if you will equip your system with more RAM and faster CPU you can ask higher price for it. Also you need to make sure that your system will be able to reach great stability, becouse unnecessary system downtime can cause issue to your customers.

### 1. Disable Flight Sheet on your machine

In order to use hiveos on clore.ai as hosting provider you need to unset your flight sheet (stop mining on the machine with hive), but you will still be able to mine when your machine will not be rented with background job on clore.ai

### 2. Start hive shell

Start and open hive shell


### 3. Install clore.ai hosting server

You can clone hosting repository and run the installer
```
git clone https://gitlab.com/cloreai-public/hosting
cd hosting
./install.sh
```
When everything goes smoothly you will be show INSTALLATION COMPLETE message

### 4. Install nvidia cuda toolkit
This is really important for functionality of nvidia gpu in docker on hiveos
```
apt install nvidia-cuda-toolkit
```

### 5. Reinstall nvidia driver
This version of nvidia driver was tested
```
nvidia-driver-update 515.86.01 --force
```


### 6. Login with your clore.ai token
Run this with your machine token you got from clore.ai
`/opt/clore-hosting/clore.sh --init-token <token>`


### 7 Reboot
After you succesfully connect your machine to clore.ai, you will do one final reboot and the machine should appear in your dashboard as running, you can set the price for what you will rent the machine and change it's availability

##### Final note
Don't turn off your machine when it is rented, it is computing service for someone else, you yourself whould not be happy if you will be for example training some ai model on some remote server and it just went offline, so please if you want to turn off your machine to move it somewhere else or to make maintainance, please firstly set it's availability to not available in settings and wait until the machine will not be rented.
On the same note we recommend to enable power on on AC power loss in bios, so when the power will be down and then gets back up the system will automatically start up reducing downtime

## Disable CLORE Hosting

If your machine is rented, disable renting on clore.ai website and please wait until the rental is finished, then you disable all the services in terminal and reboot the machine.

```
systemctl disable clore-hosting.service
systemctl disable docker.service
systemctl disable docker.socket
reboot
```