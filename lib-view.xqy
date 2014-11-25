xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

module namespace v="http://marklogic.com/performance/dashboard/view";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace x="http://marklogic.com/performance/dashboard/xquery"
 at "lib-xquery.xqy";

declare namespace xh = "http://www.w3.org/1999/xhtml";

declare variable $v:ACCEPT-XML as xs:boolean := (
  (: per Mary Holstege: Opera says that it accepts xhtml+xml,
   : but fails to handle it correctly.
  :)
  contains(xdmp:get-request-header('accept'), 'application/xhtml+xml')
  and not(contains(xdmp:get-request-header('user-agent'), 'Opera'))
);

declare variable $v:CONTENT-TYPE := (
  xdmp:set-response-content-type( concat(
      if ($v:ACCEPT-XML) then "application/xhtml+xml" else "text/html",
      "; charset=utf-8") )
);

declare variable $v:DOCTYPE-XHTML := (
  '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "DTD/xhtml1-transitional.dtd">'
);

declare variable $v:ELLIPSIS as xs:string := codepoints-to-string(8230);

declare variable $v:MICRO-SIGN as xs:string := codepoints-to-string(181);

declare variable $v:PROFILER-COLUMNS as element(columns) := (
  element columns {
    <column>location</column>,
    <column>expression</column>,
    <column>count</column>,
    element column {
      attribute title {
        "Time spent in the expression,",
        "not including time spent in sub-expressions." },
      'shallow-%' },
    element column {
      attribute title {
        "Time spent in the expression,",
        "not including time spent in sub-expressions." },
      concat('shallow-', $v:MICRO-SIGN, 's') },
    element column {
      attribute title {
        "Total time spent in the expression,",
        "including time spent in sub-expressions." },
      'deep-%' },
    element column {
      attribute title {
        "Total time spent in the expression,",
        "including time spent in sub-expressions." },
      concat('deep-', $v:MICRO-SIGN, 's') }
  }
);

declare function v:page($page as element(v:page) ) as item()+
{
  $v:CONTENT-TYPE,
  $v:DOCTYPE-XHTML,
  v:page-html($page)
};

declare function v:page-html(
  $page as element(v:page) )
as element(xh:html)
{
  (: assert :)
  if (exists($page/(v:head|v:body))) then ()
  else error(
    (), 'VIEW-EMPTY', text { normalize-space(xdmp:quote($page)) })
  ,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{
    string-join(('Dashboard', $page/v:title), ' - ') }</title>
      <link rel="stylesheet" type="text/css" href="dashboard.css">
      </link>
      { $page/v:head/node() }
    </head>
    <body>
  {
    $page/v:body/@*,
    element h1 {
      if ($page/v:title) then $page/v:title/string()
      else 'Dashboard' },
    $page/v:body/node(),
    $v:COPYRIGHT
  }
    </body>
  </html>
};

declare variable $v:COPYRIGHT := (
  <div xmlns="http://www.w3.org/1999/xhtml">
    <hr/>
    <p>
  Copyright &copy; 2009-2010 Mark Logic Corporation. All Rights Reserved.
    </p>
  </div>
);

declare function v:round-to-sigfig($i as xs:double)
 as xs:double
{
  if ($i eq 0) then 0
  else round-half-to-even(
    $i, xs:integer(2 - ceiling(math:log10(abs($i))))
  )
};

declare function v:format-profiler-report($report as element(prof:report))
  as element(xh:table)
{
  let $elapsed := data($report/prof:metadata/prof:overall-elapsed)
  return <table xmlns="http://www.w3.org/1999/xhtml">{
    attribute summary { "profiler report" },
    attribute class { "profiler-report sortable" },
    element caption {
      attribute class { "caption" },
      'Profiled',
      (sum($report/prof:histogram/prof:expression/prof:count), 0)[1],
      'expressions in', $elapsed },
    element tr {
      for $c in $v:PROFILER-COLUMNS/*
      return element th {
        attribute class {
          "profiler-report sortcol",
          if ($c eq "shallow-%") then "sortdesc" else ()
        },
        $c/@title, $c/text()
      }
    },
    let $size := 255
    let $max-line-length := string-length(string(max(
      $report/prof:histogram/prof:expression/prof:line)))
    (: NB - all elements should have line and expr-source,
     : but 3.2-1 sometimes produces different output.
     :)
    for $i in $report/prof:histogram/prof:expression
      [ prof:line ][ prof:expr-source ]
    order by $i/prof:shallow-time descending, $i/prof:deep-time descending
    return v:format-profiler-row($elapsed, $i, $size, $max-line-length)
  }</table>
};

declare function v:format-profiler-row(
  $elapsed as prof:execution-time, $i as element(prof:expression),
  $size as xs:integer, $max-line-length as xs:integer)
 as element(xh:tr) {
  let $shallow := data($i/prof:shallow-time)
  let $deep := data($i/prof:deep-time)
  let $uri := text {
    if (not(string($i/prof:uri)))
    then '.main'
    else if (starts-with($i/prof:uri, '/'))
    then substring-after($i/prof:uri, '/')
    else $i/prof:uri
  }
  return <tr xmlns="http://www.w3.org/1999/xhtml">{
    attribute class { "profiler-report" },
    element td {
      attribute class { "profiler-report row-title" },
      attribute nowrap { 1 },
      element code {
        element span { $uri, ': ' },
        element span {
          attribute class { "numeric" },
          attribute xml:space { "preserve" },
          x:lead-space(string($i/prof:line), $max-line-length) } } },
    element td {
        attribute class { "profiler-report expression" },
        element code {
          let $expr := substring(string($i/prof:expr-source), 1, 1 + $size)
          return
            if (string-length($expr) gt $size)
            then concat($expr, $v:ELLIPSIS)
            else $expr
        }
    },
    element td {
      attribute class { "profiler-report numeric" }, $i/prof:count },
    element td {
      attribute class { "profiler-report numeric" },
      if ($elapsed ne prof:execution-time('PT0S'))
      then v:round-to-sigfig(100 * $shallow div $elapsed)
      else '-'
    },
    element td {
      attribute class { "profiler-report numeric" },
      x:duration-to-microseconds($shallow)
    },
    element td {
      attribute class { "profiler-report numeric" },
      if ($elapsed ne prof:execution-time('PT0S'))
      then v:round-to-sigfig(100 * $deep div $elapsed)
      else '-'
    },
    element td {
      attribute class { "profiler-report numeric" },
      x:duration-to-microseconds($deep)
    }
  }</tr>
};

declare function v:duration-to-string(
  $d as xs:duration)
 as xs:string
{
  v:duration-to-string($d, ())
};

declare function v:duration-to-string(
  $d as xs:duration,
  $limit as xs:integer?)
 as xs:string
{
  let $list := (
    for $i in ('year', 'month', 'day', 'hour', 'minute')
    let $fn := xdmp:function(
      xs:QName(concat('fn:', $i, 's-from-duration')))
    let $v := xdmp:apply($fn, $d)
    where $v gt 0
    return string-join(
      (xs:string($v), ' ', $i, if ($v eq 1) then () else 's'),
      '')
  )
  return string-join(
    if ($limit) then $list[1 to $limit] else $list, ', ')
};

(: dashboard/lib-view.xqy :)