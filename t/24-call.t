use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 1 } 
else { plan skip_all => "no config" };

my $propname = "glide.product.description";
my $sn = TestUtil::getSession();
my %outputs = $sn->call("getProperty", property => $propname);
my $propvalue = $outputs{property};
ok ($propvalue eq "Service Automation", "Property value is $propvalue");

1;
