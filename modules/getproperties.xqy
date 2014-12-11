xquery version "1.0-ml";
(:A file that returns an html response containing desired information about a specific kind of node:)

declare variable $responseType := xdmp:set-response-content-type("text/html");

let $nodename := xdmp:get-request-field("nodename")
let $node-type := xdmp:get-request-field("type")
return

if($node-type="cluster") then(
<html>
	<name>
		<b>Cluster</b>: {$nodename}
	</name>
	<hr/>
	<properties>
		"Cluster properties go here"
	</properties>
</html>


)else if($node-type="group") then(
<html>
<name>
<b>Group</b>: {$nodename}
</name>
<hr/>
<properties>
"Group properties go here"
</properties>
</html>


)else if($node-type="host") then(
<html>
<name>
<b>Host</b>: {$nodename}
</name>
<hr/>
<properties>
"Host properties go here"
</properties>
</html>


)else if($node-type="forest") then(
<html>
<name>
<b>Forest</b>: {$nodename}
</name>
<hr/>
<properties>
"Forest properties go here"
</properties>
</html>


)else if($node-type="database") then(
<html>
<name>
<b>Database</b>: {$nodename}
</name>
<hr/>
<properties>
"Database properties go here"
</properties>
</html>


)else if($node-type="app-server") then(
<html>
<name>
<b>App-Server</b>: {$nodename}
</name>
<hr/>
<properties>
"App-Server properties go here"
</properties>
</html>


)else(
<name>
<b>ERROR</b>
<hr/>
<b>NODE: </b>{$nodename}
<hr/>
<b>NODE TYPE: </b>"{$node-type}"
</name>
)
