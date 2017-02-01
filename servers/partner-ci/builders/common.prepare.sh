#!/bin/bash -e

git log  --pretty=oneline | head
IS_NESTED=$(cat /sys/module/kvm_intel/parameters/nested)
IS_IGNORE_MSRS=$(cat /sys/module/kvm/parameters/ignore_msrs)
IS_EPT=$(cat /sys/module/kvm_intel/parameters/ept)
echo 'nested option enable = '$IS_NESTED
echo 'ignore msrs option enable = '$IS_IGNORE_MSRS
echo 'ept option enable = '$IS_EPT

if [[ $IS_NESTED == *"Y"* ]] && [[ $IS_IGNORE_MSRS == *"Y"* ]] && [[ $IS_EPT == *"Y"* ]]; then
  echo 'nested kvm virtuallization succesfully enabled '
else
  echo 'nested kvm virtualization disabled or works incorrect, please check configuration'
fi

# activate bash xtrace for script
[[ "${DEBUG}" == "true" ]] && set -x || set +x

[ -z $ISO_FILE ] && (echo "ISO_FILE variable is empty"; exit 1)


if [[ $ISO_FILE == *"Mirantis"* ]]; then
  export FUEL_RELEASE=$(echo $ISO_FILE | cut -d- -f2 | tr -d '.iso')
fi
if [[ $ISO_FILE == *"custom"* ]]; then
  export FUEL_RELEASE=90
fi

if [[ "${UPDATE_MASTER}" == "true" ]] && [[ ${FUEL_RELEASE} != *"80"* ]]; then
  [ ${SNAPSHOTS_ID} ] && export SNAPSHOTS_ID=${SNAPSHOTS_ID} || export SNAPSHOTS_ID=${CUSTOM_VERSION:10}
else
  export SNAPSHOTS_ID="released"
fi

