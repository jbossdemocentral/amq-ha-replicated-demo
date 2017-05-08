#!/bin/sh
DEMO="JBoss AMQ 7 Replicated HA Demo"
VERSION=7.0.0
AUTHORS="Hugo Guerrero"
PROJECT="git@github.com:hguerrero/amq-ha-replicated-demo.git"
AMQ=A-MQ7-7.0.0.ER15-1-redhat-1
AMQ_BIN=A-MQ7-7.0.0.ER15-1-redhat-1-bin.zip
DEMO_HOME=./target
AMQ_HOME=$DEMO_HOME/$AMQ
AMQ_PROJECT=./project/failoverdemo62
AMQ_SERVER_CONF=$AMQ_HOME/etc
AMQ_SERVER_BIN=$AMQ_HOME/bin
AMQ_INSTANCES=$AMQ_HOME/instances
AMQ_MASTER=replicatedMaster
AMQ_SLAVE=replicatedSlave
AMQ_MASTER_HOME=$AMQ_INSTANCES/$AMQ_MASTER
AMQ_SLAVE_HOME=$AMQ_INSTANCES/$AMQ_MASTER
SRC_DIR=./installs
PRJ_DIR=./projects/failoverdemo62

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
echo "##                #####  #   #  #####  #####                   ##"
echo "##                #      #   #  #      #                       ##"
echo "##                #####  #   #  #####  ####                    ##"
echo "##                #      #   #      #  #                       ##"
echo "##                #      #####  #####  #####                   ##"
echo "##                                                             ##"
echo "##                                                             ##"
echo "##  brought to you by,                                         ##"
echo "##                    ${AUTHORS}                            ##"
echo "##                                                             ##"
echo "##  ${PROJECT}        ##"
echo "##                                                             ##"
echo "#################################################################"
echo


echo "  - Stop all existing AMQ processes..."
echo
jps -lm | grep artemis | grep -v grep | awk '{print $1}' | xargs -r kill -KILL


# make some checks first before proceeding.
if [[ -r $SRC_DIR/$AMQ_BIN || -L $SRC_DIR/$AMQ_BIN ]]; then
		echo $DEMO AMQ is present...
		echo
else
		echo Need to download $AMQ_BIN package
    echo from the Customer Support Portal and place it in the $SRC_DIR
		echo directory to proceed...
		echo
		exit
fi


# Create the target directory if it does not already exist.
if [ ! -x $DEMO_HOME ]; then
		echo "  - creating the demo home directory..."
		echo
		mkdir $DEMO_HOME
else
		echo "  - detected demo home directory, moving on..."
		echo
fi


# Move the old JBoss instance, if it exists, to the OLD position.
if [ -x $AMQ_HOME ]; then
		echo "  - existing JBoss AMQ detected..."
		echo
		echo "  - moving existing JBoss AMQ aside..."
		echo
		rm -rf $AMQ_HOME.OLD
		mv $AMQ_HOME $AMQ_HOME.OLD

		# Unzip the JBoss instance.
		echo Unpacking JBoss AMQ $VERSION
		echo
		unzip -q -d $DEMO_HOME $SRC_DIR/$AMQ_BIN
else
		# Unzip the JBoss instance.
		echo Unpacking new JBoss AMQ...
		echo
		unzip -q -d $DEMO_HOME $SRC_DIR/$AMQ_BIN
fi


echo "  - Making sure 'AMQ' for server is executable..."
echo
chmod u+x $AMQ_HOME/bin/artemis


echo "  - Create Replicated Master"
echo
sh $AMQ_SERVER_BIN/artemis create --replicated --failover-on-shutdown  --user admin --password password --role admin --allow-anonymous y --clustered --host 127.0.0.1 --cluster-user clusterUser --cluster-password clusterPassword  --max-hops 1 $AMQ_INSTANCES/$AMQ_MASTER

echo "  - Change default configuration to avoid duplicated live broker when failingback"
echo
sh sed -i 's#<master/>#<master><check-for-live-server>true</check-for-live-server></master>#' $AMQ_INSTANCES/$AMQ_MASTER/etc/broker.xml


echo "  - Create Replicated Slave"
echo
sh $AMQ_SERVER_BIN/artemis create --replicated --failover-on-shutdown --slave --user admin --password password --role admin --allow-anonymous y --clustered --host 127.0.0.1 --cluster-user clusterUser --cluster-password clusterPassword  --max-hops 1 --port-offset 100 $AMQ_INSTANCES/$AMQ_SLAVE

echo "  - Change default configuration to automate failback"
echo
sh sed -i 's#<slave/>#<slave><check-for-live-server>true</check-for-live-server></slave>#' $AMQ_INSTANCES/$AMQ_SLAVE/etc/broker.xml


echo "  - Start up AMQ Master in the background"
echo
sh $AMQ_MASTER_HOME/bin/artemis-service start

echo "  - Create haQueue on master broker"
echo
sh $AMQ_MASTER_HOME/bin/artemis queue create --auto-create-address --address haQueue --name haQueue --keep-on-no-consumers --durable --anycast --url tcp://localhost:61616


sleep 15

COUNTER=5
#===Test if the fabric is ready=====================================
echo "  - Testing fabric,retry when not ready"
while true; do
    if [ $(sh $AMQ_SERVER_BIN/client 'fabric:status'| grep "100%" | wc -l ) -ge 3 ]; then
        break
    fi

    if [  $COUNTER -le 0 ]; then
    	echo ERROR, while creating Fabric, please check your Network settings.
    	break
    fi
    let COUNTER=COUNTER-1
    sleep 2
done
#===================================================================



echo "Go to Project directory"
echo
cd $AMQ_PROJECT

echo "Start compile and deploy failover camel example project to fuse"
echo
mvn fabric8:deploy


cd ../..



echo "To stop the backgroud AMQ process, please go to bin and execute stop"
echo
