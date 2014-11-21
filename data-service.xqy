xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace ss="http://marklogic.com/xdmp/status/server";

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";
import module namespace v="http://marklogic.com/performance/dashboard/view"
 at "lib-view.xqy";

declare variable $MULTIPLE-HOSTS := count(xdmp:hosts()) gt 1
;

declare variable $RESULTS := map:map()
;

(: default empty to work with form checkboxes :)
declare variable $TAGS as xs:string* := xdmp:get-request-field('tag')
;

declare variable $MAP :=
<map>
  <forest>
    <value tag="merge-count">$status/pd:merge-count</value>
    <value tag="stand-count">$status/pd:stand-count</value>
    <value tag="memory-space">$status/pd:memory-size-sum</value>
    <value tag="disk-space">$status/pd:disk-size-sum</value>
    <value tag="free-space">$status/fs:device-space</value>
  </forest>
  <host>
    <value tag="compressed-tree-cache-used">$status/pd:compressed-tree-cache-used-max</value>
    <value tag="expanded-tree-cache-used">$status/pd:expanded-tree-cache-used-max</value>
    <value tag="list-cache-used">$status/pd:list-cache-used-max</value>
    <value tag="merge-count-by-host">
let $id := $status/hs:host-id/data(.)
return sum($status/../pd:forest-status[fs:host-id eq $id]/pd:merge-count)
    </value>
  </host>
  <server>
    <value tag="threads">$status/ss:threads</value>
    <value tag="request-rate">$status/ss:request-rate</value>
  </server>
</map>
;

declare function local:push(
  $prefix as xs:string,
  $ts as xs:dateTime,
  $fn as element(),
  $status as element() )
as empty-sequence()
{
  if (not($pd:DEBUG)) then () else xdmp:log(text {
      'data-service.push:',
      $prefix, normalize-space(xdmp:quote($fn)) }),
  (: validate inputs :)
  if (exists($fn/@tag)) then () else error(
    (), 'DASHBOARD-INVALID',
    text { 'missing @tag in', xdmp:quote($fn) }),
  let $key := concat($prefix, $fn/@tag)
  (: Technically this should be in epoch ms - UTC.
   : However this is confusing so we use the server timezone.
   : The implicit timezone doesn't work properly,
   : so we have to concatenate it in.
   :)
  let $epoch-ms := (
    round(
      1000 * (
        ($ts - xs:dateTime("1970-01-01T00:00:00-00:00") + implicit-timezone())
        div $pd:DURATION-1S ) ) )
  let $value := data(
    typeswitch($fn)
    case element(function) return xdmp:apply(
      xdmp:function(xs:QName(concat('local:', $fn/@name))),
      $status)
    case element(value) return xdmp:value($fn)
    default return error((), 'DASHBOARD-UNIMPLEMENTED', name($fn))
  )
  return map:put(
    $RESULTS,
    $key,
    (map:get($RESULTS, $key), xdmp:to-json((
          $epoch-ms, if ($value) then $value else 0 )) ) )
};

declare function local:gather(
  $ts as xs:dateTime,
  $list as element()*,
  $type-qn as xs:QName,
  $name-qn as xs:QName+ )
as empty-sequence()
{
  let $is-server := ($type-qn eq xs:QName('server'))
  for $i in $list
  (: if server the prefix should be "host::server::" :)
  let $prefix := string-join(
    (if (not($is-server and $MULTIPLE-HOSTS)) then ()
      else xdmp:host-name($i/ss:host-id),
      (: If this is a server, it might be a task server.
       : So look for both server-name and server-kind.
       : But enforce existence of a name of some kind.
       :)
      ($i/*[node-name(.) = $name-qn])[1] cast as xs:string,
      ''),
    '::' )
  let $tags := $MAP/*[node-name(.) eq $type-qn]/*[@tag = $TAGS]
  return local:push($prefix, $ts, $tags, $i)
};

(: main :)
let $start := $pd:NOW - $pd:DURATION
let $gather := (
  for $data in /pd:status[@current-time ge $start]
  let $ts := xs:dateTime($data/@current-time)
  order by $data/@current-time ascending
  return (
    for $i in ('forest', 'host', 'server')
    let $status-qn := xs:QName(concat('pd:', $i, '-status'))
    let $status := $data/*[node-name(.) eq $status-qn]
    let $name-qn := xs:QName((
      if ($i eq 'server') then 'ss:server-kind' else (),
      concat(substring($i, 1, 1), 's:', $i, '-name') ))
    return local:gather($ts, $status, xs:QName($i), $name-qn)
  )
)
return (
  "[",
  string-join(
    for $k in map:keys($RESULTS)
    order by $k
    return
    text {
      "{ label:",
      xdmp:describe($k, 1, 256),
      ", data: [",
      string-join(map:get($RESULTS, $k), ','),
      "] }"
    },
    ','),
  "]"
)

(: data-service.xqy :)