OK=0
KO=0

# source the openrc 
source $RD_OPTION_OPENRC

#only execute this once since it takes really long
NEUTRON_AGENT_LIST="$(neutron agent-list)"

if [[ ${RD_OPTION_REFERENCE} == "" ]]; then
  REASON_MESSAGE="${RD_OPTION_STATUS^}d by $RD_JOB_USER_NAME using Rundeck ($RD_JOB_EXECID)"
else
  REASON_MESSAGE="[$RD_OPTION_REFERENCE] ${RD_OPTION_STATUS^}d by $RD_JOB_USER_NAME using Rundeck ($RD_JOB_EXECID)"
fi

if [ ! -z "$NEUTRON_AGENT_LIST" ]; then
  for HOST in $RD_OPTION_HOSTS
    do
      # Gettting cell info
      HOST_INFO=$(echo "$NEUTRON_AGENT_LIST" | grep neutron-linuxbridge-agent | grep $HOST | awk -F" |" '{print $2}')
      if [ ! -z "$HOST_INFO" ]; then
        echo "[INFO] Trying to $RD_OPTION_STATUS neutron-linuxbridge-agent on $HOST_INFO..."
        if [ ${RD_OPTION_BEHAVIOUR} == 'perform' ]; then
          if [ ${RD_OPTION_STATUS} == 'disable' ]; then
            neutron agent-update $HOST_INFO --admin-state-down
          else
            neutron agent-update $HOST_INFO --admin-state-up
          fi
          if [ $? -eq 0 ]; then
            echo "[INFO] neutron-linuxbridge-agent sucessfully "$RD_OPTION_STATUS"d on $HOST."
            ((OK++))
          else
            sleep 1 # output messages order
            echo "[ERROR] Failed to "$RD_OPTION_STATUS"d neutron-linuxbridge-agent on $HOST."
            ((KO++))
          fi
        else
          echo "[DRYRUN][INFO] neutron agent-$RD_OPTION_STATUS $HOST_INFO neutron-linuxbridge-agent"
          ((OK++))
        fi
      else
        echo "[WARNING] Not found. $HOST is not a neutron host"
        ((OK++))
      fi
      echo ""
    done

else
  echo "[ERROR] Something went wrong executing neutron agent-list. Please check with the OpenStack admins."
  exit 2
fi

#Summary
printf "\n:TOTAL HOSTS:SUCCESS:ERROR\n[${RD_OPTION_BEHAVIOUR^^}] SUMMARY NEUTRON ${RD_OPTION_STATUS^^}:     $((OK + KO)):   $OK:  $KO" | column  -t -s ':'
echo ""
