xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace l="http://www.w3.org/2005/xquery-local-functions";

import module namespace admin="http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";
import module namespace in="http://marklogic.com/performance/dashboard/install"
 at "lib-install.xqy";
import module namespace v="http://marklogic.com/performance/dashboard/view"
  at "lib-view.xqy";

declare function l:database()
 as empty-sequence()
{
  in:database-delete(),
  in:forest-delete()
};

declare function l:scheduler()
 as empty-sequence()
{
  (: remove scheduled task :)
  let $tasks := (
    admin:group-get-scheduled-tasks($in:CONFIG, $in:GROUP)
    [gr:task-path eq '/sample.xqy']
    [gr:task-root eq $in:ROOT]
    [gr:task-database eq $in:DATABASE]
  )
  where $tasks
  return in:admin('group-delete-scheduled-task', ($in:GROUP, $tasks))
};

declare function l:security()
 as empty-sequence()
{
  (: delete users and roles - recursively! :)
  if (empty(in:invoke('uninstall-security.xqy', ()))) then ()
  else (xdmp:sleep(1000), l:security())
};

declare function l:server()
 as empty-sequence()
{
  (: TODO app server :)
};

declare function l:uninstall()
 as item()*
{
  in:name-set($pd:NAME),
  l:scheduler(),
  l:server(),
  l:database(),
  l:security(),
  in:save()
};

v:page(
  element v:page {
    element v:title { 'Uninstall' },
    element v:head { },
    element v:body {
      <div xmlns="http://www.w3.org/1999/xhtml">
      {
        for $message in l:uninstall()
        return element div { $message }
      }
      </div> } } )

(: uninstall.xqy :)