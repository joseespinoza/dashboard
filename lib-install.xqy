xquery version "1.0-ml";
(:
 : Copyright (c) 2009-2010 Mark Logic Corporation. All Rights Reserved.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :
 :)

module namespace in="http://marklogic.com/performance/dashboard/install";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace fs="http://marklogic.com/xdmp/status/forest";

(: must import anything used by lambda functions :)
import module namespace admin="http://marklogic.com/xdmp/admin"
  at "/MarkLogic/admin.xqy";
import module "http://marklogic.com/xdmp/security"
  at "/MarkLogic/security.xqy";

declare variable $in:CONFIG := admin:get-configuration()
;

declare variable $in:DATABASE := admin:database-get-id($in:CONFIG, $in:NAME)
;

declare variable $in:FOREST := admin:forest-get-id($in:CONFIG, $in:NAME)
;

declare variable $in:GROUP := admin:host-get-group($in:CONFIG, $in:HOST)
;

declare variable $in:HOST as xs:unsignedLong := (
  (: we want to do things on the security host :)
  xdmp:forest-status(
    xdmp:database-forests(xdmp:security-database())[1])
  /fs:host-id
);

declare variable $in:NAME as xs:string? := ();

(: TODO load everything into a modules database? :)
(: TODO modules may change if installs become more flexible :)
declare variable $in:MODULES := xdmp:modules-database()
;

(: TODO root may change if installs become more flexible :)
declare variable $in:ROOT as xs:string := xdmp:modules-root()
;

declare variable $in:USER := xdmp:user($in:USERNAME)
;

declare variable $in:USERNAME := lower-case($in:NAME);

declare function in:lambda(
  $fn as xs:QName,
  $args as item()* )
 as item()*
{
  in:lambda($fn, $args, 0)
};

declare function in:lambda(
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

declare function in:admin(
  $fn as xs:string,
  $args as item()* )
 as empty-sequence()
{
  xdmp:set(
    $in:CONFIG,
    in:lambda(
      xs:QName(concat('admin:', $fn)),
      ($in:CONFIG, $args) ))
};

declare function in:database(
  $fn as xs:string,
  $args as item()* )
 as empty-sequence()
{
  in:admin(
    concat('database-', $fn), $args)
};

declare function in:name-set(
  $name as xs:string )
 as empty-sequence()
{
  xdmp:set($in:NAME, $name)
};

declare function in:forest-create()
 as empty-sequence()
{
  if (try { admin:forest-get-id($in:CONFIG, $in:NAME) }
    catch ($ex) { }) then () else (
    (: must save new forest before using it :)
    in:admin('forest-create', ($in:NAME, $in:HOST, '')),
    in:save()
  )
};

declare function in:forest-delete()
 as empty-sequence()
{
  if (try { admin:forest-get-id($in:CONFIG, $in:NAME) }
    catch ($ex) { }) then () else (
    in:admin('forest-delete', ($FOREST, true()))
  )
};

declare function in:database-create()
 as empty-sequence()
{
  if (try { admin:database-get-id($in:CONFIG, $in:NAME) }
    catch ($ex) { }) then () else (
    in:database(
      'create',
      ($in:NAME, xdmp:security-database(), xdmp:schema-database()))
  )
};

declare function in:database-delete()
 as empty-sequence()
{
  if (try { admin:database-get-id($in:CONFIG, $in:NAME) }
    catch ($ex) { }) then () else (
    for $f in admin:database-get-attached-forests($CONFIG, $DATABASE)
    return in:database('detach-forest', ($DATABASE, $f))
    ,
    (: must save forest after detaching :)
    in:save(),
    in:database('delete', ($DATABASE))
  )
};

declare function in:database-set(
  $name as xs:string,
  $args as item()+ )
 as empty-sequence()
{
  in:database(concat('set-', $name), ($in:DATABASE, $args))
};

declare function in:database-add(
  $name as xs:string,
  $args as item()+ )
 as empty-sequence()
{
  try {
    in:database(concat('add-', $name), ($in:DATABASE, $args)) }
  catch ($ex) {
    if ($ex/error:code eq 'ADMIN-DUPLICATEITEM') then ()
    else xdmp:rethrow() }
};

declare function in:database-attach-forests()
 as empty-sequence()
{
  let $forests := admin:database-get-attached-forests($in:CONFIG, $in:DATABASE)
  let $detach := (
    for $f in $forests
    where $f ne $in:FOREST
    return in:database('detach-forest', ($in:DATABASE, $f))
  )
  where not($forests = $in:FOREST)
  return in:database('attach-forest', ($in:DATABASE, $in:FOREST))
};


declare function in:save()
 as empty-sequence()
{
  admin:save-configuration($in:CONFIG)
};

declare function in:invoke(
  $module as xs:string,
  $vars as item()* )
 as item()*
{
  xdmp:invoke(
    $module,
    $vars,
    <options xmlns="xdmp:eval">
    {
      element database { xdmp:security-database() },
      (: this should be safe,
       : because the rest of the query does not touch security
       :)
      element isolation { 'different-transaction' }
    }
    </options>)
};

(: lib-install.xqy :)