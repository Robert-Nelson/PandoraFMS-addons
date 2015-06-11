PandoraFMS Agent Plugins for Unix and Windows
---------------------------------------------

These plugins provide modules for each of the sensors from IPMI.  They set
Warning and Critical Status based on the thresholds provided by IPMI.  The
Module Group can also be specified.

For Unix systems the freeipmi package must be installed.  The IPMI information
can be retrieved from the local system or using the network interface to the
IPMI device.

For Windows a version of freeipmi built with cygwin is provided.  The IPMI
information is retrieved using the network interface to the IPMI device.
