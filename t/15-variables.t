use strict;
use warnings;
use TestUtil;
use Test::More;
use ServiceNow::SOAP;

# test the getVariables function

my $ritmNumber;
if (TestUtil::config) {
    $ritmNumber = getProp('ritm_number');
    if ($ritmNumber) {
        plan tests => 2;
    }
    else {
        plan skip_all => "no ritm_number";
    }
}
else {
    plan skip_all => "no config";
}

my $sn = TestUtil::getSession();
my $minimum = 2;

my $sc_req_item = $sn->table('sc_req_item');
my $ritmRec = $sc_req_item->getRecord(number => $ritmNumber);
my $sysid = $ritmRec->{sys_id};
my @vars = $sc_req_item->getVariables($sysid);
my $count = @vars;
print $ritmNumber, "\n";
foreach my $var (sort { $a->{order} <=> $b->{order} } @vars) {
    my $order     = $var->{order};
    my $name      = $var->{name};
    my $reference = $var->{reference};
    my $question  = $var->{question};
    my $value     = $var->{value};
    print "$order $name=$value";
    print " [$reference]" if $reference;
    print "\n";
}

ok (scalar(@vars) > $minimum, "$ritmNumber has $count variables");

# check result type for all reference variables
my ($refvarcount, $refvarok);
foreach my $var (@vars) {
    if ($var->{reference}) {
        $refvarcount++;
        my $value = $var->{value};
        $refvarok++ if $value eq '' or TestUtil::isGUID($value);
    }
}

ok ($refvarok == $refvarcount, "all reference values are GUIDs");

1;