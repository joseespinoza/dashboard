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

declare variable $URI := concat($pd:URI-PREFIX, xs:string($pd:NOW))
;

(: record one sample :)
xdmp:document-insert(
  $URI, pd:sample(), $PERMISSIONS, $COLLECTIONS )

(: sample.xqy :)