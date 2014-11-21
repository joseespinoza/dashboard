xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

import module namespace v="http://marklogic.com/performance/dashboard/view"
 at "lib-view.xqy";

(: TODO check install requirements, redirect as needed :)

v:page(
  <v:page xmlns="http://www.w3.org/1999/xhtml">
    element v:head { },
    <v:body>
      <ul>
        <li><a href="log-analyze.xqy?source=local">Server health</a></li>
        <li><a href="dashboard.xqy">Dashboard</a>
      (<a href="purge.xqy">purge older samples</a>)</li>
        <li><a href="log-analyze.xqy">Analyze a support log</a></li>
      </ul>
      <hr/>
      <ul>
        <li><a href="install.xqy">Install dashboard</a></li>
        <li><a href="uninstall.xqy">Uninstall dashboard</a></li>
      </ul>
    </v:body>
  </v:page>
)

(: default.xqy :)