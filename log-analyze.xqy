xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)
declare namespace an="http://marklogic.com/xdmp/assignments";
declare namespace db="http://marklogic.com/xdmp/database";
declare namespace fs="http://marklogic.com/xdmp/status/forest";
declare namespace gr="http://marklogic.com/xdmp/group";
declare namespace ho="http://marklogic.com/xdmp/hosts";
declare namespace hs="http://marklogic.com/xdmp/status/host";
declare namespace xh="http://www.w3.org/1999/xhtml";

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";
import module namespace v="http://marklogic.com/performance/dashboard/view"
 at "lib-view.xqy";

declare variable $WARN := attribute class { 'warn' }
;

declare variable $PROFILE := xs:boolean(
  xdmp:get-request-field('profile', 'false'))
;

declare variable $BOUNDARY :=
'###########################################################################'
;

declare variable $SUPPORT := (
  if (xdmp:get-request-field('source') eq 'local') then (
    (: mimic support-request-go.xqy - not easy! :)
    for $i in xdmp:forest-status(xdmp:forests()) return document { $i },
    for $i in xdmp:forest-counts(xdmp:forests()) return document { $i },
    for $h in xdmp:hosts()
    let $hs := xdmp:host-status($h)
    return (
      document { $hs },
      for $id in $hs/(
        hs:http-server/hs:http-server-id
        |hs:xdbc-server/hs:xdbc-server-id
        |hs:task-server-id)
      return document { xdmp:server-status($h, $id) }
    ),
    (: fetch local config files :)
    for $i in ('assignments', 'databases', 'groups', 'hosts')
    return xdmp:read-cluster-config-file(concat($i, '.xml'))
    ,
    (: fetch local error log files :)
    for $p in xdmp:filesystem-directory(
      xdmp:filesystem-directory(
        xdmp:data-directory())/dir:entry[
        dir:type eq 'directory'][
        dir:filename eq 'Logs']/dir:pathname)/dir:entry[
      dir:type eq 'file'][
      matches(dir:filename, '^ErrorLog(_\d+)?\.txt')]/dir:pathname
    return xdmp:document-get($p)
    (: TODO fetch logs from remote servers :)
  )
  else (
    (: break the support log into sections,
     : so we can special-case the parsing if needed.
     :)
    for $tok in tokenize(
      typeswitch(xdmp:get-request-field('log'))
      case $n as binary() return xdmp:quote($n)
      default $n return $n,
      $BOUNDARY
    )
    return local:unquote($tok)
  )
)
;

declare variable $ASSIGNMENTS as element(an:assignment)* :=
  ($SUPPORT/an:assignments)[1]/an:assignment
;

declare variable $DATABASES as element(db:database)* :=
  ($SUPPORT/db:databases)[1]/db:database
;

declare variable $GROUPS as element(gr:group)* :=
  ($SUPPORT/gr:groups)[1]/gr:group
;

declare variable $HOSTS as element(ho:host)* :=
  ($SUPPORT/ho:hosts)[1]/ho:host
;

declare variable $HOST-STATUS as element(hs:host-status)* :=
  $SUPPORT/hs:host-status
;

declare variable $FOREST-COUNTS as element(fs:forest-counts)* :=
  $SUPPORT/fs:forest-counts
;

declare variable $FOREST-STATUS as element(fs:forest-status)* :=
  $SUPPORT/fs:forest-status
;

declare variable $SIZING as element(pd:sizing)* := (
  for $sizing in (
    for $database in $DATABASES
    let $forest-ids as xs:unsignedLong* := $database/db:forests/db:forest-id
    return pd:sizing(
      $forest-ids,
      $ASSIGNMENTS, $FOREST-STATUS, $FOREST-COUNTS,
      $database)
    ,
    (: also unattached but enabled forests :)
    let $assigned as xs:unsignedLong* := $DATABASES/db:forests/db:forest-id
    for $forest in $ASSIGNMENTS
    where xs:boolean($forest/an:enabled)
    and not($forest/an:forest-id = $assigned)
    return pd:sizing(
      $forest/an:forest-id,
      $ASSIGNMENTS, $FOREST-STATUS, $FOREST-COUNTS)
  )
  order by
    xs:integer($sizing/fs:in-memory-MB) descending,
    xs:integer($sizing/fs:fragments) descending,
    $sizing/@database-name,
    $sizing/@forest-name
  return $sizing
);

