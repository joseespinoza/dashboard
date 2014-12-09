xquery version "1.0-ml";

let $responseType := xdmp:set-response-content-type("text/html")
let $post-data := xdmp:get-request-field("nodename")
return
<post-data>
<b>
   {$post-data}
</b>
</post-data>