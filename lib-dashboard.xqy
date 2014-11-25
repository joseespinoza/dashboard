xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

module namespace pd="http://marklogic.com/performance/dashboard";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: must import anything used by lambda functions :)
import module namespace admin="http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";
import module "http://marklogic.com/xdmp/security"
  at "/MarkLogic/security.xqy";

declare namespace an="http://marklogic.com/xdmp/assignments";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace ss="http://marklogic.com/xdmp/status/server";

declare variable $pd:DEBUG as xs:boolean := xs:boolean(
  xdmp:get-request-field('debug', '0')
);

declare variable $pd:DURATION as xs:duration := (
  let $v := xdmp:get-request-field('duration', 'PT24H')
  return try {
    xs:dayTimeDuration($v) }
  catch ($ex) {
    xs:yearMonthDuration($v) }
);

declare variable $pd:DURATION-1S := xs:dayTimeDuration('PT1S')
;

declare variable $pd:DURATION-LIST := (
  for $v in (
    'PT1H', 'PT3H', 'PT6H', 'PT12H',
    'P1D', 'P3D', 'P7D', 'P15D',
    'P1M', 'P3M', 'P6M',
    'P1Y'
  )
  return (
    if (contains($v, 'T')) then xs:dayTimeDuration($v)
    else if (contains($v, 'D')) then xs:dayTimeDuration($v)
    else xs:yearMonthDuration($v)
  )
);

declare variable $pd:NAME := 'Dashboard'
;

(: this enables a now() setter for test purposes :)
declare variable $pd:NOW := current-dateTime()
;

declare variable $pd:ROLENAME := lower-case($pd:NAME)
;

declare variable $pd:ROLENAME-READ := concat($pd:ROLENAME, '-read')
;

declare variable $pd:TAGS-ALL as xs:string+ := (
  'merge-count', 'merge-count-by-host', 'stand-count',
  'free-space', 'disk-space', 'memory-space',
  'compressed-tree-cache-used',
  'expanded-tree-cache-used',
  'list-cache-used',
  'threads', 'request-rate'
);

declare variable $pd:TAGS-DEFAULT as xs:string+ := (
  'merge-count-by-host', 'stand-count',
  'free-space', 'disk-space', 'memory-space',
  'threads', 'request-rate'
);

declare variable $pd:URI-PREFIX := '/sample/'
;

declare variable $pd:USERNAME := $pd:ROLENAME
;

declare function pd:lambda(
  $fn as xs:QName,
  $args as item()* )
 as item()*
{
  pd:lambda($fn, $args, 0)
};

declare function pd:lambda(
  $fn as xs:QName,
  $args as item()*,
  $empty as xs:integer )
 as item()*
{
  let $lambda := xdmp:function($fn)
  let $count := count($args) + $empty
  return (
    (: this is the ugly part :)
    if ($count eq 0) then xdmp:apply(
      $lambda)
    else if ($count eq 1) then xdmp:apply(
      $lambda,
      $args[1])
    else if ($count eq 2) then xdmp:apply(
      $lambda,
      $args[1], $args[2])
    else if ($count eq 3) then xdmp:apply(
      $lambda,
      $args[1], $args[2], $args[3])
    else if ($count eq 4) then xdmp:apply(
      $lambda,
      $args[1], $args[2], $args[3], $args[4])
    else if ($count eq 5) then xdmp:apply(
      $lambda,
      $args[1], $args[2], $args[3], $args[4], $args[5])
    else if ($count eq 6) then xdmp:apply(
      $lambda,
      $args[1], $args[2], $args[3], $args[4], $args[5], $args[6])
    else error(
      (), 'LAMBDA-UNIMPLEMENTED', text { $count, $fn, $args })
  )
};

declare function pd:sizing(
  $forest-ids as xs:unsignedLong*,
  $assignments as element(an:assignment)*,
  $forest-status as element(fs:forest-status)*,
  $forest-counts as element(fs:forest-counts)*)
 as element(pd:sizing)
{
  pd:sizing($forest-ids, $assignments, $forest-status, $forest-counts, ())
};

