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
event new_game => sub {
    my $game = Games::Pandemic->instance;

    # create the map
    my $map = Games::Pandemic::Map::Pandemic->new;
    $game->set_map( $map );

    # create the infection deck
    my @cards = shuffle $map->disease_cards;
    my $infection = Games::Pandemic::Deck->new( cards => \@cards );
    $game->set_infection( $infection );

    $K->post( 'main' => 'new_game' );
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
