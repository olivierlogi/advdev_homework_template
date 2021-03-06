#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

##Add policy role
oc policy add-role-to-user view --serviceaccount=default -n $GUID-parks-dev
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-dev


##Deploy mongo
echo "Deploy Mongo" 
MEMORY_LIMIT="512Mi"
NAMESPACE="openshift"
DATABASE_SERVICE_NAME="mongodb"
MONGODB_USER="mongodb"
MONGODB_PASSWORD="mongodb"
MONGODB_DATABASE="parks"
MONGODB_ADMIN_PASSWORD="mongodb"
VOLUME_CAPACITY="1Gi"
MONGODB_VERSION="3.2"

oc new-app -f ./Infrastructure/templates/mongodb_persistent.json -n ${GUID}-parks-dev  --param MEMORY_LIMIT=$MEMORY_LIMIT \
--param NAMESPACE=${NAMESPACE} \
--param DATABASE_SERVICE_NAME=${DATABASE_SERVICE_NAME} \
--param MONGODB_USER=${MONGODB_USER} \
--param MONGODB_PASSWORD=${MONGODB_PASSWORD} \
--param MONGODB_DATABASE=${MONGODB_DATABASE} \
--param MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD} \
--param VOLUME_CAPACITY=${VOLUME_CAPACITY} \
--param MONGODB_VERSION=${MONGODB_VERSION}



#Deploy MLBPark Backend service
echo "Creating MLBPark base app"

oc create configmap mlbparks-config --from-literal="APPNAME=MLB Parks (Dev)" \
    --from-literal="DB_HOST=mongodb" \
    --from-literal="DB_PORT=27017" \
    --from-literal="DB_USERNAME=mongodb" \
    --from-literal="DB_PASSWORD=mongodb" \
    --from-literal="DB_NAME=parks" \
    -n "${GUID}-parks-dev"

oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set env dc/mlbparks --from=configmap/mlbparks-config -n ${GUID}-parks-dev
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
oc expose dc/mlbparks --port=8080 -n ${GUID}-parks-dev
oc expose svc mlbparks -n ${GUID}-parks-dev


#Deploy Nationalparks Backend service
echo "Creating Nationalparks base app"


oc create configmap nationalparks-config --from-literal="APPNAME=National Parks (Dev)" \
    --from-literal="DB_HOST=mongodb" \
    --from-literal="DB_PORT=27017" \
    --from-literal="DB_USERNAME=mongodb" \
    --from-literal="DB_PASSWORD=mongodb" \
    --from-literal="DB_NAME=parks" \
    -n ${GUID}-parks-dev

oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/nationalparks:0.0-0 --name=nationalparks -l type=parksmap-backend --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

oc set env dc/nationalparks --from configmap/nationalparks-config -n "${GUID}-parks-dev"

oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev
oc expose dc nationalparks --port=8080 -n ${GUID}-parks-dev
oc expose svc nationalparks --labels="type=parksmap-backend" -n ${GUID}-parks-dev

oc set probe dc/nationalparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/nationalparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

#Deploy parksmap frontend app
echo "Creating ParksMap base app"
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parksmap:0.0-0 --name=parksmap --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set env dc/parksmap -e "APPNAME=ParksMap (Dev)" -n "${GUID}-parks-dev"
oc set triggers dc/parksmap --remove-all -n ${GUID}-parks-dev
oc expose dc/parksmap --port=8080 -n ${GUID}-parks-dev
oc expose svc parksmap -n ${GUID}-parks-dev




