xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

declare namespace xh = "http://www.w3.org/1999/xhtml";

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";
import module namespace v="http://marklogic.com/performance/dashboard/view"
 at "lib-view.xqy";
import module namespace x="http://marklogic.com/performance/dashboard/xquery"
 at "lib-xquery.xqy";

declare variable $TAGS as xs:string+ := (
  (: cannot use function mapping for default value? :)
  let $tag := xdmp:get-request-field('tag')
  return if (exists($tag)) then $tag else $pd:TAGS-DEFAULT
);

(: TODO use Aristo theme? :)

v:page(
  <v:page xmlns="http://www.w3.org/1999/xhtml">
  {
    <v:head>
      <script language="JavaScript" type="text/javascript"
  src="jquery-1.3.2.min.js">
      </script>
      <script language="JavaScript" type="text/javascript"
  src="jquery-flot-0.6.js">
      </script>
      <script language="JavaScript" type="text/javascript"
  src="jquery.ba-serializeobject.min.js">
      </script>
      <script language="JavaScript" type="text/javascript"
  src="dashboard.js">
      </script>
    </v:head>
    ,
    element v:body {
      <div>
      {
        (: form for data service parameters :)
        element form {
          attribute id { 'dashboard-parameters' },
          element p {
            'Displaying ',
            element span {
              attribute id { 'sample-count' },
              '0' },
            ' samples as of ',
            element span {
              attribute id { 'timestamp' } },
            ' (next update at ',
            element span {
              attribute id { 'refresh' } }, ')' },
          element table {
            attribute class { 'noborder' },
            element tr {
              attribute class { 'noborder' },
              element th {
                attribute class { 'noborder' },
                'Maximum Duration' },
              element td {
                attribute class { 'noborder' },
                element select {
                  attribute name { 'duration'},
                  for $d in $pd:DURATION-LIST
                  return element option {
                    if (not($pd:DURATION eq $d)) then ()
                    else attribute selected { 1 },
                    attribute value { $d },
                    v:duration-to-string($d) } } },
              element td {
                attribute class { 'noborder' },
                attribute rowspan { 2 },
                element div {
                  attribute id { 'dashboard-spinner' },
                  attribute class { 'spinner noborder' } } } },
            element tr {
              attribute class { 'noborder' },
              (: build tags as checkboxes from master list,
               : with defaults selected. Include shortcuts.
               :)
              element th {
                attribute class { 'noborder' },
                'Display' },
              element td {
                attribute class { 'noborder' },
                <a href="#" class="select-all">(all)</a>,
                ' | ',
                <a href="#" class="select-none">(none)</a>,
                <br/>,
                for $t in $pd:TAGS-ALL
                order by $t
                return element div {
                  $t,
                  element input {
                    attribute type { 'checkbox' },
                    if (not($t = $TAGS)) then ()
                    else attribute checked { 'checked' },
                    attribute name { 'tag' },
                    attribute value { $t } }
                }
              } } },
          element div {
            attribute id { 'dashboard-main' },
            element p {
              attribute id { 'message' },
              attribute class { 'warn' } } }
        }
      }
      </div> }
    }
    </v:page>
)

(: default.xqy :)