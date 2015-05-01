use strict;
use warnings;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;
use List::MoreUtils qw(uniq);

if (TestUtil::config) { plan tests => 3 } 
else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();

my $incident = $sn->table('incident');
my $sys_user_group = $sn->table('sys_user_group')->setDV('true');
my $startDate = getProp('start_date');
my $endDate = getProp('end_date');
my $filter = "sys_created_on>=$startDate^sys_created_on<$endDate";
print "filter=$filter\n";
my $count = $incident->count($filter);
ok ($count >= 100, "count($count) is at least 100");
ok ($count < 10000, "count($count) is less than 10000");

my @incRecs = $incident->query($filter)->fetchAll();
ok (@incRecs == $count, "$count records fetched");

my @grpKeys = uniq grep { !/^$/ } map { $_->{assignment_group} } @incRecs;
my @grpRecs = $sys_user_group->asQuery(@grpKeys)->fetchAll();

my $i = 0;
foreach my $grp (@grpRecs) {
    my $sysid = $grp->{sys_id};
    my $name = $grp->{name};
    my $mgr = $grp->{manager};
    print ++$i, ": $sysid $name : $mgr\n";
}


1;