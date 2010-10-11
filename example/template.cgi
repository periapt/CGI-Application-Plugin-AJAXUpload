#!/usr/bin/perl 

#
# Sample application 
#
# Just place this file in a CGI enabled part of your website, and the httpdocs
# contents in the appropriate place, and 
# load it up in your browser.  The only valid username/password
# combination is 'test' and '123'.
#
use lib qw(/home/nicholas/git/cgi-application-plugin-authentication/lib);

use strict;
use warnings;
use Readonly;

# This bit needs to be modified for the local system.
Readonly my $TEMPLATE_DIR =>
'/home/nicholas/git/CGI-Application-Plugin-AJAXUpload/example/templates';

{

    package SampleEditor;

    use base "CGI::Application";

    use CGI::Application::Plugin::AutoRunmode;
    use CGI::Carp qw(fatalsToBrowser);

    sub setup {
        my $self = shift;
        $self->start_mode('one');
    }

    sub one : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('one.tmpl');
        return $tmpl_obj->output;
    }

    sub two : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('two.tmpl');
        return $tmpl_obj->output;
    }
}

SampleEditor->new(TMPL_PATH=>$TEMPLATE_DIR)->run;

