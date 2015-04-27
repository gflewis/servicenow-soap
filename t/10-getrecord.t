use strict;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;

if (TestUtil::config) { plan tests => 1 } else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();
my $tbl = $sn->table('sys_user');
eval { my $rec = $tbl->getRecord(active => 'true') };
ok ($@, "get method for all active users threw exception (more than one)");
1;