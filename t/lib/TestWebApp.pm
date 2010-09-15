package TestWebApp;
use base qw(CGI::Application);
use CGI::Application::Plugin::AJAXUpload;
use File::Temp;
use Test::More;

$ENV{CGI_APP_RETURN_ONLY} = 1;

sub setup {
    my $self = shift;

    $self->{_TESTWEBAPP_TEMPDIR} = File::Temp->newdir();
    my $httpdocs_dir = $self->{_TESTWEBAPP_TEMPDIR}->dirname;
    mkdir "${httpdocs_dir}/img";
    mkdir "${httpdocs_dir}/img/uploads";

    my %ajax_upload_args = (
        httpdocs_dir => $httpdocs_dir,
    );

    $self->ajax_upload_setup(%ajax_upload_args);

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
