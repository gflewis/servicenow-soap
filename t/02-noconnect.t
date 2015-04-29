# test that connect() traps error and returns null if connection parameters are bad
use strict;
use warnings;
use Test::More tests => 1;
use ServiceNow::SOAP;
my $sn = ServiceNow("badcompany", "baduser", "badpassword")->connect();
print $@,"\n";
ok (!$sn, "connect trapped bad connection parameters");

1;