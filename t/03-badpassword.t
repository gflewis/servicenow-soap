use strict;
use ServiceNow::SOAP;
use lib 't';
use TestUtil;
use Test::More;
if (TestUtil::config) { plan tests => 1 } else { plan skip_all => "no config" };

my $instance = TestUtil::getInstance();
my $user = TestUtil::getUsername();
BAIL_OUT "not initialized" unless $instance;
my $sn = ServiceNow($instance, $user, "bad password")->connect() 
    or print "failed to connect to $instance: $@";    
ok (!$sn, "connect trapped bad password");

1;
