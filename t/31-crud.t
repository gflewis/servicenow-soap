use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

# This script tests insert, update, attachFile and deleteRecord

if (TestUtil::config) {
    if (getProp('test_insert')) {
        plan tests => 8;
    }
    else {
        plan skip_all => "test_insert is false";
    }
}
else {
    plan skip_all => "no config";
}

my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
my $timestamp =  
    10000000000 * (1900 + $year) + 100000000 * (1 + $mon) + 1000000 * $mday + 
    10000 * $hour + 100 * $min + $sec;

my $lorum = <<zzz;
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur efficitur mi nisl, in consectetur tellus pellentesque eu. Aliquam ante purus, consectetur sed laoreet ut, viverra a ligula. 

Nunc congue eros eros, vel egestas urna aliquet sed. Duis euismod tristique nunc, id feugiat lorem mattis id. Etiam sodales congue enim gravida accumsan. Duis vel justo fermentum, laoreet nulla vel, convallis arcu. Aenean ac ex tincidunt, fermentum felis at, condimentum velit.
zzz

my $groupName = getProp('group_name');
ok ($groupName, "assignment group is $groupName");
my $shortDescription = "Test $timestamp script $0";
my $fullDescription = "$lorum\n$timestamp";

my $incident = TestUtil::getSession()->table("incident");

#
# Crete an incident
#
my %result = $incident->insert(
    short_description => $shortDescription,
    description => $fullDescription,
    assignment_group => $groupName,
    impact => 3);

my $sysid = $result{sys_id};
my $number = $result{number};

ok ($sysid, "inserted sys_id=$sysid");
ok ($number =~ /^INC\d+$/, "inserted number=$number");

my $rec1 = $incident->get($sysid);
ok ($rec1->{impact} == 3, "original impact is 3");

# 
# Attach a file
#
my $attachment = getProp('attachment');
my $mimetype = getProp('attachment_type');

ok ($attachment, "attachment name is $attachment");
ok ($mimetype, "attachment type is $mimetype");
$incident->attachFile($sysid, $attachment, $mimetype);
#
# Update the incident
#
$incident->update(sys_id => $sysid, impact => 1);
my $rec2 = $incident->get($sysid);
ok ($rec2->{impact} == 1, "updated impact is 1");

# 
# Delete the incident
#
SKIP: {
    skip "deleteRecord test skipped", 1 unless getProp('test_delete');
    $incident->deleteRecord(sys_id => $sysid);
    my $rec3 = $incident->get($sysid);
    ok (!$rec3, "incident deleted");    
  };

1;
