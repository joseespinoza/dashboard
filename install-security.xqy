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

import module namespace in="http://marklogic.com/performance/dashboard/install"
 at "lib-install.xqy";
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
  try { in:lambda(xs:QName($fn), $args, $empty) }
  catch ($ex) {
    (: ignore 'already exists' codes, and return existing id :)
    if (not($ex/error:code = $code)) then xdmp:set($EXCEPTION, $ex)
    else in:lambda(xs:QName($fn-get), $args-get)
  }
};

(: The idea here is to proceed stepwise until we hit an error.
 : Each error will be caught and returned as XML.
 : The caller should keep invoking until no errors are thrown
 : or until some maximum number of invokes.
 :)
xdmp:log(text {
    $pd:NAME, 'install-security:', xdmp:database(), xdmp:security-database() }),
if (xdmp:database() eq xdmp:security-database()) then ()
else error((), 'INSTALL-NOTSECURITY', text {
    xdmp:database-name(xdmp:database()), 'is not the security database!' })
,
(: create users and roles :)
let $role-read := local:do(
  'sec:create-role',
  ($pd:ROLENAME-READ, "Dashboard view-only role"), 3,
  'SEC-ROLEEXISTS', 'sec:get-role-ids', ($pd:ROLENAME-READ) )
(: inherits previous role :)
let $role := local:do(
  'sec:create-role',
  ($pd:ROLENAME, "Dashboard sampling task role", $pd:ROLENAME-READ), 2,
  'SEC-ROLEEXISTS', 'sec:get-role-ids', ($pd:ROLENAME) )
(: privileges :)
(: TODO think about using protected collection instead of any-collection :)
(: TODO think about using uri privilege instead of any-uri :)
for $action in ('status', 'any-collection', 'any-uri')
let $action := concat('http://marklogic.com/xdmp/privileges/', $action)
return local:do(
  'sec:privilege-add-roles',
  ($action, 'execute', $pd:ROLENAME) )
,
let $user := local:do(
  'sec:create-user',
  ($pd:USERNAME, "Dashboard sampling task user",
    (: no one should log in as this user :)
    xdmp:integer-to-hex(xdmp:random()), $pd:ROLENAME), 2,
  'SEC-USEREXISTS', 'sec:uid-for-name', ($pd:USERNAME) )
return $EXCEPTION

(: install-security.xqy :)