use strict;
use warnings;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;
use Time::HiRes;

unless (TestUtil::config) { plan skip_all => "no config" };
my $sn = TestUtil::getSession();

my $computer = $sn->table('cmdb_ci_computer');
my $query1 = $computer->query(operational => 1, sys_class_name => 'cmdb_ci_computer')->setChunk(500);
my $count1 = $query1->getCount();
my $query2 = $computer->asQuery($query1->getKeys())->setColumns(
    "sys_id,name,sys_created_on,sys_updated_on")->setChunk(500);
ok ($query2->getCount() == $count1, "$count1 records in query");

my $start1 = Time::HiRes::time();
my @recs1 = $query1->fetchAll();
my $finish1 = Time::HiRes::time();
my $start2 = $finish1;
my @recs2 = $query2->fetchAll();
my $finish2 = Time::HiRes::time();

my $elapsed1 = $finish1 - $start1;
my $elapsed2 = $finish2 - $start2;
printf "query1 elapsed %.2f\n", $elapsed1;
printf "query2 elapsed %.2f\n", $elapsed2;
ok ($elapsed2 < $elapsed1, "second query was faster");

done_testing();


1;