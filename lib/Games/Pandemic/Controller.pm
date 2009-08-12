package Games::Pandemic::Controller;
# ABSTRACT: controller for a pandemic game

use 5.010;
use strict;
use warnings;

use List::Util      qw{ shuffle };
use List::MoreUtils qw{ all };
use MooseX::Singleton;  # should come before any other moose
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;

use Games::Pandemic::Card::Epidemic;
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
    my ($action, @params) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;

    # FIXME: check src vs current player

    $K->yield("_action_$action", @params);
};


=method event: close()

Player has closed current game.

=cut

event close => sub {
    my $game = Games::Pandemic->instance;
    $game->clear_map;
    $game->clear_cards_deck;
    $game->clear_infection_deck;
    $game->clear_players;
    $game->clear_players_in_turn;
    $game->clear_curplayer;
    $game->clear_too_many_cards;
    $game->has_ended;
};


=method event: continue()

Player wishes to move game forward.

=cut

event continue => sub {
    my $game = Games::Pandemic->instance;
    # FIXME: check src vs current player
    given ( $game->state ) {
        when ('end_of_actions')     { $K->yield('_draw_cards' ); }
        when ('end_of_cards')       { $K->yield('_propagate'  ); }
        when ('end_of_propagation') { $K->yield('_next_player'); }
    }
};


=method event: drop_cards( $player, @cards )

Request from C<$player> to remove some C<@cards> from her hands.

=cut

event drop_cards => sub {
    my ($player, @cards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $deck = $game->cards;

    # FIXME: check src vs $player

    # remove cards from player hands
    foreach my $card ( @cards ) {
        $player->drop_card( $card );
        $deck->discard( $card );
        $K->post( main => 'drop_card', $player, $card );
    }

    # check again that there are not too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
        return;
    }

    $K->yield( $game->next_step ) if $game->too_many_cards;
    $game->clear_too_many_cards;
};


=method event: new_game()

Create a new game: (re-)initialize the map, and various internal states.

=cut

event new_game => sub {
    my $game = Games::Pandemic->instance;
    $game->has_started;

    # create the map
    my $map = Games::Pandemic::Map::Pandemic->new;
    $game->set_map( $map );

    # 5 research stations available. FIXME: should it be part of the map?
    $game->set_stations( 5 );

    # create the player cards deck
    my @pcards = shuffle $map->cards;
    {
        # insert epidemic cards
        my $nbinit = 12;   # FIXME: 3 players * 4 cards, should not be fixed
        my $epidemics = 4; # FIXME: depends on game difficulty
        my $nbleft  = scalar(@pcards) - $nbinit;
        my $perheap = int( $nbleft / $epidemics );
        foreach my $i ( 0 .. $epidemics-1 ) {
            my $offset = $i * $perheap + int( rand($perheap) );
            splice @pcards, $offset, 0, Games::Pandemic::Card::Epidemic->new;
        }
    }
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

    # create the players
    # FIXME: by now we're creating a fixed set of players, should be
    # configurable
    # FIXME: initial number of card depends of map / number of players
    $K->yield( _new_player => 'Researcher', 4 );
    $K->yield( _new_player => 'Scientist', 4 );
    #$K->yield( _new_player => 'Medic', 4 );
    #$K->yield( _new_player => 'Dispatcher', 4 );
    #$K->yield( _new_player => 'OperationsExpert', 4 );

    # start the game
    $K->yield( '_next_player' );
};


# -- private event

#
# event: _action_build()
#
# request to build a research station.
#
event _action_build => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    # invalid request
    return $K->yield('_next_action')
        unless $curp->is_build_possible;
    # FIXME: check research station count

    # build station
    my $city = $curp->location;
    $city->build_station;
    $game->dec_stations;
    $K->post( main => 'build_station', $city );

    # player loose a card
    if ( not $curp->can_build_anywhere ) {
        my $card = $curp->owns_city_card($city);
        $curp->drop_card( $card );
        $game->cards->discard( $card );
        $K->post( main => 'drop_card', $curp, $card );
    }

    $K->yield('_action_done');
};


