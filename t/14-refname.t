use strict;
use warnings;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;

# Verify we can we query a table using location.name=$value 

my $locationName;
if (TestUtil::config) {
    $locationName = getProp("location_name");
    # print "location=$locationName\n";
    if ($locationName) {
        plan tests => 1;
    }
    else {
        plan skip_all => "no location_name";
    }
}
else {
    plan skip_all => "no config";
}

my $sn = TestUtil::getSession();
my $minimum = 3;

my $computer = $sn->table('cmdb_ci_computer');
my @recs = $computer->query(
    "operational_status" => "1", 
    "location.name" => $locationName,
    __order_by => "name")->fetchAll();
my $count = scalar(@recs);
foreach my $rec (@recs) {
    # print $rec->{name}, "\n";
}
ok (scalar(@recs) > $minimum, "$locationName has $count computers");

1;