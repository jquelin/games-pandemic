package Games::Pandemic;
# ABSTRACT: cooperative pandemic board game

use 5.010;
use strict;
use warnings;

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
    is  => 'rw',
    isa => 'Games::Pandemic::Map',
);

# player cards deck
has cards => (
    is  => 'rw',
    isa => 'Games::Pandemic::Deck',
);

# infection cards deck
has infection => (
    is  => 'rw',
    isa => 'Games::Pandemic::Deck',
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
    }
);
has curplayer => ( is=>'rw', isa=>'Games::Pandemic::Player', weak_ref=>1 );

# game state
has state => ( is=>'rw', isa=>'Str' );


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

# holds the player having too many cards - if any
has too_many_cards => (
    is       => 'rw',
    isa      => 'Games::Pandemic::Player',
    default  => undef,
    clearer  => 'clear_too_many_cards',
    weak_ref => 1,
);


has next_step => ( is=>'rw', isa=>'Str' );


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



