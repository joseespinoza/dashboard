xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)
declare namespace l="http://www.w3.org/2005/xquery-local-functions";

import module namespace admin="http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";
import module namespace in="http://marklogic.com/performance/dashboard/install"
 at "lib-install.xqy";
import module namespace v="http://marklogic.com/performance/dashboard/view"
  at "lib-view.xqy";

declare variable $PD-NS := namespace-uri(<pd:x/>)
;

declare function l:database()
 as empty-sequence()
{
  in:forest-create(),
  in:database-create(),

  (: keep the in-memory stands small :)
  in:database-set('in-memory-list-size', 1),
  in:database-set('in-memory-tree-size', 1),
  in:database-set('in-memory-range-index-size', 1),
  in:database-set('in-memory-reverse-index-size', 1),

  (: avoid creating directory and property fragments :)
  in:database-set('directory-creation', 'manual'),
  in:database-set('maintain-last-modified', false()),
  in:database-set('expunge-locks', 'none'),

  (: scalar indexes :)
  in:database-set('uri-lexicon', true()),
  in:database-add(
    'range-element-attribute-index',
    admin:database-range-element-attribute-index(
      'dateTime', $PD-NS, 'status', '', 'current-time', '', false() ) ),

  (: ready :)
  in:database-attach-forests()
};

declare function l:scheduler()
 as empty-sequence()
{
  (: make sure we have saved any pending work :)
  in:save(),
  (: add scheduled task, every 10 minutes like sysstat sa1 :)
  (: TODO still throws USERDNE on first call - odd :)
  in:invoke(
    'install-task.xqy', (
      xs:QName('INTERVAL'), 10,
      xs:QName('NAME'), $in:NAME,
      xs:QName('PATH'), '/sample.xqy' ) )
};

declare function l:security()
 as empty-sequence()
{
  l:security(())
};

declare function l:security(
  $last-ex as element(error:error)? )
 as empty-sequence()
{
  (: create users and roles - recursively! :)
  let $ex as element(error:error)? := in:invoke('install-security.xqy', ())
  (: We want to terminate recursion if an error is repeated.
   : It isn't safe to rely on error:code, eg ROLEDNE may repeat.
   : So we need to be slightly clever.
   :)
  let $ex := if (empty($ex)) then () else element { node-name($ex) } {
    $ex/error:code,
    $ex/error:datum
  }
  where $ex
  return (
    if (not(deep-equal($ex, $last-ex))) then (
      xdmp:sleep(1000), l:security() )
    else error((), 'INSTALL-SECURITY', text {
        'The security install script threw an error:',
        normalize-space(xdmp:quote($ex)) })
  )
};

declare function l:server()
 as empty-sequence()
{
  (: TODO app server :)
};

declare function l:install()
 as item()*
{
  xdmp:set($in:NAME, $pd:NAME),
  l:database(),
  l:security(),
  l:server(),
  l:scheduler(),
  in:save()
};

v:page(
  element v:page {
    element v:title { 'Install' },
    element v:head { },
    element v:body {
      <div xmlns="http://www.w3.org/1999/xhtml">
      {
        for $message in l:install()
        return element div { $message }
      }
      </div> } } )

(: install.xqy :)
