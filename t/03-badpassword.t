use strict;
use Test::More tests => 1;
use ServiceNow::SOAP;
my $configfile = "test.config";
our %config;
SKIP: {
skip "$configfile not found", 7 unless -f $configfile;
do $configfile or BAIL_OUT "Unable to load $configfile";
my $instance = $config{instance};
my $user = $config{username};
BAIL_OUT "not initialized" unless $instance;
my $sn = ServiceNow($instance, $user, "bad password")->connect() 
    or print "failed to connect to $instance: $@";
ok (!$sn, "connect trapped bad password");

}
1;