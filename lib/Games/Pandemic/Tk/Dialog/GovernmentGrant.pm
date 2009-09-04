use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog::GovernmentGrant;
# ABSTRACT: dialog window to play a government grant

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;
use Tk::Tiler;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;

Readonly my $K    => $poe_kernel;
Readonly my $GREY => '#666666';


# -- accessors

has player   => ( is=>'rw', isa=>'Games::Pandemic::Player', required=>1 );
has card     => ( is=>'rw', isa=>'Games::Pandemic::Card', required=>1 );
has _selcard => ( is=>'rw', isa=>'Games::Pandemic::Card' );

has _selected => (
    is         => 'rw',
    isa        => 'ArrayRef[Tk::Widget]',
    predicate  => '_has_selected',
    auto_deref => 1,
);

# -- initialization

sub _build_header    { $_[0]->card->label }
sub _build_resizable { 1 }
sub _build_title     { T('Special event') }
sub _build__ok       { T('Build') }
sub _build__cancel   { T('Cancel') }



# -- private methods

#
# $main->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;
    my $card = $self->card;

    # icon + text
    my $f   = $top->Frame->pack(@TOP,@FILLX);
    my $img  = image( catfile($SHAREDIR, 'cards', 'government-grant-48.png') );
    $f->Label(-image => $img)->pack(@LEFT, @FILL2, @PAD10);
    $f->Label(
        -text       => $card->description,
        -justify    => 'left',
    )->pack(@LEFT, @FILLX, @PAD10);

    # main elements
    my $text = T('Select city in which to build the new research station:');
    $top->Label(-text => $text, -anchor=>'w')->pack(@TOP,@FILLX, @PAD5);
    my $tiler = $top->Scrolled( 'Tiler',
        -scrollbars => 'oe',
        -rows       => 8,
        -columns    => 3,
    )->pack(@TOP, @XFILL2, @PAD2);

    # display cards
    my @citycards =
        sort { $a->city->disease->name cmp $b->city->disease->name
            || $a->label cmp $b->label }
        Games::Pandemic->instance->map->disease_cards;

    foreach my $card ( @citycards ) {
        # to display a checkbutton with image + text, we need to
        # create a checkbutton with a label just next to it.
        my $fcard = $tiler->Frame;
        my $img = $fcard->Label( -image => image($card->icon, $top) )->pack(@LEFT);
        my $lab = $fcard->Label( -text  => $card->label, -anchor => 'w' )->pack(@LEFT, @FILLX);
        $_->bind('<1>', [$self, '_select_city', $card, $fcard, $img, $lab] )
            for ($img, $lab, $fcard);
        $tiler->Manage($fcard);
    }
};


#
# $ggd->_select_city( $card, $fcard, $img, $lab );
#
# Called when one of the frame ($fcard), image ($img) or label ($lab)
# representing the $card has been selected. Hilight the new widgets, un-
# hilight the old widgets and store the new card selected.
#
sub _select_city {
    my ($self, $card, $fcard, $img, $lab) = @_;

    # store new selected card
    $self->_set_selcard($card);

    # remove previous selection
    my $bg = $fcard->cget('-bg');
    if ( $self->_has_selected ) {
        my @old = $self->_selected;
        $_->configure(-bg=>$bg) for @old;
    }

    # add selection
    my @new = ($img, $lab, $fcard);
    $self->_set_selected( \@new );
    $_->configure(-bg=>$GREY) for @new;
}


#
# $ggd->_valid;
#
#
# called when the action button has been clicked. Request the controller
# to play the card and build a research station in the selected city.
#
sub _valid {
    say "ici";
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::GovernmentGrant->new(
        parent => $mw,
        card   => $card,        # special govt grant card
        player => $player,      # player owning it
    );


=head1 DESCRIPTION

This dialog implements a dialog to let the user choose in which city to
build a research station when playing a
L<Games::Pandemic::Card::Special::GovernmentGrant> card.

The card should be passed in the constructor, along with the player
holding the card.
