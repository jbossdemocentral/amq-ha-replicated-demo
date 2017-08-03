#!/bin/sh
# Note everything is installed into the target directory, so now that we
# have an easily repeatable installation of your project, you can throw away
# the target directory at any time and run your init.sh to start over!
#

DEMO="JBoss AMQ 7 Replicated HA Demo"
AUTHORS="Hugo Guerrero"
PROJECT="git@github.com:jbossdemocentral/amq-ha-replicated-demo.git"
PRODUCT="Red Hat JBoss AMQ Broker"
PRODUCT_HOME=./target/amq-broker-7.0.1
SRC_DIR=./installs
SUPPORT_DIR=./support
PRJ_DIR=./projects
INSTALLER=amq-broker-7.0.1-bin.zip
VERSION=7.0.1

AMQ_SERVER_CONF=$PRODUCT_HOME/etc
AMQ_SERVER_BIN=$PRODUCT_HOME/bin
AMQ_INSTANCES=$PRODUCT_HOME/instances
AMQ_MASTER=replicatedMaster
AMQ_SLAVE=replicatedSlave
AMQ_MASTER_HOME=$AMQ_INSTANCES/$AMQ_MASTER
AMQ_SLAVE_HOME=$AMQ_INSTANCES/$AMQ_SLAVE

# wipe screen.
clear

