use Module::Build;
use strict;

my $builder = Module::Build->new(
    module_name => 'ServiceNow::SOAP',
    license => 'artistic_2',
    dist_version => '0.002_000',
    requires => {
        'SOAP::Lite' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Cookies' => 0,
        'MIME::Base64' => 0,
        'XML::Simple' => 0,
        'Time::HiRes' =>
        'Carp' => 0
        },
    test_requires => {
        'Test::More' => 0
    }
);

$builder->create_build_script();
