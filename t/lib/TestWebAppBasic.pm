package TestWebAppBasic;
use base qw(CGI::Application);
use CGI::Application::Plugin::AJAXUpload;

$ENV{CGI_APP_RETURN_ONLY} = 1;

1
