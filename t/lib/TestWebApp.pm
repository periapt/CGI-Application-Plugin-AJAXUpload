package TestWebApp;
use base qw(CGI::Application);
use CGI::Application::Plugin::JSON qw(json_body to_json);
use CGI::Application::Plugin::AJAXUpload;
use File::Temp;
use Test::More;

$ENV{CGI_APP_RETURN_ONLY} = 1;

sub setup {
    my $self = shift;
    $self->header_props(-encoding=>'utf-8',-charset=>'utf-8');

    if ($self->param('document_root')) {
        my $setup = $self->param('document_root');
        $self->$setup();
    }
    else {
        $self->{_TESTWEBAPP_TEMPDIR} = File::Temp->newdir();
        my $httpdocs_dir = $self->{_TESTWEBAPP_TEMPDIR}->dirname;
        mkdir "${httpdocs_dir}/img";
        mkdir "${httpdocs_dir}/img/uploads";
        $self->ajax_upload_httpdocs($httpdocs_dir);
    }

    $self->ajax_upload_setup();

    return;
}

sub response_like {
    my $self = shift;
    my $header_re = shift;
    my $body_re = shift;
    my $comment = shift;

    my $output = $self->run;

    my ($header, $body) = split /\r\n\r\n/, $output;
    like($header, $header_re, "$comment (header match)");
    like($body, $body_re, "$comment (body match)");

    return;
}

1
