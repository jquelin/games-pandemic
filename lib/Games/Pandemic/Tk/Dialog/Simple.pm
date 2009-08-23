use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog::Simple;
# ABSTRACT: generic pandemic dialog

use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;


# -- accessors

has text   => ( is=>'ro', isa=>'Str', required=>1 );
has icon   => ( is=>'ro', isa=>'Str' );


# -- initialization

sub _build__cancel { T('Close') }


# -- private methods

#
# dialog->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;

    # icon + text
    my $f = $top->Frame->pack(@TOP,@XFILL2);
    $f->Label(-image => image($self->icon,$top))->pack(@LEFT, @FILL2, @PAD10)
        if defined $self->icon;
    $f->Label(
        -text       => $self->text,
        -justify    => 'left',
        -wraplength => '6c',
    )->pack(@LEFT, @XFILL2, @PAD10);
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => $title,
        header => $header,
        icon   => $image,
        text   => $texte,
    );

=head1 DESCRIPTION

This module implements a very simple dialog window, to display various
information on the current game state. It only has a close button, since
it does not implement any action.

The only mandatory paramater (beside C<parent> of course) is C<text>.
