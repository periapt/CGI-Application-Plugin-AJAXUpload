use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::AJAXUpload',
    license             => 'perl',
    dist_author         => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    dist_version_from   => 'lib/CGI/Application/Plugin/AJAXUpload.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'version'    => 0,
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'CGI-Application-Plugin-AJAXUpload-*' ],
);

$builder->create_build_script();