[ -z "${SNAPSHOTS_ID}" ] && { echo SNAPSHOTS_ID is empty; exit 1; }
#remove old logs and test data
[ -f nosetest.xml ] && rm -f nosetests.xml
[ -d logs ] && rm -rf logs/* || mkdir logs

export ISO_PATH="${ISO_STORAGE}/${ISO_FILE}"
[ ! -f $ISO_PATH ] && { echo "The $ISO_PATH isn't exist"; exit 1; }

if [[ $ISO_FILE == *"Mirantis"* ]]; then
  export FUEL_RELEASE=$(echo $ISO_FILE | cut -d- -f2 | tr -d '.iso')
fi

if [[ $ISO_FILE == *"custom"* ]]; then
  export FUEL_RELEASE=90
fi

export REQUIRED_FREE_SPACE=200

export ENV_NAME="${ENV_PREFIX}.${SNAPSHOTS_ID}"
[ -z ${VENV_PATH} ] && { export VENV_PATH="${HOME}/${FUEL_RELEASE}-venv"; }

## For plugins we should get a valid version of requrements of python-venv
## This requirements could be got from the github repo
## but for each branch of a plugin we should map specific branch of the fuel-qa repo
## the fuel-qa branch is determined by a fuel-iso name.

case "${FUEL_RELEASE}" in
  *10* ) export REQS_BRANCH="stable/newton" ;;
  *90* ) export REQS_BRANCH="stable/mitaka" ;;
  *80* ) export REQS_BRANCH="stable/8.0"    ;;
  *70* ) export REQS_BRANCH="stable/7.0"    ;;
  *61* ) export REQS_BRANCH="stable/6.1"    ;;
   *   ) export REQS_BRANCH="master"
esac

REQS_PATH="https://raw.githubusercontent.com/openstack/fuel-qa/${REQS_BRANCH}/fuelweb_test/requirements.txt"

REQS_PATH_DEVOPS="https://raw.githubusercontent.com/openstack/fuel-qa/${REQS_BRANCH}/fuelweb_test/requirements-devops-source.txt"

###############################################################################

## We have limited disk resources, so before run of system tests a lab
## may have many deployed and runned envs, those may cause errors during test

## Recreate all an virtual env
function recreate_venv {
  [ -d $VENV_PATH ] && rm -rf ${VENV_PATH} || echo "The directory ${VENV_PATH} doesn't exist"
  virtualenv --clear "${VENV_PATH}"
}

function get_venv_requirements {
  rm -f requirements.*
  wget --no-check-certificate -O requirements.txt $REQS_PATH
  export REQS_PATH="$(pwd)/requirements.txt"
  wget --no-check-certificate -O requirements-devops-source.txt $REQS_PATH_DEVOPS
  export REQS_PATH_DEVOPS="$(pwd)/requirements-devops-source.txt"
  export SPEC_REQS_PATH="${WORKSPACE}/plugin_test/requirement.txt"
  sed -i 's/2.9.23/release\/2.9/g' $REQS_PATH_DEVOPS
  # additional libraries associated with vcenter-control wrapper
  echo -e "pyvim\npyvmomi" >> $REQS_PATH
}

function prepare_venv {
    source "${VENV_PATH}/bin/activate"
    easy_install -U pip
    export redirected_output='pip.properties'
    pip install -r "${REQS_PATH}" --upgrade > $redirected_output
    pip install -r "${REQS_PATH_DEVOPS}" --upgrade > $redirected_output
    [ -e $SPEC_REQS_PATH ] && pip install -r "${SPEC_REQS_PATH}" --upgrade > $redirected_output
    django-admin.py syncdb --settings=devops.settings --noinput
    django-admin.py migrate devops --settings=devops.settings --noinput
    deactivate
}

function smart_erase {
  env=$1

  virsh list --all --name | grep $env && vms=$(virsh list --all --name | grep $env) || echo "there is no vms"

  virsh net-list | tail -n +3 | cut -d' ' -f2-2 | grep $env && networks=$(virsh net-list | tail -n +3 | cut -d' ' -f2-2 | grep $env) \
  || echo "there is no networks"
  if [ ! -z "$networks" ]; then
    for net in $networks; do
      if virsh net-destroy $net; then
        echo "network destroyed succesfully"
      else
        ref=$?
        echo "there are some troubles with virt-networks stack, please check ( exit code = $ref )"
      fi
      if virsh net-undefine $net; then
        echo "network destroyed succesfully"
      else
        ref=$?
        echo "there are some troubles with virt-networks stack, please check ( exit code = $ref )"
      fi
    done
  fi
  for vm in $vms; do
    domstat=$(virsh domstate $vm)
    if [[ $domstat != *"shut"* ]]; then
      if virsh destroy $vm; then
        echo "domain destroyed succesfully"
        virsh undefine --remove-all-storage --snapshots-metadata $vm
      else
        ref=$?
        echo "there are some troubles with virt stack, restart services and recheck"
	sudo service libvirt-bin restart
        if virsh destroy $vm; then
          echo "domain destroyed succesfully"
          virsh undefine --remove-all-storage --snapshots-metadata $vm
        else
          ref=$?
          echo "there are some troubles with virt stack, please check it manually "
        fi
      fi
    else
      virsh undefine --remove-all-storage --snapshots-metadata $vm
    fi
  done
  dos.py sync
}

#################################################################
## Gets dospy environments
## with prefix the function returns all env except envs like prefix
function dospy_list {
  prefix=$1
  dos.py sync
  [ -z $prefix ] && \
    dos.py list | tail -n +3 || \
    dos.py list | tail -n +3 | grep $prefix
}

##################################################################
wait_ws() {
  while [ $(pgrep vmrun | wc -l) -ne 0 ] ; do sleep 5; done
}

if [[ "${RECREATE_VENV}" == "true" ]]; then
  recreate_venv
  get_venv_requirements
  [ -d $VENV_PATH ] && prepare_venv || { echo "$VENV_PATH doesn't exist $VENV_PATH will be recreated"; recreate_venv; }
fi

source "$VENV_PATH/bin/activate"

[ -z $VIRTUAL_ENV ] && { echo "VIRTUAL_ENV is empty"; exit 1; }

set +x

cmd="vmrun -T ws-shared -h https://localhost:443/sdk \
-u ${WORKSTATION_USERNAME} -p ${WORKSTATION_PASSWORD}"
nodes=${WORKSTATION_NODES}
export snapshot="${WORKSTATION_SNAPSHOT}"

# start from saved state
for node in $nodes; do
  if [[ $(pgrep vmrun | wc -l) -ne 0 ]]; then
    echo "Stopping $node"
    $cmd stop "[standard] $node/$node.vmx" || \
      echo "Error: $node failed to stop" &
  fi
done
wait_ws
set -x

if [[ "${FORCE_REUSE}" == "false" ]]; then
  if [[ "${FORCE_ERASE}" == "true" ]]; then
    for env in $(dospy_list); do
      smart_erase $env
    done
  else
    # determine free space before run the cleaner
    free_space=$(df -h | grep '/$' | awk '{print $4}' | tr -d G)

    if (( free_space < REQUIRED_FREE_SPACE )); then
      for env in $(dospy_list $ENV_NAME); do
        if [[ $env  != *"released"* ]]; then
          smart_erase $env
        fi
      done
    fi
  fi
  ###############################################################
  ##############possibility of reusing envs######################
  current_date=$(date +'%Y-%m-%d')
  mod_current_date=$(date -d $current_date +"%Y%m%d")
  for env in $(dospy_list $ENV_NAME); do
    if [[ "$env"  == "$ENV_NAME" ]] && [[ "$env"  != *"released"* ]]; then
      if [[ "$env"  != *"released"* ]]; then
        if dos.py snapshot-list $env | grep "empty"; then
          snap_date=$(dos.py snapshot-list $env | grep empty | awk '{print $2}')
          mod_snap_date=$(date -d $snap_date +"%Y%m%d")
          if [[ $mod_snap_date -eq $mod_current_date ]]; then
            echo "$env is suitable for test, it will be reused"
            USEFUL_ENV=$env
          else
            echo "$env is not suitable for test, it will be erased"
            smart_erase $env
          fi
        else
          echo "there is no date-metadata, $env will be erased"
          smart_erase $env
        fi
      else
        echo "there're no snapshots to reuse"
      fi
    fi
  done

  for env in $(dospy_list); do
    [[ "$env"  != "$USEFUL_ENV" ]] && [[ $env  != *"released"* ]] && smart_erase $env
  done
fi
##########################################################
[[ "${DEBUG}" == "true" ]] && virsh list --all
sudo cp /var/log/libvirt/libvirtd.log ${WORKSPACE}/libvirtd_before_test.log
sudo chown jenkins:jenkins ${WORKSPACE}/libvirtd_before_test.log



