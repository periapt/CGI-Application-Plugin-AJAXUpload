#!/usr/bin/perl -wT
use strict;
use warnings;
use Carp;
use Test::More;
use Test::NoWarnings;
use Test::CGI::Multipart;
use lib qw(t/lib);
use Perl6::Slurp;
use Readonly;
use File::Temp;
use TestWebApp;

plan tests=> 1+8*TestWebApp::cgi_tests();

Readonly my $CONTENT_RE =>
    qr{
        \A
        Encoding:\s+utf-8\s+Content-Type:\s+application/json
        (?:;\s+charset=utf-8)?
    }xms;

sub nonexistent_dir {
    my $new_dir = File::Temp->newdir;
    return $new_dir->dirname;
}

sub valid_dir {
    my $tmpdir = File::Temp->newdir;
    my $tmpdir_name = $tmpdir->dirname;
    mkdir "$tmpdir_name/img";
    mkdir "$tmpdir_name/img/uploads";
    return $tmpdir;
}

foreach my $cgi (TestWebApp::cgi_tests()) {

my $tcm = Test::CGI::Multipart->new;
$tcm->set_param(name=>'rm', value=>'ajax_upload_rm');
$tcm->upload_file(name=>'file', value=>'This is a test!',file=>'test.txt');

subtest 'httpdocs_dir not specified' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {}
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"No document root specified"}/,
        'httpdocs_dir not specified'
    );
};

subtest 'httpdocs_dir does not exist' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs(nonexistent_dir());
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Document root is not a directory"}/,
        'httpdocs_dir does not exist'
    );
};

subtest 'httpdocs_dir not a directory' => sub{
    plan tests => 3;
    my $actually_a_file = File::Temp->new;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($actually_a_file->filename);
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(rm=>'ajax_upload_rm');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Document root is not a directory"}/,
        'httpdocs_dir not a directory'
    );
};

subtest 'upload_subdir does not exist' => sub{
    plan tests => 3;
    my $tmpdir = File::Temp->newdir;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir->dirname);
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Upload folder is not a directory"}/,
        'upload folder does not exist'
    );
};

subtest 'upload_subdir is not writeable' => sub{
    plan tests => 3;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    chmod 300, "$tmpdir_name/img/uploads";
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Upload folder is not writeable"}/,
        'Upload folder is not writeable'
    );
};

my $tcm2 = Test::CGI::Multipart->new;
$tcm2->set_param(name=>'rm', value=>'ajax_upload_rm');
subtest 'no file parameter' => sub{
    plan tests => 3;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    my $app = TestWebApp->new(
        QUERY=>$tcm2->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"No file handle returned"}/,
        'no file parameter'
    );
};


subtest 'internal error' => sub{
    plan skip_all => 'broken';
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec => {
                filename_gen=>sub {croak "Help!"}
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Internal Error"}/,
        'Internal Error',
        qr/Help!/
    );
};

subtest 'success' => sub{
    plan tests => 4;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(cgi=>$cgi),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"SUCCESS","image_url":"/img/uploads/test.txt"}!xms,
        'success'
    );
    is(slurp("$tmpdir_name/img/uploads/test.txt"), "This is a test!", 'file contents');
};

}





