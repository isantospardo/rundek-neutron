#!/bin/bash

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
      #HOST_LOWER=${HOST,,} #lower case hostname
      #HOST_INFO=$(echo "$NEUTRON_AGENT_LIST" | awk "/$HOST_LOWER/ && /neutron-dhcp-agent/" | awk '{print $1}')
      HOST_INFO=$(echo "$NEUTRON_AGENT_LIST" | grep neutron-dhcp-agent | awk -F" |" '{print $2}')
      if [ ! -z "$HOST_INFO" ]; then
        echo "[INFO] Trying to $RD_OPTION_STATUS neutron-dhcp-agent on $HOST_INFO..."
        if [ ${RD_OPTION_BEHAVIOUR} == 'perform' ]; then
          if [ ${RD_OPTION_STATUS} == 'down' ]; then
            #nova service-$RD_OPTION_STATUS $HOST_INFO nova-compute --reason "$REASON_MESSAGE"
            #neutron agent-update 73124323-e555-4d98-b365-0854fc28a2f5 --admin-state-down
            neutron agent-update $HOST_INFO --admin-state-$RD_OPTION_STATUS
          fi
          if [ $? -eq 0 ]; then
            echo "[INFO] neutron-dhcp-agent sucessfully "$RD_OPTION_STATUS"d on $HOST."
            ((OK++))
          else
            sleep 1 # output messages order
            echo "[ERROR] Failed to "$RD_OPTION_STATUS"d neutron-dhcp-agent on $HOST."
            ((KO++))
          fi
        else
          #echo "[DRYRUN][INFO] nova service-$RD_OPTION_STATUS $HOST_INFO neutron-dhcp-agent --reason \""$REASON_MESSAGE"\""
          echo "[DRYRUN][INFO] neutron agent-$RD_OPTION_STATUS $HOST_INFO neutron-dhcp-agent"
          ((OK++))
        fi
      else
        echo "[ERROR] Not found. Has $HOST been deleted already?"
        ((KO++))
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

