use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog::Action;
# ABSTRACT: pandemic dialog to confirm an action

use Moose;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;

extends 'Games::Pandemic::Tk::Dialog::Simple';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;

Readonly my $K => $poe_kernel;


# -- accessors

has action    => ( is=>'ro', isa=>'Str', required=>1 );
has post_args => ( is=>'ro', isa=>'ArrayRef', required=>1 );


# -- initialization

sub _build__ok     { $_[0]->action }
sub _build__cancel { T('Cancel') }


# -- private methods

#
# $dialog->_valid;
#
# request to perform the action.
#
sub _valid {
    my $self = shift;
    my $args = $self->post_args;
    $K->post( @$args );
    $self->_close;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::Action->new(
        parent    => $mw,
        title     => $title,       # optional
        header    => $header,      # optional
        icon      => $image,       # optional
        text      => $text,
        action    => $label,
        post_args => $postargs,
    );

=head1 DESCRIPTION

This module implements a dialog window asking the user whether she
wants to perform an action or not. One can give more information with
the text and icon.

It has a cancel button to close the dialog, and a C<$label> action
button that will perform a L<POE::Kernel> post with the C<$postargs>.
