package CGI::Application::Plugin::AJAXUpload;

use warnings;
use strict;
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(
    ajax_upload_setup
    ajax_upload_rm
);

use version; our $VERSION = qv('0.0.1');

# Module implementation here

sub ajax_upload_setup {
    my $self = shift;

    my %args = @_;

    croak "no httpdocs_dir specified" if not exists $args{httpdocs_dir};
    my $httpdocs_dir = $args{httpdocs_dir};
    croak "$httpdocs_dir is not a directory" if not -d $httpdocs_dir;

    my $upload_subdir = '/img/uploads';
    if (exists $args{upload_subdir}) {
        $upload_subdir = $args{upload_subdir};
    }
    my $full_upload_dir = "$httpdocs_dir/$upload_subdir";
    croak "$full_upload_dir is not a directory" if not -d $full_upload_dir;
    croak "$full_upload_dir is not writeable" if not -w $full_upload_dir;

    my $dfv_profile = $args{dfv_profile};
    my $filename_gen = $args{filename_gen};
    my $run_mode = 'ajax_upload_rm';
    if (exists $args{run_mode}) {
        $run_mode = $args{run_mode};
    }

    $self->run_modes(
        $run_mode => sub {
            my $c = shift;
            return $c->ajax_upload_rm($httpdocs_dir,
                                        $upload_subdir,
                                        $dfv_profile,
                                        $filename_gen
            );
        }
    );

    return;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

CGI::Application::Plugin::AJAXUpload - Run mode to handle a file upload and return a JSON response

=head1 VERSION

This document describes CGI::Application::Plugin::AJAXUpload version 0.0.1

=head1 SYNOPSIS

    use MyWebApp;
    use CGI::Application::Plugin::AJAXUpload;

    sub setup {
        my $c = shift;
        $c->ajax_upload_setup(
            run_mode=>'file_upload',
            httpdocs_dir=>'/var/www/vhosts/mywebapp/httpdocs',
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

=head2 ajax_upload_setup

This method takes a number of named parameters

=over

=item httpdocs_dir

This is the physical path of the directory storing the static files.
If it does not exist an error will be thrown.

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

=head2 ajax_upload_rm

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

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

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
