use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;
use Data::Dumper;

if (TestUtil::config) { plan tests => 1 } 
else { plan skip_all => "no config" };

# SOAP::Lite->import(+trace => 'debug');

my $propname = "glide.product.description";
my $sn = TestUtil::getSession();
my $config = TestUtil::config();
my $ws = $config->{web_service};
my $name = $ws->{name};
print "calling Web Service \"$name\"\n";
my %inputs = %{$ws->{inputs}};
my @outnames = @{$ws->{outputs}};
my $outputs = $sn->call($name, %inputs);
# print Dumper($outputs);
my $need = @outnames;
my $good = 0;
foreach my $name (@outnames) {
    my $value = $outputs->{$name} || 'UNDEFINED';
    print "$name=$value\n";
    $good++ if defined $outputs->{$name};
}
ok ($good == $need, "$good of $need outputs defined");

1;
