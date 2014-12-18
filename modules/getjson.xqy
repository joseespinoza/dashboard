xquery version "1.0-ml";


(: Sets no caching on all types of browsers :)
let $_0 := xdmp:add-response-header("Cache-Control","no-cache")
let $_1:= xdmp:add-response-header("Cache-Control","no-store")
let $_2 := xdmp:add-response-header("Cache-Control","must-revalidate")
let $_3 := xdmp:add-response-header("Pragma","no-cache")
let $_4 := xdmp:add-response-header("Expires","0")
let $json := xdmp:document-get("file:///Users/cchaplin/Library/MarkLogic/dashboard/graph/cluster.json")
return
	$json