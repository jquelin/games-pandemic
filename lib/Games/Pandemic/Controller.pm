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
use Games::Pandemic::Player;

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

event action => sub {
    my $action = $_[ARG0];
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;

    # FIXME: check src vs current player

    $K->yield("_action_$action");
 };


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

    # create the players
    # FIXME: by now we're creating a fixed set of players, should be
    # configurable
    # FIXME: initial number of card depends of map / number of players
    $K->yield( _new_player => 'Scientist', 4 );
    $K->yield( _new_player => 'OperationsExpert', 4 );
#    $K->yield( _new_player => 'Medic', 4 );
#    $K->yield( _new_player => 'Researcher', 4 );
#    $K->yield( _new_player => 'Dispatcher', 4 );

    # signal main window that we have started a new game
    $K->post( 'main' => 'new_game' );

    # start the game
    $K->yield( '_next_player' );
};


# -- private event

#
# event: _action_done()
#
# action is finished.
#
event _action_done => sub {
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;

    $player->action_done;
    # FIXME: update gui

   my $event = $player->actions_left == 0 ? '_draw_cards' : '_next_action';
    $K->yield( $event );
};


#
# event: _action_pass()
#
# user wishes to pass.
# 
event _action_pass => sub {
    # nothing to do - user is just passing
    $K->yield('_action_done');
};


#
# _deal_card( $player, $nb );
#
# deal $nb cards to $player. check whether player has too much cards in
# her hands, and also for game over condition.
#
event _deal_card => sub {
    my ($player, $nb) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->cards;

    # deal some cards to the players
    foreach my $i ( 1 .. $nb ) {
        my $card = $deck->next;
        $player->give_card($card);
        $K->post(main=>'got_card', $player, $card);
    }

    # FIXME: game over if no more card
    # FIXME: if player has too much cards
};

#
# event: _draw_cards()
#
# sent when player needs to draw her cards.
#
event _draw_cards => sub {
    $K->yield( '_propagate' );
};


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

    # update the disease
    $disease->take($nb);
    #if ( $disease->nbleft <= 0 ) { # FIXME: gameover }

    # perform the infection & update the gui
    my $outbreak = $city->infect($nb, $disease);
    $K->post( main => 'infection', $city, $outbreak );

    return unless $outbreak;
    # FIXME: outbreak!
};


#
# event: _new_player( $role, $nb )
#
# request to create & store a new player, having $role and starting with
# $nb cards.
#
event _new_player => sub {
    my ($role, $nbcards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;

    $role = "Games::Pandemic::Role::$role";
    my $player = Games::Pandemic::Player->new_with_traits(traits=>[$role]);
    $game->add_player($player);
    $K->post( main => 'new_player', $player );
    $K->yield( '_deal_card', $player, $nbcards );
};


#
# event: _next_action()
#
# sent for player to continue its turn
#
event _next_action => sub {
    $K->post( main => 'next_action' );
};


#
# event: _next_player( $player )
#
# sent when $player should start to play its turn.
#
event _next_player => sub {
    my $game = Games::Pandemic->instance;

    my $player = $game->next_player;
    if ( not defined $player ) {
        $game->reinit_players( $game->all_players );
        $player = $game->next_player;
    }
    $game->set_curplayer( $player );

    $player->set_actions_left(4);
    $K->post( main => 'next_player', $player );
    $K->yield( '_next_action' );
};


#
# event: _propagate()
#
# sent to do the regular disease propagation.
#
event _propagate => sub {
    $K->yield( '_next_player' );
};


no Moose;
# singleton classes cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

START

=end Pod::Coverage
