xquery version "0.9-ml"
(:
 : Copyright (c) 2008-2010 Mark Logic Corporation. All Rights Reserved.
 :
 :)
module "http://marklogic.com/performance/dashboard/xquery"

default function namespace = "http://www.w3.org/2003/05/xpath-functions"

declare namespace x="http://marklogic.com/performance/dashboard/xquery"

define variable $x:NBSP as xs:string { codepoints-to-string(160) }

define variable $x:NL as xs:string { codepoints-to-string(10) }

(:~ string-padding :)
define function x:string-pad(
  $padString as xs:string?,
  $padCount as xs:integer)
 as xs:string?
{
  (: for 1.0-ml modules - why did the committee remove useful functions? :)
  string-pad($padString, $padCount)
}

(:~ get the epoch seconds :)
define function x:get-epoch-seconds($dt as xs:dateTime)
  as xs:unsignedLong
{
  xs:unsignedLong(
    ($dt - xs:dateTime('1970-01-01T00:00:00Z'))
    div xdt:dayTimeDuration('PT1S') )
}

(:~ get the epoch seconds :)
define function x:get-epoch-seconds()
  as xs:unsignedLong
{
  x:get-epoch-seconds(current-dateTime())
}

(:~ convert epoch seconds to dateTime :)
define function x:epoch-seconds-to-dateTime($v)
  as xs:dateTime
{
  xs:dateTime("1970-01-01T00:00:00-00:00")
  + xdt:dayTimeDuration(concat("PT", $v, "S"))
}

define function x:duration-to-microseconds($d as xs:dayTimeDuration)
 as xs:unsignedLong {
   xs:unsignedLong( $d div xdt:dayTimeDuration('PT0.000001S') )
}

define function x:lead-nbsp($v as xs:string, $len as xs:integer)
 as xs:string {
  x:lead-string($v, $x:NBSP, $len)
}

define function x:lead-space($v as xs:string, $len as xs:integer)
 as xs:string {
  x:lead-string($v, ' ', $len)
}

define function x:lead-zero($v as xs:string, $len as xs:integer)
 as xs:string {
  x:lead-string($v, '0', $len)
}

define function x:lead-string(
  $v as xs:string, $pad as xs:string, $len as xs:integer)
 as xs:string {
  concat(x:string-pad($pad, $len - string-length(string($v))), string($v))
}

(: lib-xquery.xqy :)