declare function local:unquote(
  $in as xs:string )
 as document-node()+
{
  try {
    xdmp:unquote($in, '', 'repair-full') }
  catch ($ex) {
    if ($ex/error:code ne 'XDMP-DOCSTARTTAGCHAR') then xdmp:rethrow()
    (: this is probably a log message with unescaped XML in it :)
    else xdmp:unquote(replace($in, '<', '&amp;lt;'), '', 'repair-full') }
};

declare function local:tr(
  $label as xs:string, $list as xs:anyAtomicType*)
 as element()
{
  <tr xmlns="http://www.w3.org/1999/xhtml">
  {
    element th { $label },
    local:td($list)
  }
  </tr>
};

declare function local:td($list as xs:anyAtomicType*)
 as element()*
{
  local:td($list, false())
};

declare function local:td(
  $list as xs:anyAtomicType*,
  $warn as xs:boolean)
 as element()*
{
  for $i in $list
  return <td xmlns="http://www.w3.org/1999/xhtml">
  {
    let $class := (
      if ($i castable as xs:integer) then 'integer' else (),
      if ($warn) then 'warn' else ()
    )
    where $class
    return attribute class { $class }
    ,
    $i
  }
  </td>
};

declare function local:warn-if($e as element())
{
  local:warn-if(
    $e,
    if (data($e) instance of xs:boolean) then true()
    else 'enabled'
  )
};

declare function local:warn-if($e as element(), $v as xs:anyAtomicType+)
  as xs:anyAtomicType*
{
  if ($e = $v) then (local-name($e), 'is', $v)
  else ()
};

declare function local:warn-unless(
  $e as element(), $v as xs:anyAtomicType+)
  as xs:anyAtomicType*
{
  if ($e = $v) then ()
  else (local-name($e), data($e), 'not', $v)
};

declare function local:warn-lt(
  $e as element(), $v as xs:anyAtomicType+)
  as xs:anyAtomicType*
{
  if ($e < $v) then (local-name($e), data($e), 'lt', $v)
  else ()
};

declare function local:warn-gt(
  $e as element(), $v as xs:anyAtomicType+)
  as xs:anyAtomicType*
{
  if ($e > $v) then (local-name($e), data($e), 'gt', $v)
  else ()
};

