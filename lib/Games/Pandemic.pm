use 5.010;
use strict;
use warnings;

package Games::Pandemic;
# ABSTRACT: cooperative pandemic board game

# although it's not strictly needed to load POE::Kernel manually (since
# MooseX::POE will load it anyway), we're doing it here to make sure poe
# will use tk event loop. this can also be done by loading module tk
# before poe, for example if we load games::pandemic::tk::main before
# moosex::poe... but better be safe than sorry, and doing things
# explicitly is always better.
use POE::Kernel { loop => 'Tk' };

use MooseX::Singleton;  # should come before any other moose
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Config;
use Games::Pandemic::Controller;
use Games::Pandemic::Tk::Main;


# -- accessors

has config => (
    is       => 'ro',
    writer   => '_set_config',
    default  => sub { Games::Pandemic::Config->new },
    isa      => 'Games::Pandemic::Config'
);

has map => (
    is      => 'rw',
    isa     => 'Games::Pandemic::Map',
    clearer => 'clear_map',
);

# player cards deck
has cards => (
    is      => 'rw',
    isa     => 'Games::Pandemic::Deck',
    clearer => 'clear_cards_deck',
);

# infection cards deck
has infection => (
    is      => 'rw',
    isa     => 'Games::Pandemic::Deck',
    clearer => 'clear_infection_deck',
);

# current players
has _players => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Player]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        elements => 'all_players',       # my @p = $game->all_players;
        push     => 'add_player',        # $game->add_player( $player );
        clear    => 'clear_players',
    }
);
# list of players waiting for their turn
has _players_in_turn => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Player]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        push     => 'reinit_players',    # $game->reinit_players( $player );
        shift    => 'next_player',       # my $p = $game->next_player;
        clear    => 'clear_players_in_turn',
    }
);
has curplayer => (
    is       => 'rw',
    isa      => 'Games::Pandemic::Player',
    weak_ref => 1,
    clearer  => 'clear_curplayer',
);

# game state
has state => ( is=>'rw', isa=>'Str' );
has is_in_play => (
    metaclass => 'Bool',
    is        => 'ro',
    isa       => 'Bool',
    default   => 0,
    provides  => {
        set   => 'has_started',
        unset => 'has_ended',
    }
);


# number of research stations remaining to be build
has stations => (
    metaclass => 'Counter',
    is        => 'ro',
    isa       => 'Int',
    provides  => {
        dec => 'dec_stations',
        set => 'set_stations',
    },
);

has nb_outbreaks => (
    metaclass => 'Counter',
    is        => 'ro',
    isa       => 'Int',
    provides  => {
        inc => '_inc_outbreaks',
        set => 'set_outbreaks',
    },
);



=method $game->inc_outbreaks;

Increment number of outbreaks, up to a maximum of 8.

=cut

sub inc_outbreaks {
    my $self = shift;
    return if $self->nb_outbreaks == 8; # FIXME: game dependant?
    $self->_inc_outbreaks;
}


# holds the player having too many cards - if any
has too_many_cards => (
    is       => 'rw',
    isa      => 'Games::Pandemic::Player',
    default  => undef,
    clearer  => 'clear_too_many_cards',
    weak_ref => 1,
);


# whether there will be a propagation in this turn
has propagation => (
    metaclass => 'Bool',
    is        => 'ro',
    isa       => 'Bool',
    default   => 1,
    provides  => {
        set   => 'enable_propagation',
        unset => 'disable_propagation',
    }
);

has nb_epidemics => (
    metaclass => 'Counter',
    is        => 'ro',
    isa       => 'Int',
    provides  => {
        inc => 'inc_epidemics',
        set => 'set_epidemics',
    },
);

=method my $nb = $game->infection_rate;

Return the infection rate, that is, the number of cities infected per
turn. This rate is growing with number of epidemics, according to the
table given by the map's C<infection_rates()> method.

=cut

sub infection_rate {
    my $self = shift;
    my $map  = $self->map;
    my $nbepidemics = $self->nb_epidemics;
    my @rates = $map->infection_rates;
    return $nbepidemics >= scalar(@rates)
        ? $rates[-1] : $rates[$nbepidemics];
}

has next_step => ( is=>'rw', isa=>'Str', clearer=>'clear_next_step' );


# -- public methods

=method Games::Pandemic->run;

Create the various POE sessions, and start the POE kernel.

=cut

sub run {
    my $self = shift;

    # fetch the singleton if called as a class method
    $self = $self->instance unless ref($self);

    # create the poe sessions
    Games::Pandemic::Controller->new;
    Games::Pandemic::Tk::Main->new;

    # and let's start the fun!
    POE::Kernel->run;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

    use Games::Pandemic;
    Games::Pandemic->new;
    Games::Pandemic->run;

=head1 DESCRIPTION

Pandemic is a cooperative game where the players are united to beat the
game. The goal is to find the cures for various diseases striking
cities, before they propagate too much.

This distribution implements a graphical interface for this game. I
definitely recommend you to buy a C<pandemic> board game and play with
friends, you'll have an exciting time - much more than with this poor
electronic copy.



