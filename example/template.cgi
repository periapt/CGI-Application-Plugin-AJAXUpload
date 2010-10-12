#!/usr/bin/perl 

#
# Sample application 
#
# Just place this file in a CGI enabled part of your website, and the httpdocs
# contents in the appropriate place, and 
# load it up in your browser.  The only valid username/password
# combination is 'test' and '123'.
#
use strict;
use warnings;
use Readonly;

# This bit needs to be modified for the local system.
Readonly my $TEMPLATE_DIR => '/home/nicholas/git/CGI-Application-Plugin-AJAXUpload/example/templates';
Readonly my $IMAGE_WIDTH => 350;
Readonly my $IMAGE_HEIGHT => 248;

Readonly my $HTML_CHAR_FRAG => qr{
    [\w\s\.,'!/\)\(;%]
}xms;

Readonly my $HTML_ENTITY_FRAG => qr{
    &\w+;
}xms;

Readonly my $HTML_STRICT_REGEXP => qr{
    \A                              # Start of string
    (?!\s)                          # No initial space
    (?:
        $HTML_CHAR_FRAG
        |$HTML_ENTITY_FRAG
    ){1,255}       # Words, spaces and limited punctuation
    (?<!\s)                         # No end space
    \z # end string
}xms;

Readonly my $HTML_BODY_REGEXP => qr{
    \A # Start of string
    (?:
        [\&\;\=\<\>\"\]\[]
        |$HTML_CHAR_FRAG
        |$HTML_ENTITY_FRAG
    )+
    \z
    # end string
}xms;

{

    package SampleEditor;

    use base ("CGI::Application::Plugin::HTDot", "CGI::Application");

    use CGI::Application::Plugin::AutoRunmode;
    use CGI::Application::Plugin::JSON qw(json_body to_json);
    use CGI::Application::Plugin::AJAXUpload;
    use CGI::Application::Plugin::ValidateRM;
    use Data::FormValidator::Filters::ImgData;

    use CGI::Carp qw(fatalsToBrowser);

    sub setup {
        my $self = shift;
        $self->start_mode('one');
        $self->ajax_upload_httpdocs('/var/www/vhosts/editor/httpdocs');
        my $profile = $self->ajax_upload_default_profile;
        $profile->{field_filters}->{value} =
                filter_resize($IMAGE_WIDTH,$IMAGE_HEIGHT);
        $self->ajax_upload_setup(dfv_profile=>$profile);
    }

    sub one : Runmode {
        my $self = shift;
        my $tmpl_obj = $self->load_tmpl('one.tmpl');
        return $tmpl_obj->output;
    }

    sub two : Runmode {
        my $c = shift;
        # I am using HTML::Acid here because that was written exactly for 
        # this setup. However of course you can use whatever HTML cleansing
        # you like.
        use Data::FormValidator::Filters::HTML::Acid;
            my $form_profile = {
                    required=>[qw(title body)],
                    untaint_all_constraints => 1,
                    missing_optional_valid => 1,
                    debug=>1,
                    filters=>['trim'], 
                    field_filters=>{
                         body=>[filter_html(img_height_default=>$IMAGE_HEIGHT,img_width_default=>$IMAGE_WIDTH)],  
                    },
                    constraint_methods => {
                        title=>$HTML_STRICT_REGEXP,
                        body=>$HTML_BODY_REGEXP,
                    },
                    msgs => {
                         any_errors => 'err__',
                         prefix => 'err_',
                         invalid => 'Invalid',
                         missing => 'Missing',
                         format => '<span class="dfv-errors">%s</span>',
                    },
            };
        my ($results, $err_page) = $c->check_rm(
            sub {
                 my $self = shift;
                 my $err = shift;
                 my $template = $self->load_tmpl('one.tmpl');
                 $template->param(%$err) if $err;
                 return $template->output;
             },
             $form_profile
        );
        return $err_page if $err_page;
        my $valid = $results->valid;
        my $template = $c->load_tmpl('two.tmpl');
        $template->param(article=>$valid);
        return $template->output;
    }
}

SampleEditor->new(TMPL_PATH=>$TEMPLATE_DIR)->run;
