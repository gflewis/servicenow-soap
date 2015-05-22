use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

# SOAP::Lite->import(+trace => 'debug');

plan skip_all => "no config" unless TestUtil::config;
plan skip_all => "aggregates disabled" unless TestUtil::getProp("test_aggregates");

my $sn = TestUtil::getSession();
my $incident = $sn->table('incident');
my $sys_user_group = $sn->table('sys_user_group');
my $filter = getProp('incident_filter');

my $totalCount = $incident->count($filter);
ok ($totalCount > 0, "total count=$totalCount");

eval { my %badResult = $incident->countBy() };
ok ($@, "countBy failed with missing argument");
ok ($@, "message: $@");

my %byCategory = $incident->countBy('category', $filter);
ok (%byCategory, "byCategory not empty");
my $categoryKeys = keys %byCategory;
ok ($categoryKeys > 1, "$categoryKeys keys in byCategory");
foreach my $key (sort keys %byCategory) {
    my $count = $byCategory{$key};
    ok ($count =~ /\d+/, "category: $key: count=$count");
}

my %result = $incident->countBy('assignment_group', $filter);

ok (%result, "result not empty");
my $nkeys = keys %result;
ok ($nkeys > 1, "$nkeys keys in result");

foreach my $key (keys %result) {
    my $count = $result{$key};
    note "$key: $count";
}

done_testing;

1;
