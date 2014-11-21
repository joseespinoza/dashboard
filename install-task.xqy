xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)
declare namespace gr="http://marklogic.com/xdmp/group";

import module namespace admin="http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";

import module namespace in="http://marklogic.com/performance/dashboard/install"
 at "lib-install.xqy";

declare variable $INTERVAL as xs:positiveInteger external;
declare variable $NAME as xs:string external;
declare variable $PATH as xs:string external;

in:name-set($NAME),
(: make sure we only install one task! :)
let $tasks := (
  admin:group-get-scheduled-tasks($in:CONFIG, $in:GROUP)
  [gr:task-path eq $PATH]
  [gr:task-root eq $in:ROOT]
  [gr:task-database eq $in:DATABASE]
)
where empty($tasks)
return in:admin(
  'group-add-scheduled-task',
  ($in:GROUP,
    admin:group-minutely-scheduled-task(
      $PATH, $in:ROOT, $INTERVAL,
      $in:DATABASE, $in:MODULES, $in:USER, $in:HOST))),
in:save()

(: install-task.xqy :)