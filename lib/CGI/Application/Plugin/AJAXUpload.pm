package CGI::Application::Plugin::AJAXUpload;

use warnings;
use strict;
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT);
use CGI::Upload;
use Perl6::Slurp;

@EXPORT = qw(
    ajax_upload_httpdocs
    ajax_upload_setup
    _ajax_upload_rm
);

use version; our $VERSION = qv('0.0.1');

# Module implementation here

sub ajax_upload_httpdocs {
    my $self = shift;
    my $httpdocs = shift;
    if ($httpdocs) {
        $self->{__CAP__AJAXUPLOAD_HTTPDOCS} = $httpdocs;
        return;
    }
    return $self->{__CAP__AJAXUPLOAD_HTTPDOCS};
}

sub ajax_upload_setup {
    my $self = shift;
    my %args = @_;

    my $upload_subdir = $args{upload_subdir} || '/img/uploads';
    my $dfv_profile = $args{dfv_profile};
    my $filename_gen = $args{filename_gen};
    my $run_mode = $args{run_mode} || 'ajax_upload_rm';

    $self->run_modes(
        $run_mode => sub {
            my $c = shift;
            my $r = eval {
                $c->_ajax_upload_rm(
                    $upload_subdir,
                    $dfv_profile,
                    $filename_gen
                );
            };
            if ($@) {
                carp $@;
                return $c->json_body({status=> 'Internal Error'});
            }
            return $r;
        }
    );

    return;
}

sub _ajax_upload_rm {
    use autodie qw(open close);
    my $self = shift;
    my $upload_subdir = shift;
    my $dfv_profile = shift;
    my $filename_gen = shift;
    my $httpdocs_dir = $self->ajax_upload_httpdocs;  

    return $self->json_body({status => 'No document root specified'})
        if not defined $httpdocs_dir;

    my $full_upload_dir = "$httpdocs_dir/$upload_subdir";
    my $query = $self->query;

    if ($query->param('validate')) {

        return $self->json_body({status => 'Document root is not a directory'})
            if not -d $httpdocs_dir;

        return $self->json_body({status => 'Upload folder is not a directory'})
            if not -d $full_upload_dir;

        return $self->json_body({status => 'Upload folder is not writeable'})
            if not -w $full_upload_dir;
        
    }

    my $upload = CGI::Upload->new({query=>$query});
    my $fh = $upload->file_handle('file');
    return $self->json_body({status => 'No file handle returned'})
        if not $fh;

    my $value = slurp $fh;
    $value =~ /^(.*)$/;
    $value = $1;
    return $self->json_body({status => 'No data uploaded'}) if not $value;
    close $fh;

    my $filename =  $upload->file_name('file');
    if ($filename_gen) {
        $filename = &$filename_gen($filename);
    }
    $filename =~ /^(.*)$/;
    $filename = $1;
    
    open $fh, '>', "$full_upload_dir/$filename";
    print {$fh} $value;
    close $fh;

    return $self->json_body({status=>'SUCCESS',url=>"$upload_subdir/$filename"});
}

1; # Magic true value required at end of module
__END__

=head1 NAME

CGI::Application::Plugin::AJAXUpload - Run mode to handle a file upload and return a JSON response

=head1 VERSION

This document describes CGI::Application::Plugin::AJAXUpload version 0.0.1

=head1 SYNOPSIS

    use MyWebApp;
    use CGI::Application::Plugin::JSON qw(json_body to_json);
    use CGI::Application::Plugin::AJAXUpload;

    sub setup {
        my $c = shift;
        $c->ajax_upload_httpdocs('/var/www/vhosts/mywebapp/httpdocs');

        $c->ajax_upload_setup(
            run_mode=>'file_upload',
            upload_subdir=>'/img/uploads',
        );
        return;
    }

=head1 DESCRIPTION

This module provides a customizable run mode that handles a file upload
and responds with a JSON message like the following:

    {status: 'UPLOADED', image_url: '/img/uploads/666.png'}

or on failure

    {status: 'The image was too big.'}

This is specifically intended to provide a L<CGI::Application> based back
end for L<AllMyBrain.com|http://allmybrain.com>'s 
L<image upload extension|http://allmybrain.com/2007/10/16/an-image-upload-extension-for-yui-rich-text-editor> to the
L<YUI rich text editor|http://developer.yahoo.com/yui/editor>. However as far as
I can see it could be used as a back end for any L<CGI::Application> website that uploads files behind the scenes using AJAX. In any case this module does NOT
provide any of that client side code and you must also map the run mode onto the URL used by client-side code.

It can also hand validation of the image to L<Data::FormValidator> style objects
and allows callbacks to modify exactly how the file is stored.

=head1 INTERFACE 

=head2 ajax_upload_httpdocs

The module needs to know the document root because it will need to
to copy the file to a sub-directory of the document root,
and it will need to pass that sub-directory back to the client as part
of the URL. If passed a value it will store that as the document root.
If not passed a value it will return the document root.

=head2 ajax_upload_setup

This method sets up a run mode to handle a file upload
and return a JSON message providing status. It takes a number of named
parameters:

=over

=item upload_subdir

This is the sub-directory of C<httpdocs_dir> where the files will actually
be written to. It must be writeable. It defaults to '/img/uploads'.

=item dfv_profile

This is L<Data::FormValidator> profile. If it is not set the data will be taken on trust.

=item filename_gen

This is a callback method that will be given in order: the CGI application
object  and the file name as given by the upload data. It must return the 
actual name that the file name is to be stored under. If not set the given
name will be used and any existing files of that name might be overwritten.
This method can be used also to do additional housekeeping.

=item run_mode

This is the name of the run mode that will handle this upload. It defaults to
'ajax_upload_rm'.

=back

=head2 _ajax_upload_rm

This forms the implementation of the run mode. It requires a C<file>
parameter that provides the file data. Optionally it also takes a
C<validate> parameter that will check all the file permissions.

It takes the following actions:

=over 

=item --

If the C<validate> parameter is set the setup will check. If there
is a problem a status message will be passed back to the user.

=item --

It will get the filename and data associated with the upload and 
pass the data through the L<Data::FormValidator> if a profile is 
supplied.

=item --

If it fails the L<Data::FormValidator> test a failed message will be passed
back to the caller.

=item --

The filename will be passed through the file name generator.

=item --

The data will then be copied to the given file, its path being the 
combination of the C<httpdocs_dir> parameter, the
C<upload_subdir> and the generated file name.

=item - 

The successful JSON message will be passed back to the client.

=back

=head1 DIAGNOSTICS

=item C<< no httpdocs_dir specified >>

A C<httpdocs_dir> parameter must be specified in the C<ajax_upload_setup>
method.

=item C<< %s is not a directory >>

The C<httpdocs_dir> parameter must be a directory.

=item C<< %s is not writeable >>

The C<upload_subdir> parameter must be a writeable directory.

=back


=head1 CONFIGURATION AND ENVIRONMENT

CGI::Application::Plugin::AJAXUpload requires no configuration files or environment variables. However the client side code and the URL to run mode dispatching
is not supplied.

=head1 DEPENDENCIES

This depends on version 1.02 of L<CGI::Application::Plugin::JSON>. Earlier
versions might work but they produce different headers which break the tests.
One must load the JSON plugin in the web application code as shown in the
synopsis.

=head1 BUGS AND LIMITATIONS

For the moment there is no intention to support CGI engines other than
L<CGI>. That may come in the future however each of those modules
has a different interface.

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-ajaxupload@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
