use strict;
use warnings;
use Carp;
use Test::More;
#use Test::NoWarnings;
use Test::Exception;
use lib qw(t/lib);
use TestWebAppBasic;
use CGI;

use File::Temp;

plan skip_all => 'reworking';

sub nonexistent_dir {
    my $new_dir = File::Temp->newdir;
    return $new_dir->dirname;
}

subtest 'httpdocs_dir not specified' => sub{
    plan tests => 2;
    my $app = TestWebAppBasic->new;
    isa_ok($app, 'CGI::Application');
    throws_ok {
        $app->ajax_upload_setup(
        );
    } qr/no httpdocs_dir specified/, 'absent argument';
};

subtest 'httpdocs_dir does not exist' => sub{
    plan tests => 2;
    my $app = TestWebAppBasic->new;
    isa_ok($app, 'CGI::Application');
    throws_ok {
        $app->ajax_upload_setup(
            httpdocs_dir => nonexistent_dir()
        );
    } qr/is not a directory/, 'nonexistent directory';
};

subtest 'httpdocs_dir does not exist' => sub{
    plan tests => 2;
    my $app = TestWebAppBasic->new;
    isa_ok($app, 'CGI::Application');
    my $actually_a_file = File::Temp->new;
    throws_ok {
        $app->ajax_upload_setup(
            httpdocs_dir => $actually_a_file->filename,
        );
    } qr/is not a directory/, 'not actually a directory';
};

subtest 'upload_subdir does not exist' => sub{
    plan tests => 2;
    my $app = TestWebAppBasic->new;
    isa_ok($app, 'CGI::Application');
    my $tmpdir = File::Temp->newdir;
    throws_ok {
        $app->ajax_upload_setup(
            httpdocs_dir => $tmpdir->dirname,
        );
    } qr/is not a directory/, 'not actually a directory';
};

subtest 'upload_subdir is not writeable' => sub{
    plan tests => 2;
    my $app = TestWebAppBasic->new;
    isa_ok($app, 'CGI::Application');
    my $tmpdir = File::Temp->newdir;
    my $tmpdir_name = $tmpdir->dirname;
    mkdir "$tmpdir_name/img";
    mkdir "$tmpdir_name/img/uploads";
    chmod 300, "$tmpdir_name/img/uploads";
    throws_ok {
        $app->ajax_upload_setup(
            httpdocs_dir => $tmpdir->dirname,
        );
    } qr/is not writeable/, 'uploads not writeable';
};


