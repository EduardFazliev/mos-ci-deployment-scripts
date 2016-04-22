# This script is using python-jenkins python module,
# to get information from

#!/usr/bin/env bash

virtualenv init
. ./init/bin/activate
pip install python-jenkins

sudo rm -rf "$ISO_DIR"/*
sudo wget "$SWARM_ISO_LINK" -P "$ISO_DIR"

#####if we need some special iso#####
#sudo rm -rf /var/www/fuelweb-iso   #
#sudo wget  -P /var/www/fuelweb-iso #
#####################################