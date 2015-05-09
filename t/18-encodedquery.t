use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 2 } 
else { plan skip_all => "no config" };

my $today = today;
print "today=$today\n";

my $sn = TestUtil::getSession();
my $incident = $sn->table("incident");
my $filter = TestUtil::config->{incident_filter};
print "filter=$filter\n";
my @recs = $incident->getRecords($filter);
my $count = @recs;

ok ($count >= 50, "At least 50 records retrieved");
ok ($count < 1000, "Fewer than 1000 records retrieved");

1;
