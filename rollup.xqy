xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";

declare variable $COLLECTIONS := $pd:NAME
;

declare variable $PERMISSIONS := (
  xdmp:permission($pd:ROLENAME-READ, 'read'),
  xdmp:permission($pd:ROLENAME, 'update')
);

(: TODO find samples older than some date,
 : roll them up into average/min/max/square-of-sums super-samples,
 : and delete the orignals.
 :)

(: TODO add rollup scheduled task to installer :)

(: TODO add rollup scheduled task to uninstaller :)

error((), "UNIMPLEMENTED")

(: rollup.xqy :)