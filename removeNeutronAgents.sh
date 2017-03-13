OK=0
KO=0

# source the openrc 
source $RD_OPTION_OPENRC

#only execute this once since it takes really long
NEUTRON_AGENT_LIST="$(neutron agent-list)"

echo "[INFO] Trying to remove the following linuxbrige-agent from Neutron: $RD_OPTION_HOSTS..."

if [ ! -z "$NEUTRON_AGENT_LIST" ]; then
  for HOST in $RD_OPTION_HOSTS
    do
      # Gettting cell info
      HOST_INFO=$(echo "$NEUTRON_AGENT_LIST" | grep neutron-linuxbridge-agent | grep $HOST | awk -F" |" '{print $2}')

      if [ ! -z "$HOST_INFO" ]; then
        echo "[INFO] Removing linuxbridge-agent $HOST from Neutron..."
        if [ ${RD_OPTION_BEHAVIOUR} == 'perform' ]; then
          echo "[INFO] Executing: neutron agent-delete $HOST_INFO"
          neutron agent-delete "$HOST_INFO"
          if [ $? -eq 0 ]; then
            echo "[INFO] $HOST sucessfully deleted"
            ((OK++))
          else
            sleep 1 #log messages sync
            echo "[ERROR] Failed to delete linuxbrige-agent from Neutron"
            ((KO++))
          fi
        else
          echo "[DRYRUN][INFO] Would've removed linuxbrige-agent $HOST from Neutron"
          ((OK++))
        fi
      else
        echo "[WARNING] Not found. $HOST is not a neutron host?"
        ((OK++))
      fi
      echo ""
    done

else
  echo "[ERROR] Something went wrong executing neutron agent-list. Please check with the OpenStack admins."
  exit 2
fi

#Summary
printf "\n:TOTAL HOSTS:SUCCESS:ERROR\n[${RD_OPTION_BEHAVIOUR^^}] SUMMARY SERVICE DELETE:     $(($OK + $KO)):   $OK:  $KO" | column  -t -s ':'
echo ""
