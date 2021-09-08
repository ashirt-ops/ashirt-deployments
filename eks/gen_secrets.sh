#!/bin/sh
echo 'Input DSN string'
read dsn_string
echo 'Input okta secret'
read okta_secret
kubectl create secret generic dsn-private --from-literal=dsn=$dsn_string --namespace=ashirt-frontend 
kubectl create secret generic dsn-public-api --from-literal=dsn-public=$dsn_string --namespace=ashirt-public
kubectl create secret generic csrf-auth-key --from-literal=csrf-auth-key="`head -c 48 /dev/urandom`" --namespace=ashirt-frontend
kubectl create secret generic session-store-key --from-literal=session-store-key="`head -c 48 /dev/urandom`" --namespace=ashirt-frontend
kubectl create secret generic auth-okta-client-secret --from-literal=auth-okta-client-secret=$okta_secret --namespace=ashirt-frontend
