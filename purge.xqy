xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";
import module namespace v="http://marklogic.com/performance/dashboard/view"
 at "lib-view.xqy";

declare variable $DAYS as xs:integer? :=
  xs:integer(xdmp:get-request-field('days')[. castable as xs:integer])
;

v:page(
  element v:page {
    element v:title { 'Purge' },
    element v:head { },
    element v:body {
      if ($DAYS) then
      <div xmlns="http://www.w3.org/1999/xhtml">
      {
        let $dt := $pd:NOW - xs:dayTimeDuration(concat('P', $DAYS, 'D'))
        let $result := pd:purge-by-dateTime($dt)
        let $jobs := $result[1]
        let $count := $result[2]
        return element div {
          if ($count eq 0) then "Nothing to purge."
          else element div {
            element p {
              if ($jobs eq 1) then "Purged" else "Purging",
              $count,
              'samples older than', $dt },
            if ($jobs eq 1) then ()
            else element p {
              "This may take some time to complete." }
          }
        }
      }
      </div>
      else
      <form xmlns="http://www.w3.org/1999/xhtml" method="POST">
      {
        element p { 'Found', xdmp:estimate(/pd:status), 'samples.' },
        (: bucket list of sample dates :)
        element ul {
          for $v at $x in reverse(pd:sample-value-ranges())
          let $age-min := $pd:NOW - $v/cts:maximum
          let $age-max := $pd:NOW - $v/cts:minimum
          return element li {
            cts:frequency($v),
            if ($x eq 1) then (
              'less than', v:duration-to-string($age-max, 1), 'old')
            else (
              'over', v:duration-to-string($age-min, 1), 'old')
          }
        }
      }
        <p>
      Purge samples older than
      <input name="days" type="text" value="" size="3" class="integer"/>
      days. This cannot be undone!
        </p>
        <input type="submit" value="purge"/>
      </form> } } )

(: purge.xqy :)