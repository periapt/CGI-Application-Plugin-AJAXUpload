use strict;
use warnings;
use Carp;
use Test::More tests=>3;
use Test::NoWarnings;
use lib qw(t/lib);
use TestWebApp;
use CGI;

use File::Temp;

sub nonexistent_dir {
    my $new_dir = File::Temp->newdir;
    return $new_dir->dirname;
}

subtest 'httpdocs_dir not specified' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        PARAMS=>{
            document_root=>sub {}
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(rm=>'ajax_upload_rm');
    $app->query->param(validate=>1);
    $app->response_like(
        qr{Encoding:\s+utf-8\s+Content-Type:\s+application/json;\s+charset=utf-8}xms,
        qr/{"status":"No document root specified"}/,
        'httpdocs_dir not specified'
    );
};

subtest 'httpdocs_dir does not exist' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs(nonexistent_dir());
            }
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(rm=>'ajax_upload_rm');
    $app->query->param(validate=>1);
    $app->response_like(
        qr{Encoding:\s+utf-8\s+Content-Type:\s+application/json;\s+charset=utf-8}xms,
        qr/{"status":"Document root is not a directory"}/,
        'httpdocs_dir not a directory'
    );
};

