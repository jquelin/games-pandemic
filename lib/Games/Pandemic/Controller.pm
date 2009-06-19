package Games::Pandemic::Controller;
# ABSTRACT: controller for a pandemic game

use 5.010;
use strict;
use warnings;

use List::Util qw{ shuffle };
use MooseX::Singleton;  # should come before any other moose
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;

use Games::Pandemic::Deck;
use Games::Pandemic::Map::Pandemic;

Readonly my $K  => $poe_kernel;

# -- accessors

# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    $K->alias_set('controller');
}

# -- public events

=method event: new_game()

Create a new game: (re-)initialize the map, and various internal states.

=cut

event new_game => sub {
    my $game = Games::Pandemic->instance;

    # create the map
    my $map = Games::Pandemic::Map::Pandemic->new;
    $game->set_map( $map );

    # 5 research stations available. FIXME: should it be part of the map?
    $game->set_stations( 5 );

    # create the player cards deck
    my @pcards = shuffle $map->cards;
    my $pcards = Games::Pandemic::Deck->new( cards => \@pcards );
    $game->set_cards( $pcards );

    # create the infection deck
    my @icards = shuffle $map->disease_cards;
    my $icards = Games::Pandemic::Deck->new( cards => \@icards );
    $game->set_infection( $icards );

    # do the initial infections
    foreach my $nb ( $map->start_diseases ) {
        my $card = $icards->next;
        $K->yield( _infect => $card->city, $nb );
        $icards->discard( $card );
    }

    # signal main window that we have started a new game
    $K->post( 'main' => 'new_game' );
};


# -- private event

#
# _infect( $city [, $nb [, $disease ] ] );
#
# infect $city with $nb items of $disease. perform an outbreak on
# neighbour cities if needed. $nb defaults to 1, $disease defaults to
# the city default disease.
#
event _infect => sub {
    my ($city, $nb, $disease) = @_[ARG0..$#_];
    $nb      //= 1;
    $disease //= $city->disease;

    # perform the infection & update the gui
    my $outbreak = $city->infect($nb, $disease);
    $K->post( main => 'infection', $city, $outbreak );

    return unless $outbreak;
    # FIXME: outbreak!
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

START

=end Pod::Coverage
