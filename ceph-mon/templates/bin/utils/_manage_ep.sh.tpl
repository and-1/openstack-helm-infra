#!/bin/bash
action=$1
shift
svc_list=$*
source /tmp/mon.env
for svc in $svc_list;do
  ep=($(kubectl get ep $svc --namespace=${NAMESPACE} -o jsonpath='{..ip}'))
  if [[ "xadd" == "x${action}" ]];then
    if ! $(echo ${ep[*]} | grep -q "$MON_IP");then
      if (( ${#ep[*]} > 0 ));then
        kubectl patch ep $svc --namespace=${NAMESPACE} --type json -p '[{"op": "add", "path": "/subsets/0/addresses/-", "value":{"ip":"'$MON_IP'"}}]' &>/dev/null || exit 1
      else
        kubectl patch ep $svc --namespace=${NAMESPACE} --type merge -p '{"subsets":[{"addresses": [{"ip":"'$MON_IP'"}],"ports":[{"port": '$MON_PORT', "protocol":"TCP"}]}]}' &>/dev/null || exit 1
      fi
    fi
  fi
  if [[ "xdel" == "x${action}" ]];then
    if $(echo ${ep[*]} | grep -q "$MON_IP");then
      if (( ${#ep[*]} > 1 ));then
        for i in ${!ep[*]};do
          if [[ "$MON_IP" == "${ep[$i]}" ]];then
            kubectl patch ep $svc --namespace=${NAMESPACE} --type json -p '[{"op": "remove", "path": "/subsets/0/addresses/'$i'"}]' &>/dev/null
            break
          fi
        done
      else
        kubectl patch ep $svc --namespace=${NAMESPACE} --type json -p '[{"op": "remove", "path": "/subsets"}]' &>/dev/null
      fi
    fi
  fi
done

