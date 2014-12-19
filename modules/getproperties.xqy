xquery version "1.0-ml";
(:An XQuery main module that receives HTTP request from /graph/graph.js and returns an HTTP response containing the html used within the tooltip pop-up window:)
(:Takes in two header fields from the HTTP request("nodename" and "type"), uses these fields to generate a response back to graph/graph.js:)
(:Chris Chaplinsky:)

declare namespace an="http://marklogic.com/xdmp/assignments";(:for assignments.xml:)
declare namespace db="http://marklogic.com/xdmp/database";(:for databases.xml:)
declare namespace fs="http://marklogic.com/xdmp/status/forest";(:for Forest Status:)
declare namespace gr="http://marklogic.com/xdmp/group";(:for groups.xml:)
declare namespace ho="http://marklogic.com/xdmp/hosts";(:for hosts.xml:)
declare namespace hs="http://marklogic.com/xdmp/status/host";(:for Host Status:)
declare namespace xh="http://www.w3.org/1999/xhtml";
declare namespace cl="http://marklogic.com/xdmp/clusters";(:for cluster.xml:)
declare namespace sv="http://marklogic.com/xdmp/status/server";


declare variable $responseType := xdmp:set-response-content-type("text/html");

(:gets request header fields:)
let $nodename := xdmp:get-request-field("nodename")
let $node-type := xdmp:get-request-field("type")
(:Name of shortened Support Dump on the database containing all necessary node information, this file is generated in log-analyze.xqy :)
let $filename := "cluster-summary.xml"
return

(:Descion Making (if/else) statements generating different output based on node type:)
(:CLUSTER PROPERTIES:)
if($node-type="cluster") then(
<html>
	<name>
		<b>Cluster</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		SSL-Flips-Enabled: {fn:doc($filename)/summary/cluster/cl:clusters/cl:ssl-fips-enabled}
		<br/>
		Foreign Cluster Name: {fn:doc($filename)/summary/cluster/cl:clusters/cl:foreign-cluster-name}
		<br/>
		XDQP-Timeout: {fn:doc($filename)/summary/cluster/cl:clusters/cl:xdqp-timeout}
		<br/>
		Host-Timeout: {fn:doc($filename)/summary/cluster/cl:clusters/cl:host-timeout}
		<br/>
		Foreign-Host-Name: {fn:doc($filename)/summary/cluster/cl:clusters/cl:foreign-host-name}

	</properties>
</html>


(:GROUP PROPERTIES:)
)else if($node-type="group") then(
<html>
	<name>
		<b>Group</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		list-cache-size: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:list-cache-size}
		<br/>
		list-cache-partitions: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:list-cache-partitions}
		<br/>
		compressed-tree-cache-size: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:compressed-tree-cache-size}
		<br/>
		compressed-tree-cache-partitions: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:compressed-tree-cache-partitions}
		<br/>
		compressed-tree-read-size: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:compressed-tree-read-size}
		<br/>
		expanded-tree-cache-size: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:expanded-tree-cache-size}
		<br/>
		expanded-tree-cache-partitions: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:expanded-tree-cache-partitions}
		<br/>
		http-timeout: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:http-timeout}
		<br/>
		xdqp-timeout: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:xdqp-timeout}
		<br/>
		host-timeout: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:host-timeout}
		<br/>
		file-log-level: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:file-log-level}
		<br/>
		failover-enable: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:failover-enable}
		<br/>
		background-io-limit: {fn:doc($filename)/summary/groups/gr:group[gr:group-name=$nodename]/gr:background-io-limit}
		<br/>

	</properties>
</html>


(:HOST PROPERTIES:)
)else if($node-type="host") then(
<html>
	<name>
		<b>Host</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		environment: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:environment}
		<br/>
		cpus: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:cpus}
		<br/>
		cores: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:cores}
		<br/>
		core-threads: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:core-threads}
		<br/>
		memory-process-size: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-process-size}
		<br/>
		memory-process-swap-rate: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-process-swap-rate}
		<br/>
		memory-system-pagein-rate: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-system-pagein-rate}
		<br/>
		memory-system-pageout-rate: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-system-pageout-rate}
		<br/>
		memory-system-swapin-rate: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-system-swapin-rate}
		<br/>
		memory-system-swapout-rate: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-system-swapout-rate}
		<br/>
		memory-size: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:memory-size}
		<br/>
		host-size: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:host-size}
		<br/>
		host-large-data-size: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:host-large-data-size}
		<br/>
		log-device-space: {fn:doc($filename)/summary/hosts-status/hs:host-status[hs:host-name=$nodename]/hs:log-device-space}
		
		{(:{fn:doc($filename)/summary/hosts/ho:host[ho:host-name=$nodename]:)}
	</properties>
</html>


(:FOREST PROPERTIES:)
)else if($node-type="forest") then(
<html>
	<name>
		<b>Forest</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		state: {fn:doc($filename)/summary/forest-status/fs:forest-status[fs:forest-name=$nodename]/fs:state}
		<br/>
		enabled: {fn:doc($filename)/summary/forest-status/fs:forest-status[fs:forest-name=$nodename]/fs:enabled}
		<br/>
		availability: {fn:doc($filename)/summary/forest-status/fs:forest-status[fs:forest-name=$nodename]/fs:availability}
		<br/>
		document-count: {fn:doc($filename)/summary/forest-counts/fs:forest-counts[fs:forest-name=$nodename]/fs:document-count}

	</properties>
</html>


(:DATABASE PROPERTIES:)
)else if($node-type="database") then(
<html>
	<name>
		<b>Database</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		enabled: {fn:doc($filename)/summary/databases/db:database[db:database-name=$nodename]/db:enabled}
		<br/>
		reindexer-enable: {fn:doc($filename)/summary/databases/db:database[db:database-name=$nodename]/db:reindexer-enable}
		<br/>
		uri-lexicon: {fn:doc($filename)/summary/databases/db:database[db:database-name=$nodename]/db:uri-lexicon}

	</properties>
</html>


(:APP-SERVER PROPERTIES:)
)else if($node-type="app-server") then(
<html>
	<name>
		<b>App-Server</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		{(:fn:doc($filename)/summary/servers/sv:server-status[sv:server-name = $nodename]:)}
		"App-Server properties go here"
	</properties>
</html>

(:ERROR-in case node does not match:)
)else(
<name>
<b>ERROR</b>
<hr/>
<b>NODE: </b>{$nodename}
<hr/>
<b>NODE TYPE: </b>"{$node-type}"
</name>
)