declare function local:html()
 as item()+
{
  if (not($PROFILE)) then () else prof:enable(xdmp:request()),
  (: html format :)
  v:page(
    <v:page xmlns="http://www.w3.org/1999/xhtml">
    {
      element v:title { 'Support Log Analysis' },
      <v:head>
        <script language="JavaScript" type="text/javascript"
      src="jquery-1.3.2.min.js">
        </script>
        <script language="JavaScript" type="text/javascript"
      src="log-analyze.js">
        </script>
        </v:head>,
      element v:body {
        <div>

          <h2>Host Summary</h2>
          <h3>MarkLogic Server versions
        {
          string-join(distinct-values($HOST-STATUS/hs:version), '; '),
          'on',
          string-join(distinct-values($HOST-STATUS/hs:architecture), '; ')
        }
          </h3>

    <table>
  <tr>
    <th>Host</th><th>Licensee</th><th>Key</th>
    <th>CPUs</th><th>Cores</th><th>Size / Limit</th>
    <th>Options</th>
  </tr>
  {
    for $i in $HOST-STATUS
    let $options := xdmp:quote($i/hs:license-key-options)
    let $clean-options := xdmp:unquote($options) (: xdmp:unquote(fn:replace($options, "flexible ", "")) :)
    order by $i/hs:host-name
    return element tr {
      local:td((
          $i/hs:host-name,
          $i/hs:licensee,
          $i/hs:license-key,
          $i/hs:license-key-cpus,
          $i/hs:license-key-cores,
          text {
            $i/hs:host-size,
            '/',
            $i/hs:license-key-size },
          string-join(
            ($i/hs:edition, $clean-options//hs:license-key-option), '; ') ))
    }
  }
    </table>

        <h2>Disk Space</h2>
        <h3>Private Directories</h3>
        {
    element table {
      element tr {
        element th { 'filesystem' },
        element th { 'available (MB)' } },
      (: host-status log-device-space, data-dir-space :)
      for $hs in $HOST-STATUS
      let $name as xs:string := $hs/hs:host-name
      let $log-free as xs:integer := $hs/hs:log-device-space
      let $data-free as xs:integer := $hs/hs:data-dir-space
      order by $name
      return (
        element tr {
          if ($log-free gt 1024) then () else $WARN,
          local:td(
            (concat($name, ' logs'), $log-free)) },
        element tr {
          if ($data-free gt 1024) then () else $WARN,
          local:td(
            (concat($name, ' data'), $data-free)) }
      )
    },
          <br class="verticalem"/>,
          <h3>Public Data Directories</h3>,
    element table {
      (: forest disk space :)
      element tr {
        element th { 'filesystem' },
        element th { 'used (MB)' },
        element th { 'free (MB)' },
        element th { '%-used' } },
      (: build a map of location, size, and free space :)
      let $map := map:map()
      let $build := (
        (: skip any unmounted or empty forests :)
        for $fs in $FOREST-STATUS[ fs:stands/fs:stand ]
        let $id as xs:unsignedLong := $fs/fs:forest-id
        let $free as xs:integer := $fs/fs:device-space
        let $size as xs:integer := sum(
          $fs/fs:stands/fs:stand/fs:disk-size)
        let $location as xs:string := ($fs/fs:stands/fs:stand/fs:path)[1]
        let $location as xs:string := string-join(
          (tokenize($location, '[/\\]')[1 to (last() - 3)]),
          '/')
        (: make sure the old value is non-empty :)
        let $old := (map:get($map, $location)[1], 0)[1]
        return map:put($map, $location, ($size + $old, $free))
      )
      for $path in map:keys($map)
      let $values := map:get($map, $path)
      let $used := round(100 * $values[1] div sum($values))
      order by $path
      return element tr {
        if ($used lt 33) then () else $WARN,
        local:td(($path, $values, $used)) }
    }
}

  <h2>Forest Status</h2>
  {
    let $errors := $FOREST-STATUS[ fs:error ]
    return (
      if (empty($errors)) then element p { 'No forest errors found.' }
      else (
        element table {
          element tr {
            element th { 'Forest' },
            element th { 'Host' },
            element th { 'Errors' } },
          for $fs in $errors
          (: a forest can be in an error state without a host, apparently :)
          let $host-id as xs:unsignedLong? := data($fs/fs:host-id)
          let $host-name := (
            if ($host-id) then $HOSTS[ ho:host-id eq $host-id]/ho:host-name
            else '(N/A)'
          )
          return element tr {
            $WARN,
            local:td(($fs/fs:forest-name, $host-name, $fs/fs:error))
          }
        }
      )
    )
  }

  <h2>Log Messages</h2>
  {
    let $pat := concat(
      '^\d\d\d\d\-\d\d-\d\d \d\d:\d\d:\d\d\.\d+ (',
      'Notice|Warning|Error|Critical|Alert|Emergency',
      '): '    )
    let $logs := $SUPPORT/text()/tokenize(., '[\n\r]+')[ matches(., $pat) ]
    return (
      if (empty($logs)) then element p { 'No problematic log messages found.' }
      else (
        for $j in $logs
        return element div { $j }
      )
    )
  }

    <h2>Memory Sizing</h2>
{
    (: TODO - check partition count vs CPU cores :)
    let $names := ('list', 'expanded-tree', 'compressed-tree')
    return element table {
      for $i in (
        'host',
        'group',
        for $j in $names
        return (
          concat($j, ' cache (MB)'),
          'partitions', '%-used', '%-busy'
        ),
        'total cache (MB)',
        'forests',
        'forest memory (MB)',
        'total (MB)'
      )
      return element th { $i }
      ,
      let $assignments-now := $HOST-STATUS[1]/hs:assignments/hs:assignment
      for $h in $HOST-STATUS
      let $id as xs:unsignedLong := $h/hs:host-id
      let $group-id as xs:unsignedLong := $h/hs:group-id
      let $group as xs:string := $GROUPS[
        gr:group-id eq $group-id]/gr:group-name
      let $cache-total := sum($h/*/*/hs:partition-size)
      let $forest-ids as xs:unsignedLong* := $assignments-now[
        hs:host-id eq $id ]/hs:forest-id
      (: per-host forest memory, including in-memory stands :)
      let $forests := $FOREST-STATUS[ fs:forest-id = $forest-ids ]
      let $forest-mem := $forests/fs:stands/fs:stand/fs:memory-size
      let $forest-mem := sum($forest-mem)
      order by $group, $h/hs:host-name
      return element tr {
        let $values := (
          for $j in $names
          let $name := concat('hs:', $j, '-cache-partition')
          let $qname := xs:QName($name)
          let $p := $h/*/*[node-name(.) eq $qname]
          let $partition-busy := (
            if ($p/hs:partition-busy) then round(max($p/hs:partition-busy))
            else ''
          )
          return (
            sum($p/hs:partition-size),
            count($p/hs:partition-size),
            round(max($p/hs:partition-used)),
            $partition-busy
          )
        )
        return (
          local:td((
              $h/hs:host-name,
              $group,
              $values[1 to 3])),
          (: check %-busy for list :)
          local:td($values[4], $values[4] gt 25),
          local:td($values[5 to 7]),
          (: check %-busy for expanded tree :)
          local:td($values[8], $values[8] gt 25),
          local:td((
              $values[9 to last()],
              $cache-total,
              count($forest-ids),
              $forest-mem,
              sum(($cache-total, $forest-mem)) ))
        )
      }
    }
    ,
    element h3 {
      'Total forest memory (on-disk stands):',
      sum($SIZING/pd:in-memory-MB),
      'MB'
    },
    <hr/>
    ,
          <h2>Forest Details</h2>,
    for $i in $SIZING
    let $is-forest := exists($i/@forest-name)
    return element div {
      element h3 {
        if ($is-forest) then text {
          $i/@forest-name, '(unassigned forest)' }
        else text { $i/@database-name } },
      element table {
        if ($is-forest) then ()
        else local:tr('forests', $i/@forest-count),
        local:tr(
          'stands',
          $i/@stand-count),
        local:tr(
          'stands on disk',
          $i/@stand-count-on-disk),
        local:tr(
          'documents',
          $i/pd:documents),
        local:tr(
          'fragments',
          $i/pd:fragments),
        local:tr(
          'MB in memory',
          $i/pd:in-memory-MB),
        local:tr(
          'Memory B/fragment',
          round($i/pd:in-memory-B-per-fragment)),
        if ($is-forest) then ()
        else local:tr(
          'Memory-mapped indexes and lexicons',
          $i/pd:memory-indexes),
        local:tr(
          'MB on disk',
          $i/pd:on-disk-MB),
        local:tr(
          'Disk B/fragment',
          round($i/pd:on-disk-B-per-fragment)),
        if ($is-forest) then ()
        else element tr {
          element th { 'Full-text indexes' },
          element td {
            element b { 'enabled: ' },
            xs:string($i/pd:full-text/pd:enabled),
            <br class="verticalem"/>,
            element b { 'disabled: ' },
            xs:string($i/pd:full-text/pd:disabled) } },
        (: warnings - database config etc :)
        for $e in $DATABASES[db:database-id eq $i/@database-id]/*
        let $warn := (
          typeswitch($e)
          case element(db:directory-creation)
          return local:warn-if($e, 'automatic')
          case element(db:maintain-last-modified)
          return local:warn-if($e)
          case element(db:maintain-directory-last-modified)
          return local:warn-if($e)
          (: TODO show CPF details if available :)
          case element(db:triggers-database)
          return local:warn-unless($e, 0)
          case element(db:in-memory-list-size)
          return local:warn-gt($e, 512)
          case element(db:in-memory-tree-size)
          return local:warn-gt($e, 128)
          case element(db:in-memory-range-index-size)
          return local:warn-gt($e, 16)
          case element(db:in-memory-reverse-index-size)
          return local:warn-gt($e, 16)
          case element(db:in-memory-journal-size)
          return local:warn-lt($e, 1024)
          default return ()
        )
        where $warn
        return element tr {
          element td {
            attribute colspan { 2 },
            $WARN,
            $warn
          }
        }
      }
    }
  }
  
        <code>
        {'digraph{
        rankdir=LR; ranksep=1.5;
        node [shape=box];',
        	for $group at $i in $GROUPS
        	return
        	(
        		fn:concat('subgraph cluster', $i, ' {'),
        		fn:concat('label="', $group/gr:group-name, '";'),
        		fn:concat('color=lightgrey;style=filled;'),
        		let $domain := fn:concat(".", fn:substring-after($HOSTS[1]//ho:host-name, '.'))
        		let $hosts := fn:string-join($HOSTS[./ho:group eq $group/gr:group-id]/ho:host-name/text(), '";"host: ')
        		let $hostnames := fn:replace($hosts, $domain, '')
        		return
        			fn:concat('"host: ', $hostnames, '"')
        		,'}'
        	)
        ,'node [shape=box,height=1.0];',
        	for $host in $HOSTS
        	let $forests := $ASSIGNMENTS[./an:host eq $host/ho:host-id]/an:forest-name
        	return
        		let $head := fn:concat('"host: ', fn:substring-before($host/ho:host-name, '.'), '"', '->"')
        		for $forest in $forests
        		return
	        		fn:concat($head, 'forest: ', $forest, '"', ';')
	 ,'node [shape=circle,height=1.0];',
        	for $db in $DATABASES
        	let $forests := for $fid in $db//db:forest-id return $FOREST-STATUS[./fs:forest-id/text() = $fid/text()]/fs:forest-name
        	return
        		let $head := fn:concat('"db: ', $db/db:database-name, '"')
        		for $forest in $forests
        		return
	        		fn:concat('"forest: ', $forest,'"', '->', $head, '[dir="back"];')
	 ,'node [shape=doublecircle,height=1.0];',
        	for $group in $GROUPS
        	let $servers := $group//gr:http-server | $group//gr:xdbc-server
        	return
        		for $server in $servers
        		let $node-name := fn:concat(fn:node-name($server), "-name")
        		let $server-name := fn:concat('"', fn:node-name($server), ': ', $server//child::element()[fn:node-name(.) eq QName("http://marklogic.com/xdmp/group", $node-name)], '"')
        		let $mod-db := if (fn:string($server//gr:database) = "0") then ($server//gr:modules) else ($server//gr:database)
        		let $db := fn:concat('"db: ', $DATABASES//db:database-name[../db:database-id = $mod-db], '"')
        		return
	        		fn:concat($db, '->', $server-name, '[label="', $group/gr:group-name, '",dir="back"];')
	 ,
	 '{
        node [shape=plaintext, fontsize=16];
        "cluster_hosts" -> forests -> databases -> "app_servers"[dir="none"];
        }}'
        }
        </code>
        <hr/>
        <p>Elapsed time: { xdmp:elapsed-time() }</p>
        {
          if (not($PROFILE)) then ()
          else v:format-profiler-report(prof:report(xdmp:request()))
        }
        </div>
      }
    }
    </v:page>
  )
};

(: display form for upload :)
if (empty($SUPPORT)) then v:page(
  <v:page xmlns="http://www.w3.org/1999/xhtml">
  {
    element v:body {
      <form method="post" enctype="multipart/form-data">
      {
        attribute action { xdmp:get-request-path() }
      }
      <p>Upload a support log for analysis.</p>
      <input type="file" name="log" accept="text/*"/>
      <input type="submit" value="go"/>
      </form>
    }
  }
  </v:page>
)
else if ('xml' eq xdmp:get-request-field('format', 'html'))
then element report { $SIZING }
else local:html()

(: log-analyze.xqy :)
