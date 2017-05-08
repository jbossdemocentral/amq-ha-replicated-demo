# Red Hat AMQ 7 High Availability Replicated Demo (Shared Nothing)

Red Hat JBoss AMQ 7 provides fast, lightweight, and secure messaging for Internet-scale applications. This is a demostration of the new JBoss AMQ 7 replicated high availability feature to avoid using a shared store.

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