declare function pd:sizing(
  $forest-ids as xs:unsignedLong*,
  $assignments as element(an:assignment)*,
  $forest-status as element(fs:forest-status)*,
  $forest-counts as element(fs:forest-counts)*,
  $database as element(db:database)?)
 as element(pd:sizing)
{
  let $forest-counts := $forest-counts[ fs:forest-id = $forest-ids ]
  let $forest-status := $forest-status[ fs:forest-id = $forest-ids ]
  let $docs := sum($forest-counts/fs:document-count)
  let $stand-count := count($forest-status/fs:stands/fs:stand)
  (: NB - on-disk stands only :)
  let $stand-ids := data(
    $forest-status/fs:stands/fs:stand[ fs:disk-size ge fs:memory-size ]
    /fs:stand-id)
  let $stand-counts := $forest-counts/fs:stands-counts/fs:stand-counts[
    fs:stand-id = $stand-ids ]
  let $stand-status := $forest-status/fs:stands/fs:stand[
    fs:stand-id = $stand-ids ]
  let $fragments := sum(
    $stand-counts/(
      fs:active-fragment-count|fs:nascent-fragment-count
      |fs:deleted-fragment-count))
  (: workaround for 7020 :)
  let $in-memory := sum($stand-status/fs:memory-size)
  let $on-disk := sum($stand-status/fs:disk-size)
  return <sizing xmlns="http://marklogic.com/performance/dashboard">{
    if (empty($database)) then (
      attribute forest-name {
        $assignments[ an:forest-id eq $forest-ids ]/an:forest-name }
    )
    else (
      attribute database-id { $database/db:database-id },
      attribute database-name { $database/db:database-name }
    ),
    attribute forest-count { count($forest-ids) },
    attribute stand-count { $stand-count },
    attribute stand-count-on-disk { count($stand-ids) },
    element documents { $docs },
    element fragments { $fragments },
    element in-memory-MB { $in-memory },
    element in-memory-B-per-fragment {
      if ($fragments) then (1024 * 1024 * $in-memory div $fragments)
      else 0
    },
    element on-disk-MB { $on-disk },
    element on-disk-B-per-fragment {
      if ($fragments) then (1024 * 1024 * $on-disk div $fragments)
      else 0
    },
    if (empty($database)) then () else (
      let $full-text := $database/*[matches(
          local-name(.), '(positions|searches)$')]
      return element full-text {
        element enabled {
          for $i in $full-text
          let $is-bool := $i castable as xs:boolean
          let $alias := replace(
            replace(local-name($i), '^fast-', ''), '-searches$', '')
          where ($is-bool and xs:boolean($i)) or not($is-bool)
          order by
            $is-bool,
            matches($alias, 'character|wildcard'),
            matches($alias, 'positions'),
            $alias
          return (
            if ($is-bool) then $alias
            (: explicit cast in case of an older schema :)
            else string-join(($alias, string($i)), '=')
          )
        },
        element disabled {
          for $i in $full-text
          let $alias := replace(
            replace(local-name($i), '^fast-', ''), '-searches$', '')
          where $i castable as xs:boolean and not(xs:boolean($i))
          order by
            matches($alias, 'character|wildcard'),
            matches($alias, 'positions'),
            $alias
          return $alias
        }
      },
      element memory-indexes {
        sum((
            count(
              $database/(db:uri-lexicon|db:collection-lexicon)[. eq true()]),
            count($database/db:word-lexicons/*),
            (: accounting for element-attribute pairs can be tricky :)
            for $i in $database/(
              db:range-element-indexes|db:range-element-attribute-indexes
              |db:element-word-lexicons|db:element-attribute-word-lexicons
              )/*
            let $ln := count(data($i/db:localname))
            let $pn :=
            if (not($i/db:parent-localname)) then 1
            else count(data($i/db:parent-localname))
            return $ln * $pn
            ))
      }
    )
    }</sizing>
};

declare function pd:sample-smma(
  $label as xs:string,
  $list as xs:double* )
 as element()+
{
  for $i in ('sum', 'min', 'max', 'avg')
  let $name := concat('pd:', $label, '-', $i)
  let $fn := xdmp:function(xs:QName(concat('fn:', $i)))
  return element { $name } { xdmp:apply($fn, $list) }
};

declare function pd:age-in-seconds(
  $dt as xs:dateTime )
 as xs:double
{
  ($pd:NOW - $dt)
  div $pd:DURATION-1S
};

declare function pd:forest-count(
  $label as xs:string,
  $current-size as xs:boolean,
  $final-size as xs:boolean,
  $age as xs:boolean,
  $list as element()* )
 as element()*
{
  element { concat('pd:', $label, '-count') } {
    count($list) },
  if (not($current-size)) then ()
  else pd:sample-smma(
    concat($label, '-current-size'), $list/fs:current-size),
  if (not($final-size)) then ()
  else pd:sample-smma(
    concat($label, '-final-size'), $list/fs:final-size),
  if (not($age)) then ()
  else pd:sample-smma(
    concat($label, '-seconds'), pd:age-in-seconds($list/fs:start-time))
};

declare function pd:forest-count(
  $label as xs:string,
  $list as element()* )
 as element()*
{
  pd:forest-count($label, true(), true(), true(), $list)
};

declare function pd:forest(
  $e as element() )
 as element()*
{
  let $list := $e/*
  return typeswitch($e)
  case element(fs:backups) return pd:forest-count('backup', $list)
  case element(fs:merges) return (
    pd:forest-count('merge', $list),
    pd:sample-smma('merge-rate', $list/fs:merge-rate),
    pd:sample-smma(
      'merge-input-stand-count', $list/count(fs:input-stands/fs:stand-id) )
  )
  case element(fs:restore) return pd:forest-count('restore', $list)
  case element(fs:stands) return (
    element pd:stand-count { count($list) },
    pd:sample-smma('disk-size', $list/fs:disk-size),
    pd:sample-smma('memory-size', $list/fs:memory-size),
    pd:sample-smma('list-cache-hit-rate', $list/fs:list-cache-hit-rate),
    pd:sample-smma('tree-cache-hit-rate', $list/fs:list-cache-hit-rate)
  )
  case element(fs:transaction-coordinators) return pd:forest-count(
    'transaction-coordinators', 0, 0, 0, $list)
  case element(fs:transaction-participants) return pd:forest-count(
    'transaction-participants', 0, 0, 0, $list)
  default return error(
    (), 'DASHBOARD-UNEXPECTED', text {
      normalize-space(xdmp:quote($e)) })
};

declare function pd:server(
  $e as element() )
 as element()*
{
  let $list := $e/*
  return typeswitch($e)
  case element(ss:request-statuses) return (
    element pd:request-count { count($list) },
    element pd:update-count { count($list/ss:update[data(.)]) },
    pd:sample-smma('request-seconds', pd:age-in-seconds($list/ss:start-time))
  )
  default return error(
    (), 'DASHBOARD-UNEXPECTED', text {
      normalize-space(xdmp:quote($e)) })
};

declare function pd:host-count(
  $label as xs:string,
  $forest-count as xs:boolean,
  $age as xs:boolean,
  $list as element()* )
 as element()*
{
  element { concat('pd:', $label, '-count') } {
    count($list) },
  if (not($forest-count)) then ()
  else element { concat('pd:', $label, '-forest-count') } {
    count($list/hs:forests/hs:forest) },
  if (not($age)) then ()
  else pd:sample-smma(
    concat($label, '-seconds'), pd:age-in-seconds($list/hs:start-time))
};

declare function pd:host-count(
  $label as xs:string,
  $list as element()* )
 as element()*
{
  pd:host-count($label, true(), true(), $list)
};

declare function pd:host(
  $e as element() )
 as element()*
{
  let $host-id as xs:unsignedLong := $e/../hs:host-id
  let $list := $e/*
  return typeswitch($e)
  case element(hs:assignments) return element pd:forest-count {
    count($list) }
  (: TODO - bucket by status? cf 10429 :)
  case element(hs:backup-jobs) return pd:host-count(
    'backup-jobs', $list)
  case element(hs:compressed-tree-cache-partitions) return pd:sample-smma(
    'compressed-tree-cache-used', $list/hs:partition-used )
  case element(hs:config-file-timestamps) return ()
  case element(hs:expanded-tree-cache-partitions) return pd:sample-smma(
    'expanded-tree-cache-used', $list/hs:partition-used )
  case element(hs:http-servers) return pd:sample(
    'server', 'server', xdmp:server-status(
      $e/../hs:host-id, $e/hs:http-server/hs:http-server-id) )
  case element(hs:hosts) return ()
  case element(hs:license-key-options) return ()
  case element(hs:list-cache-partitions) return pd:sample-smma(
    'list-cache-used', $list/hs:partition-used )
  case element(hs:restore-jobs) return pd:host-count(
    'restore-jobs', $list)
  case element(hs:task-server) return pd:sample(
    'server', 'server', xdmp:server-status(
      $e/../hs:host-id, $e/hs:task-server-id) )
  case element(hs:xdbc-servers) return pd:sample(
    'server', 'server', xdmp:server-status(
      $e/../hs:host-id, $e/hs:xdbc-server/hs:xdbc-server-id) )
  default return error(
    (), 'DASHBOARD-UNEXPECTED', text {
      normalize-space(xdmp:quote($e)) })
};

declare function pd:sample(
  $label as xs:string,
  $name as xs:string,
  $status as element() )
 as element()+
{
    (: simple values pass through unchanged,
     : and stay in the forest-status namespace.
     :)
  let $simple := $status/*[empty(*)][exists(text())]
  (: complex values are handled via callback :)
  let $complex := xdmp:apply(
    xdmp:function(xs:QName(concat('pd:', $name))), $status/*[exists(*)] )
  return (
    element { concat('pd:', $label, '-status') } {
      $simple, $complex[empty(*)] },
    $complex[exists(*)]
  )
};

declare function pd:sample()
 as element(pd:status)
{
  element pd:status {
    attribute current-time { $pd:NOW },
    pd:sample('host', 'host', xdmp:host-status(xdmp:hosts())),
    pd:sample('forest', 'forest', xdmp:forest-status(xdmp:forests()))
  }
};

declare function pd:rollup-serialize(
  $m as map:map )
 as element()*
{
  for $k in map:keys($m)
  let $v := map:get($m, $k)
  let $qn := tokenize($k, '\s+')
  let $qn := QName($qn[1], $qn[2])
  order by $k
  return element { $qn } {
    attribute min { min($v) },
    attribute max { max($v) },
    attribute sum-of-squares { sum(for $i in $v return $i * $i) },
    avg($v)
  }
};

declare function pd:rollup(
  $list as element(pd:status)+)
 as element(pd:status)
{
  let $m := map:map()
  let $gather := (
    for $i in ('forest', 'host', 'server')
    return map:put($m, $i, map:map())
    ,
    for $status in $list/*
    let $m as map:map := map:get(
      $m, substring-before(local-name($status), '-status') )
    for $e in $status/*[. castable as xs:double]
    let $k := string-join((namespace-uri($e), name($e)), ' ')
    return map:put($m, $k, (map:get($m, $k), xs:double($e)))
  )
  let $times := xs:dateTime($list/@current-time)
  let $start := min($times)
  let $end := max($times)
  let $duration := ($end - $start)
  let $center := $start + $duration div 2
  return element pd:status {
    attribute current-time { $center },
    attribute duration { $duration },
    attribute start-time { $start },
    attribute end-time { $end },
    for $i in ('forest', 'host', 'server')
    let $mi := map:map()
    return element { concat('pd:', $i, '-status') } {
        pd:rollup-serialize(map:get($m, $i))
    }
  }
};

(: enable setting different times of day, for test purposes :)
declare function pd:now(
  $dt as xs:dateTime )
as empty-sequence()
{
  xdmp:set($pd:NOW, $dt)
};

declare function pd:purge-by-dateTime(
  $dt as xs:dateTime )
as xs:integer+
{
  let $limit := 10000
  let $uris := cts:uris(
    (), (), cts:element-attribute-range-query(
      xs:QName('pd:status'), xs:QName('current-time'), '<', $dt ) )
  let $count := count($uris)
  let $size := ceiling($count div $limit)
  let $do := (
    if ($size eq 1) then xdmp:document-delete($uris)
    else (
      for $i in 1 to $size
      let $m := map:map()
      let $do := map:put(
        $m, subsequence($uris, 1 + ($i - 1) * $limit, $limit), true() )
      return xdmp:spawn('document-delete.xqy', (xs:QName('URIS'), $m))
    )
  )
  (: is the purge done? else in progress :)
  return ($size, $count)
};

declare function pd:sample-value-ranges()
as element(cts:range)*
{
  let $bounds := $pd:NOW - reverse($pd:DURATION-LIST)
  return cts:element-attribute-value-ranges(
    xs:QName('pd:status'), xs:QName('current-time'), $bounds
  )
};

(: TODO purge task and policy document? :)

(: TODO pd:status schema? :)

(: lib-dashboard.xqy :)