#
# event: _action_charter($player, $city)
#
# request to charter $player to $city.
#
event _action_charter => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    # get the card
    my $card = $curp->owns_city_card($player->location);
    return $K->yield('_next_action') unless defined $card;

    # move the player
    my $from = $player->location;
    $player->set_location($city);
    $K->post( main => 'player_move', $player, $from, $city );
    $K->yield('_action_done');

    # drop the card
    $curp->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $curp, $card );
};


#
# event: _action_treat($disease)
#
# request to treat $disease from current player location.
#
event _action_treat => sub {
    my $disease = $_[ARG0];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $city = $curp->location;

    my $nb = $city->get_infection($disease);
    return $K->yield('_next_action') if $nb == 0;

    my $nbtreat = $curp->treat_all # FIXME: cure discovered
        ? $nb
        : 1;

    $city->treat($disease, $nbtreat);
    $disease->return($nbtreat);

    $K->post( main => 'treatment', $city );
    $K->yield('_action_done');
};


#
# event: _action_discover($disease, @cards)
#
# request to discover a cure.
#
event _action_discover => sub {
    my ($disease, @cards) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $deck = $game->cards;

    # various checks
    return $K->yield('_next_action')
        if $disease->is_cured                                # nothing to do
        || !$curp->location->has_station                     # no research station
        || scalar(@cards) != $curp->cards_needed             # not enough cards
        || not(all { $_->isa('Games::Pandemic::Card::City') } @cards) # not the right cards
        || not(all { $curp->owns_card($_) } @cards)          # not the right player
        || not(all { $_->city->disease eq $disease } @cards) # wrong cards
        ;

    # yup, we can exchange cards for a cure
    foreach my $card ( @cards ) {
        $curp->drop_card($card);
        $deck->discard($card);
        $K->post( main => 'drop_card', $curp, $card );
    }
    $disease->cure;
    $K->post( main => 'cure', $disease );

    # FIXME: golden cure

    # check if game is won
    return $K->yield('_all_cures_discovered')
        if all { $_->is_cured } $game->map->all_diseases;

    $K->yield('_action_done');
};


#
# event: _action_done()
#
# action is finished.
#
event _action_done => sub {
    my $game = Games::Pandemic->instance;

    # turn is done
    my $curp = $game->curplayer;
    $curp->action_done;
    $K->post( main => 'action_done' );

    # next step would be...
    my $event = $curp->actions_left == 0 ? '_end_of_actions' : '_next_action';

    # ... unless a player has too many cards
    foreach my $player ( $game->all_players ) {
        next if $player->nb_cards <= $player->max_cards;
        $game->set_too_many_cards($player);
        $game->set_next_step($event);
        $K->post( main => 'too_many_cards', $player );
        return;
    }

    # everything's fine, we can continue
    $K->yield( $event );
};


#
# event: _action_fly($player, $city)
#
# request to fly $player to $city.
#
event _action_fly => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    # get the card
    my $card = $curp->owns_city_card($city);
    return $K->yield('_next_action') unless defined $card;

    # move the player
    my $from = $player->location;
    $player->set_location($city);
    $K->post( main => 'player_move', $player, $from, $city );
    $K->yield('_action_done');

    # drop the card
    $curp->drop_card( $card );
    $game->cards->discard( $card );
    $K->post( main => 'drop_card', $curp, $card );
};


#
# event: _action_move($player, $city)
#
# request to move $player to $city by proximity.
#
event _action_move => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    if ( $player->can_travel_to($city) ) {
        my $from = $player->location;
        $player->set_location($city);
        $K->post( main => 'player_move', $player, $from, $city );
        $K->yield('_action_done');
    } else {
        # invalid move
        $K->yield('_next_action');
    }
};


#
# event: _action_pass()
#
# user wishes to pass.
# 
event _action_pass => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    # nothing to do - user is just passing
    $curp->set_actions_left(0);
    $K->post( main => 'action_done' );
    $K->yield( '_end_of_actions' );
};


#
# event: _action_share($card, $player)
#
# request to give $card to $player.
#
event _action_share => sub {
    my ($card, $player) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $city = $curp->location;

    return $K->yield('_next_action') if $player eq $curp;
    return $K->yield('_next_action') if $player->location ne $city;
    return $K->yield('_next_action') unless $curp->owns_card($card);
    return $K->yield('_next_action') unless $card->isa('Games::Pandemic::Card::City');
    return $K->yield('_next_action') unless $card->city eq $city || $curp->can_share_anywhere;

    # give the card
    $curp->drop_card( $card );
    $player->gain_card( $card );
    $K->post( main => 'drop_card', $curp, $card );
    $K->post( main => 'gain_card', $player, $card );

    $K->yield('_action_done');
};


