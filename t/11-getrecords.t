use strict;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;

if (TestUtil::config) { plan tests => 3 } else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();

my $cmn_location = $sn->table("cmn_location");
my @locations = $cmn_location->getRecords(__order_by => "name");
ok(@locations > 3, "At least 3 locations");
ok(@locations < 251, "Fewer than 250 locations");
my $locationCount = $cmn_location->count();
ok($locationCount == scalar(@locations), "Location count = $locationCount");

1;