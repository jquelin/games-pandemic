package Games::Pandemic::Tk::Dialog::GiveCard;
# ABSTRACT: sharing dialog window for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;

Readonly my $K => $poe_kernel;


# -- accessors

has cards => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has players => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has _card   => ( is=>'rw', weak_ref=>1, isa=>'Games::Pandemic::Card::City' );
has _player => ( is=>'rw', weak_ref=>1, isa=>'Games::Pandemic::Player' );


# -- initialization

sub _build_title   { T('Sharing') }
sub _build_header  { T('Give a card') }
sub _build__ok     { T('Give') }
sub _build__cancel { T('Cancel') }


# -- gui methods

#
# $dialog->_valid;
#
# request to give a card & destroy the dialog.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'action', 'share', $self->_card, $self->_player );
    $self->_close;
}


# -- private methods

#
# $main->_valid;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;

    my $fcenter = $top->Frame->pack(@TOP, @XFILL2);


    # if more than one player, select which one will receive the card
    my @players = $self->players;
    $self->_set_player( $players[0] );
    if ( @players > 1 ) {
        # enclose players in their own frame
        my $f = $fcenter->Frame->pack(@LEFT, @PAD10, -anchor=>'nw');
        $f->Label(
            -text   => T('Select player receiving the card:'),
            -anchor => 'w',
        )->pack(@TOP, @FILLX);

        # display cards
        my $selplayer = $self->_player->role;
        foreach my $player ( @players ) {
            # to display a radiobutton with image + text, we need to
            # create a radiobutton with a label just next to it.
            my $fplayer = $f->Frame->pack(@TOP, @FILLX);
            my $rb = $fplayer->Radiobutton(
                -text     => $player->role,
                -variable => \$selplayer,
                -value    => $player->role,
                -anchor   => 'w',
                -command  => sub{ $self->_set_player($player); },
            )->pack(@LEFT, @XFILLX);
            my $lab = $fplayer->Label(
                -image    => image( $player->image('icon', 32), $top ),
            )->pack(@LEFT);
            $lab->bind( '<1>', sub { $rb->invoke; } );
        }
    }

    # if more than one card, select which one to give
    my @cards = $self->cards;
    $self->_set_card( $cards[0] );
    if ( @cards > 1 ) {
        # enclosed cards in their own frame
        my $f = $fcenter->Frame->pack(@LEFT, @FILLX, @PAD10, -anchor=>'nw');
        $f->Label(
            -text   => T('Select city card to give:'),
            -anchor => 'w',
        )->pack(@TOP, @FILLX);

        # display cards
        my $selcard = $self->_card->label;
        foreach my $card ( @cards ) {
            # to display a radiobutton with image + text, we need to
            # create a radiobutton with a label just next to it.
            my $fcity = $f->Frame->pack(@TOP, @FILLX);
            my $rb = $fcity->Radiobutton(
                -image    => image($card->icon, $top),
                -variable => \$selcard,
                -value    => $card->label,
                -command  => sub { $self->_set_card($card); },
            )->pack(@LEFT);
            my $lab = $fcity->Label(
                -text   => $card->label,
                -anchor => 'w',
            )->pack(@LEFT, @FILLX);
            $lab->bind( '<1>', sub { $rb->invoke; } );
        }
    }
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage


