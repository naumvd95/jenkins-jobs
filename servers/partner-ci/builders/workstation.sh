#!/bin/bash -e

# activate bash xtrace for script
[[ "${DEBUG}" == "true" ]] && set -x || set +x

if [[ $ISO_FILE == *"Mirantis"* ]]; then
  fuel_release=$(echo $ISO_FILE | cut -d- -f2 | tr -d '.iso')
  export FUEL_RELEASE=$fuel_release
fi

if [[ $ISO_FILE == *"custom"* ]]; then
  export FUEL_RELEASE=90
fi

[[ "${UPDATE_MASTER}" == "true" ]] && export ISO_VERSION='mos-mu' || export ISO_VERSION='mos'
export VENV_PATH="${HOME}/${FUEL_RELEASE}-venv"
export SSH_ENDPOINT="ssh_connect.py"
main(){
  if [[ "${WS_NOREVERT}" == "false" ]]; then
    restart_ws_network
    revert_ws
    configure_nfs
  fi
}
restart_ws_network(){
  sudo vmware-networks --stop
  if sudo vmware-networks --start; then
    echo "successful networks-restart "
  else
    echo "WARNING you need to check configuration of vmnet adapters on this lab"
    exit 1
  fi
}

# waiting for ending of parallel processes
wait_ws() {
  while [ $(pgrep vmrun | wc -l) -ne 0 ] ; do sleep 5; done
}

revert_ws() {
  set +x

  cmd="vmrun -T ws-shared -h https://localhost:443/sdk \
       -u ${WORKSTATION_USERNAME} -p ${WORKSTATION_PASSWORD}"
  nodes=${WORKSTATION_NODES}
  snapshot="${WORKSTATION_SNAPSHOT}"

  # Check that vms are exist
  for node in $nodes; do
    $cmd listRegisteredVM | grep -q $node || \
      { echo "Error: $node does not exist or does not registered"; exit 1; }
  done

  # reverting in parallel
  for node in $nodes; do
    echo "Reverting $node to $snapshot"
    $cmd revertToSnapshot "[standard] $node/$node.vmx" $snapshot || \
      { echo "Error: reverting of $node has failed";  exit 1; } &
  done

  wait_ws

  # start from saved state
  for node in $nodes; do
    echo "Starting $node"
    $cmd start "[standard] $node/$node.vmx" || \
      echo "Error: $node failed to start" &
  done

  wait_ws

  [[ "${DEBUG}" == "true" ]] && set -x || set +x
}

create_ssh_endpoint(){

cat << CONTENT > $SSH_ENDPOINT
#!/usr/bin/python2
import paramiko
import sys

host = sys.argv[1]
user = sys.argv[2]
secret = sys.argv[3]
command = sys.argv[4]
port = 22

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(hostname=host, username=user, password=secret, port=port)
stdin, stdout, stderr = client.exec_command(command)
data = stdout.read() + stderr.read()
print data
client.close()
CONTENT

sudo chmod +x $SSH_ENDPOINT

}

configure_nfs(){
  set -x
  create_ssh_endpoint
  for esxi_host in $ESXI_HOSTS; do
    echo "restart services to avoid connection problems>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD './sbin/services.sh restart'
    echo "restart scfsbd-watchdog>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD '/etc/init.d/sfcbd-watchdog stop; rm -rf /var/run/sfcb/*;/etc/init.d/sfcbd-watchdog start'
    echo "esxcli network firewall set --enabled false, to avoid connection problems>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli network firewall set --enabled false'
    echo "system syslog hostname get>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system hostname get'
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   ####uncomment below rows if you want to check esxi-information
   # echo "system syslog config get>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system syslog config get'
   # echo "esxcli system module list>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system module list'
   # echo "esxcli system process list>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system process list'
   # echo "esxcli system process stats running get>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system process stats running get'
   # echo "esxcli system secpolicy domain list>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system secpolicy domain list'
   # echo "esxcli system settings advanced list>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system settings advanced list'
   # echo "esxcli system syslog config logger list>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli system syslog config logger list'
   # echo "esxcli storage core claimrule list>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
   # python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli storage core claimrule list'
   # echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    if python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'storages=$(esxcli storage nfs list | grep nfs | cut -d" " -f1); for storage in $storages; do esxcli storage nfs remove -v $storage; echo " storage $storage detected"; done';then
      echo "nfs storages have been successfully removed for $esxi_host"
    else
      echo "there is trouble with removing nfs storages from $esxi_host"; exit 1;
    fi

    for nfs_share in $NFS_SHARES; do
      if python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD "esxcli storage nfs add -H $NFS_SERVER -s /var/$nfs_share -v $nfs_share"; then
        echo "$nfs_share has been successfully connected for $esxi_host"
      else
        echo "there is trouble with $nfs_share, please check vmware configurations"; exit 1;
      fi
    done

    if python2 $SSH_ENDPOINT $esxi_host $ESXI_USER $ESXI_PASSWORD 'esxcli storage core adapter rescan --all'; then
      echo "Rescan all datastores for $esxi_host"
    else
      echo "there is trouble with rescaning datastores on $esxi_host"; exit 1;
    fi
  done

  if [[ "${NFS_CLEAN}" == "true" ]]; then
    for nfs_share in $NFS_SHARES; do
      sudo rm -rf "/var/$nfs_share/*"
    done
  fi

  [[ "${DEBUG}" == "true" ]] && set -x || set +x
}

main
