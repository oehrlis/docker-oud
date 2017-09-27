# Docker Base Image for Trivadis Engineering
Docker base image for a standalone Unified Directory 12.2.1.3 setup.

## Content

This docker image is based on the official Oracle Linux slim image ([oraclelinux](https://hub.docker.com/r/_/oraclelinux/)). It has been extended with the following Linux packages and configuration:

* Upgrade of all installed packages to the latest release (yum upgrade)
* Install the following additional packages including there dependencies:
    * *util-linux* A collection of basic system utilities
    * *libaio* Linux-native asynchronous I/O access library
    * *hostname* Utility to set/show the host name or domain name
    * *which* Displays where a particular program in your path is located
    * *unzip* A utility for unpacking zip files
    * *zip* A file compression and packaging utility compatible with PKZIP
    * *tar* A GNU file archiving program
    * *sudo* Allows restricted root access for specified users
* Dedicated groups for user *oracle*, oinstall (gid 1000), osdba (gid 1010), osoper (gid 1020), osbackupdba (gid 1030), oskmdba (gid 1040), osdgdba (gid 1050)
* Operating system user *oracle* (uid 1000)
* Add oracle to the sudoers *ALL=(ALL)*
* Oracle Inventory file *oraInst.loc* in *$ORACLE_BASE/etc/oraInst.loc*
* Generic ResponseFile *install.rsp* in *$ORACLE_BASE/etc/install.rsp* used for OUD and FMW installations
* Create of Oracle OFA Directories see below
* Install Oracle Server JRE 8 update 144
* Install Oracle Unified Directory 12c (12.2.1.3) as a standalone setup

The purpose of this image is provide base image for OUD Directory or Proxy Server. The following docker images are based on this images or build with similar structures.

   * [oehrlis/docker-oudsm](https://github.com/oehrlis/docker-oudm)

## Environment Variable and Directories

The following environment variable have been used for the installation:

Environment variable | Value / Directories         | Comment
-------------------- | --------------------------- | ---------------
ORACLE_ROOT          | ```/u00```                  | Root directory for all the Oracle software
ORACLE_BASE          | ```/u00/app/oracle```       | Oracle base directory
ORACLE_ETC           | ```$ORACLE_BASE/etc```      | Oracle etc directory with generic configuration files
n/a                  | ```$ORACLE_BASE/product```  | Oracle product base directory
ORACLE_BASE          | ```$ORACLE_BASE/local```    | Oracle base directory
ORACLE_DATA          | ```/u01```                  | Root directory for the persistent data eg. database, OUD instances etc. A docker volumes must be defined for /u01
INSTANCE_HOME        | ```$ORACLE_DATA/instances```| Location for the OUD instances
DOMAIN_HOME          | ```$ORACLE_DATA/domains```  | Location for the WLS domains
DOWNLOAD             | ```/tmp/download```         | Temporary download directory, will be removed after build
ORACLE_HOME_NAME     | ```fmw12.2.1.3.0```         | Name of the Oracle Home, used to create to PATH to ORACLE_HOME eg. *$ORACLE_BASE/product/$ORACLE_HOME_NAME*
DOCKER_BIN           | ```/opt/docker/bin```       | Docker build and setup scripts
JAVA_DIR             | ```/usr/java```             | Base directory for java home location
JAVA_HOME            | ```$JAVA_DIR/jdk1.8.0_144```| Java home directory

## Installation and Build
The docker image has to be build manually based on [oehrlis/docker-tvd](https://github.com/oehrlis/docker-tvd) from GitHub. Due to license restrictions from Oracle I can not provide this image on a public Docker repository (see [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html)). The required Software has to be downloaded prior image build. Alternatively it is possible to specify MOS credentials in ```scripts/.netrc``` or via build arguments.

### Obtaining Product Distributions
The Oracle Software required to setup an Oracle Unified Directory docker image is basically not public available. It is subject to Oracle's license terms. For this reason a valid license is required (eg. [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html)). In addition, Oracle's license terms and conditions must be accepted before downloading.

The following software is required for the Oracle Unified Directory docker image:
* Oracle Java Development Kit (JDK) 1.8 (1.8u144)
* Oracle Unified Directory 12.2.1.3.0

The software can either be downloaded from [My Oracle Support (MOS)](https://support.oracle.com), [Oracle Technology Network (OTN)](http://www.oracle.com/technetwork/index.html) or [Oracle Software Delivery Cloud (OSDC)](http://edelivery.oracle.com). The follwing steps will refere to the MOS software download to simplify the build process.

### Manual download Software
Simplest method to build the OUD image is to manually download the required software. However this will lead to bigger docker images, since the software is copied during build, which temporary blow up the container file-system. But its more safe because you do not have to store any MOS credentials.

The corresponding links and checksum can be found in ```*.download``` files in the ```software```folder. Alternatively the Oracle Support Download Links:
* Oracle Java Server JRE 8 update 144 [Patch 26512979](https://updates.oracle.com/ARULink/PatchDetails/process_form?patch_num=26512979) or [direct](https://updates.oracle.com/Orion/Services/download/p26512979_180144_Linux-x86-64.zip?aru=21443434&patch_file=p26512979_180144_Linux-x86-64.zip)
* Oracle Unified Directory 12.2.1.3.0 [Patch 26270957](https://updates.oracle.com/ARULink/PatchDetails/process_form?patch_num=26270957) or [direct](https://updates.oracle.com/Orion/Services/download/p26270957_122130_Generic.zip?aru=21504981&patch_file=p26270957_122130_Generic.zip)

Copy both files to the ```software```folder.

    cp p26512979_180144_Linux-x86-64.zip docker-oud/software
    cp p26270957_122130_Generic.zip docker-oud/software

Build the docker image either by using ```docker build``` or ```build.sh```.

    docker build -t oehrlis/oud .

    scripts/build.sh

### Automatic download with .netrc
The advantage of an automatic software download during build is the reduced image size. No additional image layers are created for the software and the final docker image is about 500MB smaller. But the setup script (```setup_oud.sh```) requires the MOS credentials to download the software with [curl](https://linux.die.net/man/1/curl). Curl does read the credentials from the ```.netrc``` file in ```scripts``` folder. The ```.netrc``` file will be copied to ```/opt/docker/bin/.netrc```, but it will be removed at the end of the build.

Create a ```.netrc``` file with the credentials for *login.oracle.com*.

    echo "machine login.oracle.com login <MOS_USER> password <MOS_PASSWORD>" >docker-oud/scripts/.netrc

Build the docker image either by using ```docker build``` or ```build.sh```.

        docker build -t oehrlis/oud .

        scripts/build.sh

### Automatic download with Build Arguments
This method is similar to the automatic download with ```.netrc``` file. Instead of manually creating a ```.netrc``` file it will created based on build parameter. Also with this method the ```.netrc``` file is deleted at the end.

Build the docker image with MOS credentials as arguments.

    docker build --build-arg MOS_USER=<MOS_USER> --build-arg MOS_PASSWORD=<MOS_PASSWORD> -t oehrlis/oud .

### Setup Oracle Unified Directory Instance
So far this part has not yet been automated. Never the less you can create a container and manually create your OUD instance with ```oud-setup``` or ```oud-setup-proxy```.

		docker run -v [<host mount point>:]/u01 --name OUD-Engineering oehrlis/oud
		docker start -ai OUD-Engineering

## Issues
Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/docker-tvd/issues)
* [submit new issue](https://github.com/oehrlis/docker-tvd/issues/new)

## License
docker-oud is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

To download and run Oracle Unifified Directory , regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page. See [OTN Developer License Terms](http://www.oracle.com/technetwork/licenses/standard-license-152015.html) and [Oracle Database Licensing Information User Manual](https://docs.oracle.com/database/122/DBLIC/Licensing-Information.htm#DBLIC-GUID-B6113390-9586-46D7-9008-DCC9EDA45AB4)
