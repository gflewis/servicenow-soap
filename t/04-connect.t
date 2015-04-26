use strict;
use Test::More tests => 7;
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
my $sys_user = $sn->table("sys_user");
ok ($sys_user, "table method appears to work");
my $userrec = $sys_user->getRecord(user_name => $user);
ok($userrec, "User record retrieved");
my $usersysid = $userrec->{sys_id};
my $timezone = $userrec->{time_zone};
ok ($userrec->{user_name} eq $user, "User name is $user");
ok ($usersysid =~ /^[0-9a-z]{32}$/, "sys_id looks like a sys_id");
ok ($userrec->{time_zone} eq "GMT", "Time zone is GMT");

my $userrec2 = $sys_user->get($usersysid);
ok ($userrec2->{user_name} eq $user, "get method appears to work");

my $userrec3 = $sys_user->get('12345678901234567890123456789012');
# ok ($@, "get method for bad sys_id threw exception");
ok (!$userrec3, "get method for bad sys_id returned null");
}
1;