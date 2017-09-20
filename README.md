Oracle Unified Directory on Docker
===============
Sample Docker configurations to facilitate installation, configuration, and environment setup for DevOps users. This project includes quick start [dockerfiles](dockerfiles/) and [samples](samples/) for Oracle Unified Directory 12.2.1.3 based on Oracle Linux and Oracle JDK 8 (Server). 

For more information on the certification, please check the tbd.

For pre-built images containing Oracle software, please check the [Oracle Container Registry](https://container-registry.oracle.com).

## How to build and run
...

The `build.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle JDK (Server JRE) base image
You must first download the Oracle Server JRE binary and drop in folder `../OracleJava/java-8` and build that image. For more information, visit the [OracleJava](../OracleJava) folder's [README](../OracleJava/README.md) file.

        $ cd ../docker-oud
        $ sh build.sh

### Building Unified Directory Docker Install Images

## License
To download and run Oracle Unified Directory 12c Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker/OracleWebLogic](./) repository required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
n/a
