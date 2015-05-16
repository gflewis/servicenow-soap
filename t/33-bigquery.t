use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More;
use Time::HiRes;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 2 }
else { plan skip_all => "no config" };

# SOAP::Lite->import(+trace => 'debug');

my $sn = TestUtil::getSession();
my $tblname = "cmdb_ci";
my $tbl = $sn->table($tblname);
my $count = $tbl->count();
ok ($count > 1000, "$count records in $tblname");

my $size = 100000;
$size = 100 * (int $count / 4 / 100) if ($size > $count);
note "size = $size";
$sn->set(query => $size);

my $query = $tbl->query();
ok ($query->getCount() == $count, "query count matches");

1;
