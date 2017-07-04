# Red Hat AMQ 7 High Availability Replicated Demo (Shared Nothing)

## Introduction
Red Hat JBoss AMQ 7 provides fast, lightweight, and secure messaging for Internet-scale applications. AMQ 7 components use industry-standard message protocols and support a wide range of programming languages and operating environments. AMQ 7 gives you the strong foundation you need to build modern distributed applications.

This is a demostration of the new JBoss AMQ 7 replicated high availability feature to avoid using a shared store.

## Overview
This project demostrate how to set up a master-slave high available broker using the replicated journal feature.

## Prerequisites
This workshop requires you to use your own laptop and have the following prerequisites installed:

#### Hardware requirements

* Operating System
  * Mac OS X (10.8 or later) or
  * Windows 7 (SP1) or
  * Fedora (21 or later) or
  * Red Hat Enterprise Linux 7
* Memory: At least 2 GB+, preferred 4 GB

#### Software requirements

* Web Browser (preferably Chrome or Firefox)
* Git client -- [download here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* http://github.com access

For running JBoss AMQ 7 Broker

* **Java Runtime Engine (JRE) 1.8** --[download here](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
* LibAIO (Optional)

If installing from supported version of Red Hat Enterprise Linux you can use yum command to install pre-requisites.

```
$ sudo yum install java-1.8.0-openjdk-devel git
```

## Deployment

This demo can be deployed using the automated installation based on the [init.sh](init.sh) script.

#### Using the script

The [init.sh](init.sh) script automates the installation and instantiation of the components contained within this demo. It will deploy an HA Broker configuration with a master broker running as the Live Broker and a second broker, the slave broker, running as a Backup for the Live Broker.

First, execute the *init.sh* script

```
./init.sh
```

After successfully deployed, you can test the failover

## Testing

#### Sending messages

To send messages to the master broker, execute the following command:

```
$ target/jboss-amq-7.0.0.redhat-1/instances/replicatedMaster/bin/artemis producer --message-count 10 --url "tcp://127.0.0.1:61616" --destination queue://haQueue
```

#### Browse messages on Master

To check the messages were successfully send to the broker, check the queue in the broker web console.

* Open a web browser and navigate to the AMQ web console http://localhost:8161/hawtio
* In the left tree navigate to 127.0.0.1 > addresses > haQueue > queues > anycast > haQueue
* Click on *Browse* (refresh if necessary)

You will see the 10 messages send by the producer script.

#### Browse backup Console

As the replicatedSlave broker is running as a backup broker for replicatedMaster, there are no active addresses or queues listening.

* Open a web browser and navigate to the AMQ web console http://localhost:8261/hawtio
* In the left tree navigate to 127.0.0.1 > addresses > haQueue > queues > anycast > haQueue

You will only see the information regarding the cluster broadcast configuration.

## Failover

#### Master shutdown

To shutdown the master broker, execute the following command:

```
$ target/jboss-amq-7.0.0.redhat-1/instances/replicatedMaster/bin/artemis-service stop
```

While the master is shutting down, the backup broker will notice the disconnection from the master and bwill become live.

#### Browse messages on Slave

To check the messages were successfully replicated to the slave broker, check the queue in the slave broker web console.

* Refresh the AMQ web console http://localhost:8261/hawtio
* In the left tree navigate to 127.0.0.1 > addresses > haQueue > queues > anycast > haQueue
* Click on *Browse* (refresh if necessary)

You will see the 10 messages send by the producer script to the master broker.

## Failback

If you want, you can start again the replicatedMaster broker to see how the backup failbacks to the master.

```
$ target/jboss-amq-7.0.0.redhat-1/instances/replicatedMaster/bin/artemis-service start
```

The master will start and check if there is a live broker, when the backup detects that the master has become availbale again, it failsback going in a backup mode again.

## Contributing

We welcome all forms of contribution (content, issues/bugs, feedback).
