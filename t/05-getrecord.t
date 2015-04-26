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
my $pass = $config{password};
BAIL_OUT "not initialized" unless $instance;
my $sn = ServiceNow($instance, $user, $pass, 1);
my $sys_user = $sn->table('sys_user');
eval { my $userrec4 = $sys_user->getRecord(active => 'true') };
ok ($@, "get method for all active users threw exception (more than one)");
}
1;