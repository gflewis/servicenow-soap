package TestUtil;

use strict;
use ServiceNow::SOAP;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(config getProp getTimestamp);

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
    my $trace = defined $_[0] ? $_[0] : 1;
    my $instance = $config->{instance};
    my $user = $config->{username};
    my $pass = $config->{password};
    return ServiceNow($instance, $user, $pass, $trace);    
}

sub isGUID { 
    return $_[0] =~ /^[0-9A-Fa-f]{32}$/; 
}

sub getTimestamp {
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
	my $timestamp = 
		10000000000 * (1900 + $year) + 
		100000000 * (1 + $mon) + 
		1000000 * $mday + 
		10000 * $hour + 
		100 * $min + 
		$sec;
	return $timestamp;
}

1;
