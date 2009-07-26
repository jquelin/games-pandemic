package Games::Pandemic::Tk::PlayerCards;
# ABSTRACT: window holding player cards for Games::Pandemic

use 5.010;
use strict;
use warnings;

use List::Util qw{ max };
use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Tk::Utils;
use Games::Pandemic::Utils;

# -- attributes & accessors

has parent    => ( is=>'ro', required=>1, weak_ref=>1, isa=>'Tk::Widget' );
has _toplevel => ( is=>'rw', isa=>'Tk::Toplevel', handles => [ qw{ destroy } ] );

# a hash with all the widgets, for easier reference.
has _widgets => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => {
        set    => '_set_w',
        get    => '_w',
        delete => '_del_w',
    },
);


# -- initialization

#
# BUILD()
#
# called during object initialization.
#
sub BUILD {
    my $self = shift;
    $self->_build_gui;
}


#
# DEMOLISH()
#
# called as destructor
#
sub DEMOLISH {
    my $self = shift;
    debug( "~player cards: $self\n" );
}


# -- public methods

=method $pcards->new_player( $player );

Request to add a new C<$player> to the window.

=cut

sub new_player {
    my ($self, $player) = @_;

    # create the frame holding the player
    my $top   = $self->_toplevel;
    my $frame = $top->Frame->pack(@LEFT, @XFILL2);

    my $ftitle = $frame->Frame->pack(@TOP, @FILLX);
    $ftitle->Label( -image => image( $player->image('icon', 32), $top ) )->pack(@LEFT);
    $ftitle->Label( -text  => $player->role )->pack(@LEFT);

    my $fcards = $frame->Frame->pack(@TOP, @XFILL2);
    $self->_set_w("cards_$player", $fcards);
}


# -- private methods

#
# dialog->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $parent = $self->parent;

    my $top = $parent->Toplevel;
    $self->_set_toplevel($top);
    $top->withdraw;

    # compute window width
    my @cards = $game->map->cards;
    my $font = $top->Font;
    my $max = max map { $font->measure($_->label) } @cards;
    my $width  = $max * 3; # FIXME: depends on number of players
    my $height = 32 * 10;  # FIXME: depends on max cards
    $top->geometry("${width}x${height}");

    # window title
    $top->title( T('Cards') );
    $top->iconimage( pandemic_icon($top) );

    # center window & make it appear
    $top->Popup( -popover => $parent );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD
DEMOLISH

=end Pod::Coverage
