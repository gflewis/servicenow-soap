use strict;
use warnings;
use Test::More;
use ServiceNow::SOAP;
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;
use lib 't';
use TestUtil;

unless (TestUtil::config) { plan skip_all => "no config" };
my $sn = TestUtil::getSession();
my $tbl = $sn->table('incident');

my @columns = $tbl->getColumns();
my $count = @columns;
ok ($count > 0, "$count fields");
my @columns2 = $tbl->getColumns();
ok (join(',', @columns2) eq join(',', @columns), "got same list twice");

my @excluded = $tbl->getExcluded(qw(sys_id sys_created_on sys_updated_on));
ok (@excluded < @columns, "excluded list is shorter");
my %cnames = map { $_ => $_ } @columns;
my %xnames = map { $_ => $_ } @excluded;
ok ($cnames{description}, "description is a column");
ok ($cnames{sys_created_on}, "sys_created_on is a column");
ok ($xnames{description}, "description excluded");
ok (! $xnames{sys_created_on}, "sys_created_on not excluded");

done_testing();
1;
