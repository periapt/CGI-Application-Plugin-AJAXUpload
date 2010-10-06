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
        'File::Temp' => 0,
        'Test::NoWarnings' => 0,
        'Test::Warn'=>0,
        'Test::Image::GD'=>0,
        'CGI::Application::Plugin::JSON'=>'0',
    },
    requires => {
        'version'    => 0,
        'Exporter'   => 0,
        'CGI'        => '3.41',
        'CGI::Application' => 0,
        'Perl6::Slurp'=>0,
        'Readonly'=>0,
        'Data::FormValidator'=>0,
        'GD'=>0,
    },
    create_makefile_pl => 'traditional',
    create_readme=>1,
    add_to_cleanup      => [ 'CGI-Application-Plugin-AJAXUpload-*' ],
);

$builder->create_build_script();
