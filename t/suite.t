use diagnostics;
use warnings;
use strict;
use Test::More;
use Data::Dumper;

use ServiceNow::SOAP;

my $propfile = "./test.cfg";
my %props;
open PROPS, "<$propfile" or die "Unable to open $propfile: $!";
while (<PROPS>) {
    next unless /^(\w+)\s*=\s*(.*)$/;
    $props{$1} = $2;
}

sub isGUID { 
    return $_[0] =~ /^[0-9A-Fa-f]{32}$/; 
}

my $url = $props{url};
my $user = $props{user};
my $pass = $props{pass};
my $sn = ServiceNow($url, $user, $pass, 1);
my $sys_user = $sn->table("sys_user");
ok ($sys_user, "table method appears to work");
my $userrec = $sys_user->getRecord(user_name => $user);
ok($userrec, "User record retrieved");
my $usersysid = $userrec->{sys_id};
my $timezone = $userrec->{time_zone};
ok ($userrec->{user_name} eq $user, "User name is $user");
ok ($usersysid =~ /^[0-9a-z]{32}$/, "sys_id looks like a sys_id");
ok ($userrec->{time_zone} eq "GMT", "Time zone is GMT");

my $userrec2 = $sys_user->get($usersysid);
ok ($userrec2->{user_name} eq $user, "get method appears to work");

my $userrec3 = $sys_user->get('12345678901234567890123456789012');
# ok ($@, "get method for bad sys_id threw exception");
ok (!$userrec3, "get method for bad sys_id returned null");

eval { my $userrec4 = $sys_user->get(active => 'true') };
ok ($@, "get method for all active users threw exception (more than one)");

my $cmn_location = $sn->table("cmn_location");
my @locations = $cmn_location->getRecords(__order_by => "name");
ok(@locations > 3, "At least 3 locations");
ok(@locations < 251, "Fewer than 250 locations");
my $locationCount = $cmn_location->count();
ok($locationCount == scalar(@locations), "Location count = $locationCount");

# Testing Display Values
my $groupName = $props{group_name};
my $sys_user_group = $sn->table("sys_user_group");
my $grpRec = $sys_user_group->getRecord(name => $groupName);
ok($grpRec, "sys_user_group record read");
my $grpId = $grpRec->{sys_id};
ok(isGUID($grpId), "Group sys_id=$grpId");
ok($grpRec->{name} eq $groupName, "Group name is $groupName");
my $grpMgrId = $grpRec->{manager};
ok(isGUID($grpMgrId), "Group manager sys_id=$grpMgrId");
my $grpMgrRec = $sys_user->get($grpMgrId);
my $grpMgrName = $grpMgrRec->{name};
ok($grpMgrName, "Group manager name=$grpMgrName");
my $grpRec2 = $sys_user_group->setDV("true")->get($grpId);
ok($grpRec2, "grpRec2 retrieved");
ok($grpRec2->{manager} eq $grpMgrName, "setDV('true')");
my $grpRec3 = $sys_user_group->setDV("all")->get($grpId);
ok($grpRec3->{dv_manager} eq $grpMgrName, "setDV('all')");
my $grpRec4 = $sys_user_group->setDV(0)->get($grpId);
ok($grpRec4->{manager} eq $grpMgrId, "setDV(0)");

my $computer = $sn->table('cmdb_ci_computer');
my $wsCount1 = $computer->count(sys_class_name => 'cmdb_ci_computer', operational_status => 1);
ok ($wsCount1 > 0, "Workstation count = $wsCount1");
my $wsCount2 = $computer->count('sys_class_name=cmdb_ci_computer^operational_status=1');
ok ($wsCount2 == $wsCount2, "Count using encoded query");
my @wsKeys = $computer->getKeys(sys_class_name => 'cmdb_ci_computer', operational_status => 1);
ok (@wsKeys == $wsCount1, "Workstation keys = $wsCount1");

my $emptyQuery = $computer->asQuery();
ok ($emptyQuery->getCount() == 0, "Empty query is empty");
my $wsQuery1 = $computer->asQuery(@wsKeys);
ok ($wsQuery1->getCount() == $wsCount1, "Query looks okay");
my $computerQuery = $computer->query();
ok ($computerQuery->getCount() > $wsCount1, "More computers than workstations");

my @wsRec1 = $computer->getRecords(sys_class_name => 'cmdb_ci_computer', operational_status => 1);
my $wsCount3 = @wsRec1;
ok ($wsCount3 < $wsCount1, "getRecords returned $wsCount3 computers");

done_testing();


