#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production project"


# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student

echo "Setting up user permissions in project ${GUID}-parks-prod"
oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-prod
oc policy add-role-to-user edit --serviceaccount=default -n ${GUID}-parks-prod
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod


echo "Setting up MongoDB statefulset"

# Config MongoDB configmap
oc create configmap parksdb-conf -n ${GUID}-parks-prod \
       --from-literal=DB_REPLICASET=rs0 \
       --from-literal=DB_HOST=mongodb \
       --from-literal=DB_PORT=27017 \
       --from-literal=DB_USERNAME=mongodb \
       --from-literal=DB_PASSWORD=mongodb \
       --from-literal=DB_NAME=parks

# Setup replicated MongoDB from templates + configure it via ConfigMap
oc new-app -f ./Infrastructure/templates/mongodb_statefulset.yaml -p MONGO_CONFIGMAP_NAME=parksdb-conf -n ${GUID}-parks-prod


echo "Setting up MLBPark blue"
oc new-app ${GUID}-parks-dev/mlbparks:latest --name=mlbparks-blue  --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

echo "Setting up MLBPark green"
oc new-app ${GUID}-parks-dev/mlbparks:latest --name=mlbparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

oc patch dc/mlbparks-blue  --patch='{ "spec": { "strategy": { "type": "Recreate" }}}' -n ${GUID}-parks-prod
oc patch dc/mlbparks-green --patch='{ "spec": { "strategy": { "type": "Recreate" }}}' -n ${GUID}-parks-prod

oc set triggers dc/mlbparks-blue  --remove-all -n ${GUID}-parks-prod
oc set triggers dc/mlbparks-green --remove-all -n ${GUID}-parks-prod

echo "Create Configmap MLBpark"
oc create configmap mlbparks-config --from-literal="APPNAME=MLB Parks (Green)" \
    --from-literal="DB_HOST=mongodb" \
    --from-literal="DB_PORT=27017" \
    --from-literal="DB_USERNAME=mongodb" \
    --from-literal="DB_PASSWORD=mongodb" \
    --from-literal="DB_NAME=parks" \
    --from-literal="DB_REPLICASET=rs0" \
    -n ${GUID}-parks-prod

oc set env dc/mlbparks-green --from=configmap/mlbparks-config -n ${GUID}-parks-prod

oc expose dc/mlbparks-green --port 8080 -n ${GUID}-parks-prod

oc expose svc/mlbparks-green --name mlbparks -n ${GUID}-parks-prod


echo "Setting up Nationalparks blue"
oc new-app ${GUID}-parks-dev/nationalparks:latest --name=nationalparks-blue  --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

echo "Setting up Nationalparks green"
oc new-app ${GUID}-parks-dev/nationalparks:latest --name=nationalparks-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

oc patch dc/nationalparks-blue  --patch='{ "spec": { "strategy": { "type": "Recreate" }}}' -n ${GUID}-parks-prod
oc patch dc/nationalparks-green --patch='{ "spec": { "strategy": { "type": "Recreate" }}}' -n ${GUID}-parks-prod

oc set triggers dc/nationalparks-blue  --remove-all -n ${GUID}-parks-prod
oc set triggers dc/nationalparks-green --remove-all -n ${GUID}-parks-prod

echo "Create config map national park"
oc create configmap nationalparks-config --from-literal="APPNAME=National Parks (Green)" \
    --from-literal="DB_HOST=mongodb" \
    --from-literal="DB_PORT=27017" \
    --from-literal="DB_USERNAME=mongodb" \
    --from-literal="DB_PASSWORD=mongodb" \
    --from-literal="DB_NAME=parks" \
    --from-literal="DB_REPLICASET=rs0" \
    -n ${GUID}-parks-prod

oc set env dc/nationalparks-green --from=configmap/nationalparks-config -n ${GUID}-parks-prod

oc expose dc/nationalparks-green --port 8080 -n ${GUID}-parks-prod

oc expose svc/nationalparks-green --name nationalparks -n ${GUID}-parks-prod


echo "Setting up Parksmap blue"
oc new-app ${GUID}-parks-dev/parksmap:latest --name=parksmap-blue  --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
echo "Setting up Parksmap green"
oc new-app ${GUID}-parks-dev/parksmap:latest --name=parksmap-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod

oc patch dc/parksmap-blue  --patch='{ "spec": { "strategy": { "type": "Recreate" }}}' -n ${GUID}-parks-prod
oc patch dc/parksmap-green --patch='{ "spec": { "strategy": { "type": "Recreate" }}}' -n ${GUID}-parks-prod

oc set triggers dc/parksmap-blue  --remove-all -n ${GUID}-parks-prod
oc set triggers dc/parksmap-green --remove-all -n ${GUID}-parks-prod

echo "Create config map Parksmap"
oc create configmap parksmap-config --from-literal="APPNAME=ParksMap (Green)" -n ${GUID}-parks-prod

oc set env dc/parksmap-green --from=configmap/parksmap-config -n ${GUID}-parks-prod

oc expose dc/parksmap-green --port 8080 -n ${GUID}-parks-prod

oc expose svc/parksmap-green --name parksmap -n ${GUID}-parks-prod