#
# event: _action_shuttle($player, $city)
#
# request to move $player to $city by research station shuttle.
#
event _action_shuttle => sub {
    my ($player, $city) = @_[ARG0..$#_];
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    return $K->yield('_next_action')
        if $player ne $curp; # FIXME: dispatcher

    # get the card
    return $K->yield('_next_action') unless $player->can_shuttle_to($city);

    # move the player
    my $from = $player->location;
    $player->set_location($city);
    $K->post( main => 'player_move', $player, $from, $city );
    $K->yield('_action_done');
};


#
# event: _all_cures_discovered()
#
# sent when game has been won.
#
event _all_cures_discovered => sub {
    $K->post( main => 'all_cures_discovered' );
    $K->yield( '_game_over' );
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

        if ( not defined $card ) {
            # no more cards - game is over
            $K->yield('_no_more_cards');
            return;
        }

        # check if we hit a new epidemic
        if ( $card->isa('Games::Pandemic::Card::Epidemic') ) {
            $K->yield( '_epidemic' );
            next;
        }

        # regular card, dealing it to player
        $player->gain_card($card);
        $K->post(main=>'gain_card', $player, $card);
    }

    # check if player has too much cards
    if ( $player->nb_cards > $player->max_cards ) {
        $game->set_too_many_cards($player);
        $K->post( main => 'too_many_cards', $player );
    }
};


#
# event: _draw_cards()
#
# sent when player needs to draw her cards.
#
event _draw_cards => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    # FIXME: is 2 cards fixed or map-dependant?
    $K->yield( '_deal_card', $curp, 2 );

    $game->set_state('end_of_cards');
    $K->post( main => 'end_of_cards' );
};


#
# event: _game_over()
#
# sent when game is over (either win or loose), user cannot do anything
# but close the game.
#
event _game_over => sub {
    my $game = Games::Pandemic->instance;
    $game->has_ended;
    $K->post( main => 'game_over' );
};


#
# event: _end_of_actions()
#
# sent when player finished her actions
#
event _end_of_actions => sub {
    my $game = Games::Pandemic->instance;
    $game->set_state('end_of_actions');
    $K->post( main => 'end_of_actions' );
};


#
# event: _epidemic()
#
# an epidemic card has been drawn.
#
event _epidemic => sub {
    my $game = Games::Pandemic->instance;
    my $deck = $game->infection;

    # epidemic first strikes hard a new city...
    my $card = $deck->last;
    my $city = $card->city;
    $K->yield( '_infect', $city, 3 );
    $K->post( main => 'epidemic', $city );

    # then already hit cities ready for a new turn...
    my @cards = $deck->past;
    push @cards, $card;
    $deck->clear_pile;
    $deck->refill( shuffle @cards );

    # FIXME: update infection rate
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
    if ( $disease->nbleft <= 0 ) {
        $K->yield('_no_more_cubes', $disease);
        return;
    }

    # perform the infection & update the gui
    my $outbreak = $city->infect($nb, $disease);
    # FIXME: update outbreak
    # FIXME: gameover if too many outbreaks
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
    $game->set_state('actions');

    $player->set_actions_left(4);
    $K->post( main => 'next_player', $player );
    $K->yield( '_next_action' );
};


#
# event: _no_more_cards()
#
# sent when controller cannot deal any more cards, and game is over.
#
event _no_more_cards => sub {
    $K->post( main => 'no_more_cards' );
    $K->yield('_game_over');
};


#
# event: _propagate()
#
# sent to do the regular disease propagation.
#
event _propagate => sub {
    my $game   = Games::Pandemic->instance;
    my $icards = $game->infection;

    # propagate diseases
    do {
        my $card = $icards->next;
        $K->yield( _infect => $card->city, 1 );
        $icards->discard( $card );
    } for 1 .. 2; # FIXME: infection rate

    # update game state
    $game->set_state('end_of_propagation');
    $K->post( 'end_of_propagation' );
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

START

=end Pod::Coverage
