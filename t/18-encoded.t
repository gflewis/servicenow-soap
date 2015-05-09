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
my $filter = 'sys_created_onONToday@javascript:gs.daysAgoStart(0)@javascript:gs.daysAgoEnd(0)';
my @recs = $incident->getRecords($filter);

ok (@recs > 1, "Records retrieved");
my $tcount = 0;
foreach my $rec (@recs) {
    my $number = $rec->{number};
    my $created = $rec->{sys_created_on};
    print "$number $created\n";
    ++$tcount if substr($created, 0, 10) eq $today;
}
ok ($tcount eq @recs, "$tcount created today");

1;
