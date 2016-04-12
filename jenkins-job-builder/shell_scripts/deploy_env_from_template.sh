##########################
#### Functions block #####
##########################
patch_fuel_qa(){
    # Check and apply patch to fuel_qa
    set +e
    file_name=$1
    patch_file=../fuel_qa_patches/$file_name
    echo "Check for patch $file_name"
    git apply --check $patch_file 2> /dev/null
    if [ $? -eq 0 ]; then
    echo "Applying patch $file_name"
    git apply $patch_file
    fi
    set -e
}
###############################
##### Functions block end #####
###############################

##### Install required components #####
sudo apt-get install python-virtualenv || true

##### Define standart parameters #####
ISO_NAME=`ls "$ISO_DIR"`
ENV_NAME=MOS_CI_"$ISO_NAME"
ISO_ID=`echo "$ISO_NAME" | cut -f3 -d-`

V_ENV_DIR=venv

export ENV_NAME="MOS_CI_$SNAPSHOT_NAME"
export USE_KVM="TRUE"

echo "Env name:         ${ENV_NAME}"
echo "Snapshot name:    ${SNAPSHOT_NAME}"
echo "Fuel QA branch:   ${FUEL_QA_VER}"
echo ""

##### Creating virtualenv for fuel-qa #####
virtualenv --no-site-packages ${V_ENV_DIR}

. ${V_ENV_DIR}/bin/activate
pip install -U pip

git clone -b "${FUEL_QA_VER}" https://github.com/openstack/fuel-qa

pip install -r fuel-qa/fuelweb_test/requirements.txt --upgrade
# https://bugs.launchpad.net/oslo.service/+bug/1525992 workaround
pip uninstall -y python-neutronclient
pip install 'python-neutronclient<4.0.0'

# django-admin.py syncdb --settings=devops.settings
# django-admin.py migrate devops --settings=devops.settings

cp __init__.py fuel-qa/system_test/
cp deploy_env.py fuel-qa/system_test/tests/
# cp mos_tests.yaml fuel-qa/system_test/tests_templates/devops_configs/
cp ${FUELQA_TEMPLATE_NAME} fuel-qa/system_test/tests_templates/tests_configs

cd fuel-qa


########################################
##### Applying patches for fuel-qa #####
########################################

if [ ${IRONIC_ENABLE} == 'true' ]; then
    patch_fuel_qa ironic.patch
fi

if [[ ${SNAPSHOT_NAME} == *"DVR"*' ]] || \
   [[ ${SNAPSHOT_NAME} == *"L2_POP"*' ]] || \
   [[ ${SNAPSHOT_NAME} == *"L3_HA"*' ]]; then
    patch_fuel_qa DVR_L2_pop_HA.patch
fi

if [[ ${INTERFACE_MODEL} == 'virtio' ]]; then
    # Virtio network interfaces have names eth0..eth5
    # (rather than default names - enp0s3..enp0s8)
    patch_fuel_qa virtio.patch
    for i in {0..5}; do
        export IFACE_$i=eth$i
    done
fi

if [[ ${NOVA_QUOTAS_ENABLED} == 'TRUE' ]]; then
    patch_fuel_qa nova_quotas.patch
fi
