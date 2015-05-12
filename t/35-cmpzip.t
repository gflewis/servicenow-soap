use strict;
use warnings;

use ServiceNow::SOAP;
use Time::HiRes;
use Test::More;
use lib 't';
use TestUtil;

# SOAP::Lite->import(+trace => 'debug');

unless (TestUtil::config) { plan skip_all => "no config" };
my $sn1 = TestUtil::getSession(zip => 10, fetch => 500);
my $sn2 = TestUtil::getSession(zip => 0, fetch => 500);

my $computer1 = $sn1->table('cmdb_ci_computer');
my $computer2 = $sn2->table('cmdb_ci_computer');

my $query1 = $computer1->query(
    operational => 1, sys_class_name => 'cmdb_ci_computer');
my $count = $query1->getCount();

exit();

my $query2 = $computer2->asQuery($query1->getKeys());
ok ($query2->getCount() == $count, "$count records in query");

my $start1 = Time::HiRes::time();
my @recs1 = $query1->fetchAll();
my $finish1 = Time::HiRes::time();
my $count1 = @recs1;
ok ($count1 == $count, "$count1 records retrieved (expected $count)");

my $start2 = $finish1;
my @recs2 = $query2->fetchAll();
my $finish2 = Time::HiRes::time();
my $count2 = @recs2;
ok ($count2 == $count, "$count2 records retrieved (expected $count)");

my $elapsed1 = $finish1 - $start1;
my $elapsed2 = $finish2 - $start2;
printf "query1 elapsed %.2f\n", $elapsed1;
printf "query2 elapsed %.2f\n", $elapsed2;
ok ($elapsed2 < $elapsed1, "second query was faster");

done_testing();


1;
