# Oracle Unified Directory on Docker
Docker image for a standalone Unified Directory 12.2.1.3 or a collocated 
Unified Directory 12.2.1.3 setup with Oracle Fusion Middleware Infrastructure 
12.2.1.3

**CURRENTLY NOT UPTODATE with the latest commit**

## Content
This docker image is based on the official Oracle Linux slim image
([oraclelinux](https://hub.docker.com/r/_/oraclelinux/)). It has been extended
with the following Linux packages and configuration:

* Upgrade of all installed packages to the latest release (yum upgrade)
* Install the following additional packages including there dependencies:
    * *hostname* Utility to set/show the host name or domain name
    * *which* Displays where a particular program in your path is located
    * *unzip* A utility for unpacking zip files
    * *tar* A GNU file archiving program
    * *gzip* A file compression and packaging utility compatible with PKZIP
    * *procps-ng* System and process monitoring utilities
* Dedicated groups for user *oracle*, oinstall (gid 1000), osdba (gid 1010),
osoper (gid 1020), osbackupdba (gid 1030), oskmdba (gid 1040), osdgdba (gid 1050)
* Operating system user *oracle* (uid 1000)
* [OUD Base](https://github.com/oehrlis/oudbase) environment developed by [ORAdba](www.oradba.ch)
* Create of Oracle OFA Directories see below
* Install Oracle Server JRE 8 update 152
* Install Oracle Fusion Middleware Infrastructure 12c (12.2.1.3)
* Install Oracle Unified Directory 12c (12.2.1.3) collocated with Oracle Fusion Middleware

The purpose of this image is provide a Oracle Unified Directory Server Manager
(OUDSM) environment which can be used to access any OUD server on the network
or Oracle Unified Directory (OUD) standalone docker images
[oehrlis/docker-oud](https://github.com/oehrlis/docker-oud). By default a
OUDSM domain will be setup and started. If require, you may also manually
create a local OUD instance in this container.

## Environment Variable and Directories

The following environment variable have been used for the installation:

Environment variable | Value / Directories         | Comment
-------------------- | --------------------------- | ---------------
ORACLE_ROOT          | ```/u00```                   | Root directory for all the Oracle software
ORACLE_BASE          | ```/u00/app/oracle```         | Oracle base directory
n/a                  | ```$ORACLE_BASE/product```    | Oracle product base directory
ORACLE_BASE          | ```$ORACLE_BASE/local```    | Oracle base directory
ORACLE_DATA          | ```/u01```                  | Root directory for the persistent data eg. database, OUD instances etc. A docker volumes must be defined for /u01
INSTANCE_HOME        | ```$ORACLE_DATA/instances```| Location for the OUD instances
DOMAIN_HOME          | ```$ORACLE_DATA/domains```  | Location for the WLS domains
ETC_BASE             | ```$ORACLE_DATA/etc```      | Oracle etc directory with configuration files
LOG_BASE             | ```$ORACLE_DATA/log```      | Oracle log directory with log files
DOWNLOAD             | ```/tmp/download```         | Temporary download directory, will be removed after build
ORACLE_HOME_NAME     | ```fmw12.2.1.3.0```         | Name of the Oracle Home, used to create to PATH to ORACLE_HOME eg. *$ORACLE_BASE/product/$ORACLE_HOME_NAME*
DOCKER_BIN           | ```/opt/docker/bin```       | Docker build and setup scripts
JAVA_DIR             | ```/usr/java```             | Base directory for java home location
JAVA_HOME            | ```$JAVA_DIR/jdk1.8.0_152```| Java home directory

## Installation and Build
The docker image has to be build manually based on [oehrlis/docker-oud](https://github.com/oehrlis/docker-oudsm) from GitHub. Due to license restrictions from Oracle I can not provide this image on a public Docker repository (see [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html)). The required Software has to be downloaded prior image build. Alternatively it is possible to specify MOS credentials in ```scripts/.netrc``` or via build arguments.

### Obtaining Product Distributions
The Oracle Software required to setup an Oracle Unified Directory docker image is basically not public available. It is subject to Oracle's license terms. For this reason a valid license is required (eg. [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html)). In addition, Oracle's license terms and conditions must be accepted before downloading.

The following software is required for the Oracle Unified Directory docker image:
* Oracle Java Development Kit (JDK) 1.8 (1.8u152)
* Oracle Unified Directory 12.2.1.3.0
* Oracle Fusion Middleware Infrastructure 12.2.1.3.0

The software can either be downloaded from [My Oracle Support (MOS)](https://support.oracle.com), [Oracle Technology Network (OTN)](http://www.oracle.com/technetwork/index.html) or [Oracle Software Delivery Cloud (OSDC)](http://edelivery.oracle.com). The follwing steps will refere to the MOS software download to simplify the build process.

### Manual download Software
Simplest method to build the OUD image is to manually download the required software. However this will lead to bigger docker images, since the software is copied during build, which temporary blow up the container file-system. But its more safe because you do not have to store any MOS credentials.

The corresponding links and checksum can be found in ```*.download``` files in the ```software```folder. Alternatively the Oracle Support Download Links:
* Oracle Java Server JRE 8 update 152 [Patch 26595894](https://updates.oracle.com/ARULink/PatchDetails/process_form?patch_num=26595894) or [direct](https://updates.oracle.com/Orion/Services/download/p26595894_180152_Linux-x86-64.zip?aru=21611278&patch_file=p26595894_180152_Linux-x86-64.zip)
* Oracle Unified Directory 12.2.1.3.0 [Patch 26270957](https://updates.oracle.com/ARULink/PatchDetails/process_form?patch_num=26270957) or [direct](https://updates.oracle.com/Orion/Services/download/p26270957_122130_Generic.zip?aru=21504981&patch_file=p26270957_122130_Generic.zip)
* Oracle Fusion Middleware Infrastructure 12.2.1.3.0 [Patch 26269885](https://updates.oracle.com/ARULink/PatchDetails/process_form?patch_num=26269885) or [direct](https://updates.oracle.com/Orion/Services/download/p26269885_122130_Generic.zip?aru=21502041&patch_file=p26269885_122130_Generic.zip)

Copy all files to the ```software```folder.

    cp p26595894_180152_Linux-x86-64.zip docker-oud/software
    cp p26270957_122130_Generic.zip docker-oud/software
    cp p26269885_122130_Generic.zip docker-oud/software

Build the docker image either by using ```docker build``` or ```build.sh```.

    docker build -t oehrlis/oudsm .

    scripts/build.sh

### Automatic download with .netrc
The advantage of an automatic software download during build is the reduced image size. No additional image layers are created for the software and the final docker image is about 3GB smaller. But the setup script (```setup_oud.sh```) requires the MOS credentials to download the software with [curl](https://linux.die.net/man/1/curl). Curl does read the credentials from the ```.netrc``` file in ```scripts``` folder. The ```.netrc``` file will be copied to ```/opt/docker/bin/.netrc```, but it will be removed at the end of the build.

Create a ```.netrc``` file with the credentials for *login.oracle.com*.

    echo "machine login.oracle.com login <MOS_USER> password <MOS_PASSWORD>" >docker-oud/scripts/.netrc

Build the docker image either by using ```docker build``` or ```build.sh```.

        docker build -t oehrlis/oudsm .

        scripts/build.sh

### Automatic download with Build Arguments
This method is similar to the automatic download with ```.netrc``` file. Instead of manually creating a ```.netrc``` file it will created based on build parameter. Also with this method the ```.netrc``` file is deleted at the end.

Build the docker image with MOS credentials as arguments.

        docker build --build-arg MOS_USER=<MOS_USER> --build-arg MOS_PASSWORD=<MOS_PASSWORD> -t oehrlis/oudsm .

## Running the OUDSM Docker Image
### Setup Oracle Unified Directory Server Manager Domain
When the container is started the first time ```create_and_start_OUDSM_Domain.sh``` will create and configure a OUDSM domain. The script will use a few default values (see below).  You can override the default values of the following parameters during runtime with the -e option:

* **DOMAIN_NAME** OUDSM weblogic domain name (default *oudsm_domain*)
* **DOMAIN_HOME** Domain home path (default */u01/domains*)
* **ADMIN_PORT** OUDSM admin port (default *7001*)
* **ADMIN_SSLPORT** OUDSM SSL admin port (default *7002*)
* **ADMIN_USER**  Weblogic user name (default *weblogic*)
* **ADMIN_PASSWORD** Weblogic user password (default *autogenerated*)

**Note** To set the DOMAIN_NAME, you must set both DOMAIN_NAME and DOMAIN_HOME.

The following docker run command does create a volume for the OUDSM domain and publish the weblogic ports. Creating a volume is optional, nevertheless it does make sense to keep the domain seperate from the container. This way your domain configuration is persistent.

        docker run --detach --volume [<host mount point>:]/u01 -p 7001:7001 -p 7002:7002 \
          --hostname oudsm --name oudsm oehrlis/oudsm

Alternative run command to overwrite the default values for creating the OUDSM domain.

        docker run --detach -e ADMIN_PORT=7070 -e ADMIN_PASSWORD=welcome1 \
          --volume [<host mount point>:]/u01 -p 7070:7070 -p 7002:7002 \
          --hostname oudsm --name oudsm oehrlis/oudsm

If you need to find the passwords at a later time, grep for "password" in the Docker logs generated during the startup of the container. To look at the Docker Container logs run:

    docker logs --details oudsm

## Issues
Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/docker-oud/issues)
* [submit new issue](https://github.com/oehrlis/docker-oud/issues/new)

## License
docker-oud is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

To download and run Oracle Unifified Directory, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page. See [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) and [Oracle Database Licensing Information User Manual](https://docs.oracle.com/database/122/DBLIC/Licensing-Information.htm#DBLIC-GUID-B6113390-9586-46D7-9008-DCC9EDA45AB4)
