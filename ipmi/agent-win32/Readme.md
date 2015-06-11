PandoraFMS Windows Agent Plugin: ipmi_sensors
---------------------------------------------

This PandoraFMS Agent plugin for Windows creates a module for each IPMI sensor.

The following installation instructions refer to the pandora_agent_install directory.
On 32-bit windows this is usually C:\Program Files\pandora_agent, on 64-bit Windows
it is usually C:\Program Files (x86)\pandora_agent.

To install, copy ipmi_sensors.vbs to the util subdirectory of the pandora_agent_install
directory.  Copy the freeipmi directory to the pandora_agent_install directory.

Then add it to the configuration file, usually pandora_agent.conf in the pandora_agent_install
directory.

	module_plugin ipmi_sensors -h <hostname> -u <username> -p <password>

Replace &lt;hostname&gt;, &lt;username&gt; and &lt;password&gt; with appropriate values.

If you wish the modules to be in a module group add "-g &lt;group&gt;".  For example:

	module_plugin ipmi_sensors -l -g "IPMI Sensors"

Note: The module group must be created in PandoraFMS in advance.
