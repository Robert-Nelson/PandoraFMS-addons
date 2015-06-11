PandoraFMS Unix Agent Plugin: ipmi_sensors
------------------------------------------

This PandoraFMS Agent plugin for unix creates a module for each IPMI sensor.

To install, copy ipmi_sensors to the plugins directory which is usually 
/usr/share/pandora_agent/plugins.  This plugin requires freeipmi to be installed
and available on the agent's path.

Then add it to the configuration file, usually /etc/pandora/pandora_agent.conf.

For IPMI local access use:

	module_plugin ipmi_sensors -l

For IPMI network access use:

	module_plugin ipmi_sensors -h <hostname> -u <username> -p <password>

Replace &lt;hostname&gt;, &lt;username&gt; and &lt;password&gt; with appropriate values.

If you wish the modules to be in a module group add "-g &lt;group&gt;".  For example:

	module_plugin ipmi_sensors -l -g "IPMI Sensors"

Note: The module group must be created in PandoraFMS in advance.
