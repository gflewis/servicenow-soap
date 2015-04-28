package TestUtil;

use strict;
use ServiceNow::SOAP;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(config getProp);

my $configfile = "test.config";
our $config;

sub config {
    unless (-f $configfile) { return undef };
    do $configfile;
    return $config;
};

sub getProp {
    my $name = shift;
    return $config->{$name};
}

sub getInstance {
    return $config->{instance};
}

sub getUsername {
    return $config->{username};
}

sub getSession {
    my $instance = $config->{instance};
    my $user = $config->{username};
    my $pass = $config->{password};
    return ServiceNow($instance, $user, $pass, 1);    
}

sub isGUID { 
    return $_[0] =~ /^[0-9A-Fa-f]{32}$/; 
}

1;