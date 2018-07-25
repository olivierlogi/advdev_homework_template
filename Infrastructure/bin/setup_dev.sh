#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

##DAdd policy role
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
MONGODB_VERSION="3.2" #could be latest

oc new-app -f ./Infrastructure/templates/mongodb_persistent.json -n ${GUID}-parks-dev  --param MEMORY_LIMIT=$MEMORY_LIMIT \
--param NAMESPACE=${NAMESPACE} \
--param DATABASE_SERVICE_NAME=${DATABASE_SERVICE_NAME} \
--param MONGODB_USER=${MONGODB_USER} \
--param MONGODB_PASSWORD=${MONGODB_PASSWORD} \
--param MONGODB_DATABASE=${MONGODB_DATABASE} \
--param MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD} \
--param VOLUME_CAPACITY=${VOLUME_CAPACITY} \
--param MONGODB_VERSION=${MONGODB_VERSION}

#Deploy front end
oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
oc expose dc/mlbparks --port=8080 -n ${GUID}-parks-dev
oc expose svc mlbparks -n ${GUID}-parks-dev
#oc create route edge mlbparks --service=mlbparks --port=8080 -n $GUID-parks-dev

echo "Creating Nationalparks base app"
oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/nationalparks:0.0-0 --name=nationalparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev
oc expose dc/nationalparks --port=8080 -n ${GUID}-parks-dev
oc expose svc nationalparks -n ${GUID}-tasks-dev
#oc create route edge nationalparks --service=nationalparks --port=8080 -n $GUID-parks-dev

echo "Creating ParksMap base app"
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/parksmap:0.0-0 --name=parksmap --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/parksmap --remove-all -n ${GUID}-parks-dev
oc expose dc/parksmap --port=8080 -n ${GUID}-parks-dev
oc expose svc parksmap -n ${GUID}-parks-dev
#oc create route edge parksmap --service=parksmap --port=8080 -n $GUID-parks-dev



