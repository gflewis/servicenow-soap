use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

unless (TestUtil::config) { plan skip_all => "no config" };
my $sn = TestUtil::getSession();
my $tbl = $sn->table("sys_user_group");
my $qry = $tbl->query(active => "true", __order_by => "name");
$qry->includeColumns("sys_id,name,sys_updated_on");
my @recs = $qry->fetch();
my $count = @recs;
ok ($count > 5, "$count groups retrieved");
my $grp = $recs[0];
ok ($grp->{sys_id}, "sys_id found");
ok ($grp->{sys_updated_on}, "sys_updated_on found");
ok (!$grp->{sys_created_on}, "sys_created_on not found");

done_testing();
1;
