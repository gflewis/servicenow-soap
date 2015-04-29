use strict;
use warnings;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;
use Time::HiRes;

unless (TestUtil::config) { plan skip_all => "no config" };
my $sn = TestUtil::getSession();
my $tblname = "cmdb_ci_disk";
my $tbl = $sn->table($tblname);
my $count = $tbl->count();
ok ($count > 1000, "$count records in $tblname");

my @keys = $tbl->getKeys();
ok (@keys == $count, "$count keys retrieved");

done_testing();


1;