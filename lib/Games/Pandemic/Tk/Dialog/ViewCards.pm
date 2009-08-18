use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog::ViewCards;
# ABSTRACT: dialog window to show cards

use List::Util qw{ max };
use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;


# -- accessors

has cards => (
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    required   => 1,
    auto_deref => 1,
);


# -- initialization

sub _build_resizable { 1 }
sub _build__cancel   { T('Close') }



# -- private methods

#
# $main->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self  = shift;
    my $top   = $self->_toplevel;
    my @cards = $self->cards;

    # compute a minimum length, for a nice outlook on the eye. we do
    # that by multiplying by the magic number 4, making the window
    # neither too narrow nor too big. ymmv, but i like it this way! :-)
    my $max   = max map { length $_->label } @cards;
    my $width = $max * 4;

    # main elements
    $top->Label(-text=>'(more recent)', -width=>$width)->pack(@TOP, @FILLX, @PAD2);
    my $f = $top->Scrolled('Frame', -scrollbars=>'oe')->pack(@TOP, @XFILL2, @PAD2);
    $top->Label(-text=>'(older)')->pack(@TOP, @FILLX, @PAD2);

    # display cards
    foreach my $card ( reverse @cards ) {
        # to display a checkbutton with image + text, we need to
        # create a checkbutton with a label just next to it.
        my $fcard = $f->Frame->pack(@TOP, @FILLX);
        $fcard->Label( -image => image($card->icon, $top) )->pack(@LEFT);
        $fcard->Label( -text  => $card->label, -anchor => 'w' )->pack(@LEFT, @FILLX);
    }
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage


