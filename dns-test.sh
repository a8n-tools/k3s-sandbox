#!/usr/bin/env bash

export DOMAIN=acme-staging-v02.api.letsencrypt.org
echo "=> Start DNS resolve test"
kubectl get pods -l name=dnstest --no-headers -o custom-columns=NAME:.metadata.name,HOSTIP:.status.hostIP | while read pod host
do
   	kubectl exec $pod -- /bin/sh -c "nslookup $DOMAIN > /dev/null 2>&1"
   	RC=$?
   	if [ $RC -ne 0 ]
   	then
		echo $host cannot resolve $DOMAIN
	fi
done
echo "=> End DNS resolve test"
