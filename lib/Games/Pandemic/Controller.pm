package Games::Pandemic::Controller;
# ABSTRACT: controller for a pandemic game

use 5.010;
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

sub START {
    $K->alias_set('controller');
}

# -- public events

#
# new_game()
#
# create a new game: (re-)initialize the map, and various internal states.
#
event new_game => sub {
    my $game = Games::Pandemic->instance;

    # create the map
    my $map = Games::Pandemic::Map::Pandemic->new;
    $game->set_map( $map );

    # create the infection deck
    my @pcards = shuffle $map->disease_cards;
    my $cards  = Games::Pandemic::Deck->new( cards => \@pcards );
    $game->set_cards( $cards );

    # create the infection deck
    my @icards = shuffle $map->disease_cards;
    my $infection = Games::Pandemic::Deck->new( cards => \@icards );
    $game->set_infection( $infection );

    # signal main window that we have started a new game
    $K->post( 'main' => 'new_game' );
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
