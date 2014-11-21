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
import module "http://marklogic.com/xdmp/security"
  at "/MarkLogic/security.xqy";

import module namespace pd="http://marklogic.com/performance/dashboard"
 at "lib-dashboard.xqy";

declare option xdmp:update "true";

declare variable $EXCEPTION := ()
;

declare function local:do(
  $fn as xs:string,
  $args as item()* )
 as xs:unsignedLong?
{
  local:do($fn, $args, 0, (), (), ())
};

declare function local:do(
  $fn as xs:string,
  $args as item()*,
  $empty as xs:integer )
 as xs:unsignedLong?
{
  local:do($fn, $args, $empty, (), (), ())
};

declare function local:do(
  $fn as xs:string,
  $args as item()*,
  $empty as xs:integer,
  $code as xs:string*,
  $fn-get as xs:string?,
  $args-get as item()* )
 as xs:unsignedLong?
{
  try { pd:lambda(xs:QName($fn), $args, $empty) }
  catch ($ex) {
    (: ignore 'already exists' codes, and return existing id :)
    if (not($ex/error:code = $code)) then xdmp:set($EXCEPTION, $ex)
    else if (empty($fn-get)) then ()
    else pd:lambda(xs:QName($fn-get), $args-get)
  }
};

xdmp:log(text {
    $pd:NAME, 'uninstall-security:',
    xdmp:database(), xdmp:security-database() }),
if (xdmp:database() eq xdmp:security-database()) then ()
else error((), 'UNINSTALL-NOTSECURITY', text {
    xdmp:database-name(xdmp:database()), 'is not the security database!' })
,
(: remove users and roles :)
let $user := local:do(
  'sec:remove-user', ($pd:USERNAME), 0, 'SEC-USERDNE', (), ())
for $role in ($pd:ROLENAME, $pd:ROLENAME-READ)
return local:do(
  'sec:remove-role', ($role), 0, 'SEC-ROLEDNE', (), ())

, $EXCEPTION

(: uninstall-security.xqy :)