# add executeable in installs
chmod +x installs/*.zip


echo
echo "#################################################################"
echo "##                                                             ##"
echo "##  Setting up the ${DEMO}              ##"
echo "##                                                             ##"
echo "##                                                             ##"
echo "##                   ###    ##     ##  #######                 ##"
echo "##                  ## ##   ###   ### ##     ##                ##"
echo "##                 ##   ##  #### #### ##     ##                ##"
echo "##                ##     ## ## ### ## ##     ##                ##"
echo "##                ######### ##     ## ##  ## ##                ##"
echo "##                ##     ## ##     ## ##    ##                 ##"
echo "##                ##     ## ##     ##  ##### ##                ##"
echo "##                                                             ##"
echo "##                                                             ##"
echo "##  brought to you by,                                         ##"
echo "##                    ${AUTHORS}                            ##"
echo "##                                                             ##"
echo "##  ${PROJECT} ##"
echo "##                                                             ##"
echo "#################################################################"
echo


echo "  - Stop all existing AMQ processes..."
echo
jps -lm | grep artemis | awk '{print $1}' | if [[ $OSTYPE = "linux-gnu" ]]; then xargs -r kill -SIGTERM; else xargs kill -SIGTERM; fi


# make some checks first before proceeding.
if [[ -r $SRC_DIR/$INSTALLER || -L $SRC_DIR/$INSTALLER ]]; then
		echo "  - $PRODUCT is present..."
		echo
else
		echo Need to download $PRODUCT package from the Customer Support Portal
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi


# Remove old install if it exists.
if [ -x $PRODUCT_HOME ]; then
		echo "  - existing $PRODUCT install detected..."
		echo
		echo "  - moving existing $PRODUCT aside..."
		echo
		rm -rf $PRODUCT_HOME.OLD
		mv $PRODUCT_HOME $PRODUCT_HOME.OLD
fi


# Run installer.
echo "  - Unpacking $PRODUCT $VERSION"
echo
mkdir -p $PRODUCT_HOME && unzip -q -d $PRODUCT_HOME/.. $SRC_DIR/$INSTALLER


echo "  - Making sure 'AMQ' for server is executable..."
echo
chmod u+x $PRODUCT_HOME/bin/artemis


echo "  - Create Replicated Master"
echo
sh $AMQ_SERVER_BIN/artemis create --no-autotune --replicated --failover-on-shutdown  --user admin --password password --role admin --allow-anonymous y --clustered --host 127.0.0.1 --cluster-user clusterUser --cluster-password clusterPassword  --max-hops 1 $AMQ_INSTANCES/$AMQ_MASTER

echo "  - Change default configuration to avoid duplicated live broker when failingback"
echo
sed -i'' -e 's/<master\/>/<master>\                <check-for-live-server>true<\/check-for-live-server>\            <\/master>/' $AMQ_MASTER_HOME/etc/broker.xml

echo "  - Changing default master clustering configuration"
echo
sed -i'' -e 's/<max-disk-usage>90<\/max-disk-usage>/<max-disk-usage>100<\/max-disk-usage>/' $AMQ_MASTER_HOME/etc/broker.xml
sed -i'' -e '/<broadcast-groups>/,/<\/discovery-groups>/d' $AMQ_MASTER_HOME/etc/broker.xml
sed -i'' -e '/<\/connector>/ a \
        <connector name="discovery-connector">tcp://127.0.0.1:61716</connector>' $AMQ_MASTER_HOME/etc/broker.xml
sed -i'' -e 's/<discovery-group-ref discovery-group-name="dg-group1"\/>/<static-connectors>   <connector-ref>discovery-connector<\/connector-ref><\/static-connectors>/' $AMQ_MASTER_HOME/etc/broker.xml

echo "  - Create Replicated Slave"
echo
sh $AMQ_SERVER_BIN/artemis create --no-autotune --replicated --failover-on-shutdown --slave --user admin --password password --role admin --allow-anonymous y --clustered --host 127.0.0.1 --cluster-user clusterUser --cluster-password clusterPassword  --max-hops 1 --port-offset 100 $AMQ_INSTANCES/$AMQ_SLAVE

echo "  - Change default configuration to automate failback"
echo
sed -i'' -e 's/<slave\/>/<slave>\                <allow-failback>true<\/allow-failback>\            <\/slave>/' $AMQ_SLAVE_HOME/etc/broker.xml

echo "  - Changing default master clustering configuration"
echo
sed -i'' -e 's/<max-disk-usage>90<\/max-disk-usage>/<max-disk-usage>100<\/max-disk-usage>/' $AMQ_SLAVE_HOME/etc/broker.xml
sed -i'' -e '/<broadcast-groups>/,/<\/discovery-groups>/d' $AMQ_SLAVE_HOME/etc/broker.xml
sed -i'' -e '/<\/connector>/ a \
        <connector name="discovery-connector">tcp://127.0.0.1:61616</connector>' $AMQ_SLAVE_HOME/etc/broker.xml
sed -i'' -e 's/<discovery-group-ref discovery-group-name="dg-group1"\/>/<static-connectors>   <connector-ref>discovery-connector<\/connector-ref><\/static-connectors>/' $AMQ_SLAVE_HOME/etc/broker.xml

echo "  - Start up AMQ Master in the background"
echo
sh $AMQ_MASTER_HOME/bin/artemis-service start


sleep 10

COUNTER=5
#===Test if the broker is ready=====================================
echo "  - Testing broker,retry when not ready"
while true; do
    if [ $(sh $AMQ_MASTER_HOME/bin/artemis-service status | grep "running" | wc -l ) -ge 1 ]; then
        break
    fi

    if [  $COUNTER -le 0 ]; then
    	echo ERROR, while starting broker, please check your settings.
    	break
    fi
    let COUNTER=COUNTER-1
    sleep 2
done
#===================================================================

echo "  - Start up AMQ Slave in the background"
echo
sh $AMQ_SLAVE_HOME/bin/artemis-service start


sleep 10

COUNTER=5
#===Test if the broker is ready=====================================
echo "  - Testing broker,retry when not ready"
while true; do
    if [ $(sh $AMQ_SLAVE_HOME/bin/artemis-service status | grep "running" | wc -l ) -ge 1 ]; then
        break
    fi

    if [  $COUNTER -le 0 ]; then
    	echo ERROR, while starting broker, please check your settings.
    	break
    fi
    let COUNTER=COUNTER-1
    sleep 2
done
#===================================================================

echo "  - Create haQueue on master broker"
echo
sh $AMQ_MASTER_HOME/bin/artemis queue create --auto-create-address --address haQueue --name haQueue --preserve-on-no-consumers --durable --anycast --url tcp://localhost:61616


echo
echo "To stop the backgroud AMQ broker processes, please go to bin folders and execute 'artemis-service stop'"
echo
