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

my $timestamp = TestUtil::getTimestamp();
my $lorem = TestUtil::lorem();

my $groupName = getProp('group_name');
ok ($groupName, "assignment group is $groupName");
my $shortDescription = "Test $timestamp script $0";
my $fullDescription = "$lorem\n$timestamp";

my $sn = TestUtil::getSessin();
my $incident = $sn->table("incident");

#
# Create an incident
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
