package Games::Pandemic::Tk::Main;
# ABSTRACT: main window for Games::Pandemic

use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw{ catfile };
use Image::Size;
use List::Util            qw{ min };
use Moose;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;
use Tk;
use Tk::Font;
use Tk::JPEG;
use Tk::Pane;
use Tk::PNG;
use Tk::ToolBar;

use Games::Pandemic::Config;
use Games::Pandemic::Tk::Action;
use Games::Pandemic::Tk::Dialog::DropCards;
use Games::Pandemic::Tk::Dialog::GiveCard;
use Games::Pandemic::Tk::Dialog::Simple;
use Games::Pandemic::Tk::PlayerCards;
use Games::Pandemic::Tk::Utils;
use Games::Pandemic::Utils;

Readonly my $K  => $poe_kernel;
Readonly my $mw => $poe_main_window; # already created by poe
Readonly my $RADIUS     => 10;
Readonly my $TIME_BLINK => 0.5;
Readonly my $TIME_DECAY => 0.150;


# -- accessors

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

# a hash with all the actions.
has _actions => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => {
        set    => '_set_action',
        get    => '_action',
    },
);

# toplevel with all players and their cards
has _playercards => (
    is      => 'rw',
    isa     => 'Games::Pandemic::Tk::PlayerCards',
    clearer => '_clear_playercards',
);


# currently selected player
has _selplayer => ( is => 'rw', weak_ref => 1, isa => 'Games::Pandemic::Player' );


# it's not usually a good idea to retain a reference on a poe session,
# since poe is already taking care of the references for us. however, we
# need the session to call ->postback() to set the various gui callbacks
# that will be fired upon gui events.
has _session => ( is=>'rw', isa=>'POE::Session', weak_ref=>1 );


# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    my ($self, $session) = @_[OBJECT, SESSION];
    $K->alias_set('main');
    $self->_set_session($session);
    $self->_build_gui;
}


# -- public events

=method event: action_done()

Received when current player has finished an action.

=cut

event action_done => sub {
    my $self = $_[OBJECT];
    $self->_update_status;
};


=method event: build_station($city)

Received when C<$city> gained a research station.

=cut

event build_station => sub {
    my ($self, $city) = @_[OBJECT, ARG0];
    $self->_draw_station($city);
    $self->_update_status;
};


=method event: cure($disease)

Received when a cure has been found for C<$disease>.

=cut

event cure => sub {
    my ($self, $disease) = @_[OBJECT, ARG0];
    $self->_update_status;
};


=method event: drop_card($player, $card)

Received when C<$player> drops a C<$card>.

=cut

event drop_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    $self->_playercards->drop_card($player, $card);
    $self->_update_status; # deck count
};


=method event: end_of_actions()

Received when current player has finished her actions.

=cut

event end_of_actions => sub {
    my $self = $_[OBJECT];
    $self->_update_actions;
};


=method event: end_of_cards()

Received when current player has received her cards for this turn.

=cut

event end_of_cards => sub {
    my $self = $_[OBJECT];
    $self->_update_actions;
};


=method event: end_of_propagation()

Received when propagation is done

=cut

event end_of_propagation => sub {
    my $self = $_[OBJECT];
    $self->_update_actions;
};


=method event: epidemic($city)

Received when a new epidemic strikes C<$city>.

=cut

event epidemic => sub {
    my ($self, $city) = @_[OBJECT, ARG0];

    # warn user
    my $format = T('%s epidemic strikes in %s.');
    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => T('Warning'),
        header => T('New epidemic'),
        icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
        text   => sprintf($format, $city->disease->name, $city->name)
    );
};


=method event: gain_card($player, $card)

Received when C<$player> got a new C<$card>.

=cut

event gain_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    $self->_playercards->gain_card($player, $card);
    $self->_update_status; # deck count
};


=method event: infection($city, $outbreak)

Received when C<$city> gets infected. C<$outbreak> is true if this
infection lead to a disease outbreak.

=cut

event infection => sub {
    my ($self, $city, $outbreak) = @_[OBJECT, ARG0, ARG1];

    # draw city infections
    $self->_draw_infection($city);

    # update status bar
    $self->_update_status;

    # compute decay colors
    my @from = (0, 255, 0);
    my @to   = (0, 0, 0);
    my $steps = 20;
    my @colors;
    foreach my $i ( 0 .. $steps ) {
        my $r = $from[0] + int( ($to[0] - $from[0]) / $steps * $i );
        my $g = $from[1] + int( ($to[1] - $from[1]) / $steps * $i );
        my $b = $from[2] + int( ($to[2] - $from[2]) / $steps * $i );
        push @colors, sprintf( "#%02x%02x%02x", $r, $g, $b );
    }
    $self->yield( _decay => $city, \@colors );
};


=method event: new_game()

Received when the controller started a new game. Display the new map
(incl. cities), action & statusbar.

=cut

event new_game => sub {
    my $self = shift;
    my $c = $self->_w('canvas');
    my $s = $self->_session;

    # add missing gui elements
    $self->_build_action_bar;
    $self->_build_status_bar;
    my $pcards = Games::Pandemic::Tk::PlayerCards->new( parent=>$mw );
    $self->_set_playercards($pcards);

    # remove everything on the canvas
    $c->delete('all');

    # prevent some actions
    $self->_action('new')->disable;
    $self->_action('load')->disable;
    $self->_action('close')->enable;

    # the background image
    my $map    = Games::Pandemic->instance->map;
    my $bgpath = $map->background_path;
    my ($xmax, $ymax) = imgsize($bgpath);
    my $bg = image($bgpath);
    $c->createImage(0, 0, -anchor=>'nw', -image=>$bg, -tags=>['background']);
    $c->lower('background', 'all');

    # place the cities on the map
    my @smooth = ( -smooth => 1, -splinesteps => 5 );
    foreach my $city ( $map->all_cities ) {
        $self->_draw_city($city);
        my $x = $city->coordx;
        my $y = $city->coordy;

        # draw connections between cities
        foreach my $n ( $city->neighbours ) {
            my $xn = $n->coordx;
            my $yn = $n->coordy;
            next if $xn < $x; # line already drawn
            if ( ($xn-$x) > $xmax/2 ) {
                $c->createLine( $x, $y, 0, ($y+$yn)/2, -fill => 'red', -tags=>['line'], @smooth );
                $c->createLine( $xn, $yn, $xmax, ($y+$yn)/2, -fill => 'red', -tags=>['line'], @smooth );
            } else {
                $c->createLine( $x, $y, $xn, $yn, -fill => 'red', -tags=>['line'], @smooth );
            }
        }
    }

    $c->raise('city',    'all');
    $c->raise('station', 'all');
    $c->raise('name',    'all');
    $c->bind( 'spot', '<1>', $s->postback('_city_click') );

    # draw the starting station
    my $start = $map->start_city;
    $self->_draw_station($start);
};


=method event: new_player( $player )

Received when the controller has just created a new player.

=cut

event new_player => sub {
    my ($self, $player) = @_[OBJECT, ARG0];

    # adding the player to player cards window
    $self->_playercards->new_player($player);

    # drawing the pawn on the canvas
    my $c = $self->_w('canvas');
    my @placed = $c->find( withtag => 'player' );
    # each player will be located at a given offset of the city center,
    # in order not to overlap each other.
    my @offsets = ( [-8, -10], [8, -10], [  0, -20], [-15, -20], [ 15, -20] );
    my $offsets = $offsets[ scalar(@placed) ];
    my $city = $player->location;
    my $x = $city->coordx + $offsets->[0];
    my $y = $city->coordy + $offsets->[1];
    $c->createImage(
        $x, $y,
        -image  => image( $player->image('pawn',16) ),
        -anchor => 's',
        -tags   => ['player', $player],
    );
};


=method event: next_action

Received when player needs to do its next action.

=cut

event next_action => sub {
    my $self = $_[OBJECT];
    $self->_update_status;
    $self->_update_actions;
};


=method event: next_player( $player )

Received when C<$player> starts its turn.

=cut

event next_player => sub {
    my ($self, $player) = @_[OBJECT, ARG0];
    my $game = Games::Pandemic->instance;

    # raise back current selected player
    $self->_w('canvas')->raise( $self->_selplayer );
    $self->_set_selplayer( $player );
    $K->delay( _blink_player => $TIME_BLINK, 0 );

    $self->_w('lab_curplayer')->configure(-image=>image($player->image('icon', 32)));
};


=method event: player_move( $player, $from ,$to )

Received when C<$player> has moved between C<$from> and C<$to> cities.

=cut

event player_move => sub {
    my ($self, $player, $from, $to) = @_[OBJECT, ARG0..$#_];

    # canvas uses delta for move()
    my $dx = $to->coordx - $from->coordx;
    my $dy = $to->coordy - $from->coordy;
    $self->_w('canvas')->move( $player, $dx, $dy );
};


=method event: too_many_cards( $player )

Received when C<$player> has too many cards: she must drop some before
the game can continue.

=cut

event too_many_cards => sub {
    my ($self, $player) = @_[OBJECT, ARG0];

    # warn user
    my $format = T('Player %s has too many cards. '.
        'Drop some cards (or use some action cards) before continuing.');
    Games::Pandemic::Tk::Dialog::Simple->new(
        parent => $mw,
        title  => T('Warning'),
        header => T('Too many cards'),
        icon   => catfile($SHAREDIR, 'icons', 'warning-48.png'),
        text   => sprintf($format, $player->role)
    );

    # prevent any action but dropping cards
    $self->_w("but_action_$_")->configure(@ENOFF)
        for qw{ build discover treat share pass };
    $self->_w("but_action_drop")->configure(@ENON);

    # FIXME: provide a way to drop cards
};


=method event: treatment( $city )

Received when C<$city> has been treated.

=cut

event treatment => sub {
    my ($self, $city) = @_[OBJECT, ARG0];
    $self->_draw_infection($city);
    $self->_update_status;
};


# -- private events

#
# event: _blink_player( $bool )
#
# make current selected player blink on the map, depending on previous $bool
# visibility satus.  schedule another _blink_player event.
#
event _blink_player => sub {
    my ($self, $lit) = @_[OBJECT, ARG0];
    my $c    = $self->_w('canvas');
    my $curp = $self->_selplayer;
    my $method = $lit ? 'raise' : 'lower';
    $c->$method( $curp );
    $K->delay( _blink_player => $TIME_BLINK, !$lit );
};


#
# event: _decay( $city, \@colors )
#
# change $city outline color to the first element of @colors, and
# schedule another _decay event with the rest of @colors if it's still
# not empty.
#
event _decay => sub {
    my ($self, $city, $colors) = @_[OBJECT, ARG0, ARG1];
    my $c    = $self->_w('canvas');
    my $name = $city->name;
    my $col  = shift @$colors;
    $c->itemconfigure(
        "$name&&spot",
        -outline => $col,
        -width   => min(5, $#$colors+1),
    );
    $K->delay_add( _decay => $TIME_DECAY, $city, $colors ) if $#$colors;
};


# -- gui events

#
# event: _action_build()
#
# user wishes to build a research station.
#
event _action_build => sub {
    $K->post( controller => 'action', 'build' );
};


#
# event: _action_drop()
#
# user wishes to drop a card, either from current player or if we're in
# a situation of too many cards.
#
event _action_drop => sub {
    my $game = Games::Pandemic->instance;
    my $player = $game->too_many_cards // $game->curplayer; # FIXME://padre
    Games::Pandemic::Tk::Dialog::DropCards->new(
        parent => $mw,
        player => $player,
    );
};


#
# event: _action_discover()
#
# user wishes to discover a cure.
#
event _action_discover => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;

    my $disease = $curp->is_discover_possible;
    my @cards =
        grep { $_->city->disease eq $disease }
        grep { $_->isa('Games::Pandemic::Card::City') }
        $curp->all_cards;

    # FIXME: choose which cards
    splice @cards, $curp->cards_needed;

    $K->post( controller => 'action', 'discover', $disease, @cards );
};


#
# event: _action_pass()
#
# user wishes to pass.
#
event _action_pass => sub {
    $K->post( controller => 'action', 'pass' );
};


#
# event: _action_share()
#
# user wishes to give a card to another player.
#
event _action_share => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $city = $curp->location;

    # get list of players to whom the card can be given
    my @players =
        grep { $_->location eq $city }
        grep { $_ ne $curp }
        $game->all_players;

    # get list of cards to be shared
    my @cards = $curp->can_share_anywhere
        ? $curp->all_cards
        : $curp->owns_city_card($city);

    if ( @players == 1 && @cards == 1 ) {
        $K->post( controller => 'action', 'share', @cards, @players );

    } else {
        Games::Pandemic::Tk::Dialog::GiveCard->new(
            parent  => $mw,
            cards   => \@cards,
            players => \@players,
        );
    }
};


#
# event: _action_treat()
#
# user wishes to treat a disease in her location.
#
event _action_treat => sub {
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $map  = $game->map;
    my $city = $curp->location;

    # find the city infections
    my @diseases;
    foreach my $disease ( $map->all_diseases ) {
        next if $city->get_infection($disease) == 0;
        push @diseases, $disease;
    }

    # check if city is multi-infected
    if ( scalar @diseases == 1 ) {
        $K->post( controller => 'action', 'treat', $diseases[0] );
    } else {
        # FIXME: ask user which disease to treat
    }
};


#
# event: _city_click( undef, [ $canvas ] )
#
# called when used clicked on a city on the canvas.
#
event _city_click => sub {
    my ($self, $args) = @_[OBJECT, ARG1];
    my $game = Games::Pandemic->instance;

    # if we're in a situation of too many cards for a player, user is
    # not allowed to travel
    return $self->yield('too_many_cards', $game->too_many_cards)
        if defined $game->too_many_cards;

    return unless $game->state eq 'actions';

    my ($canvas) = @$args;
    my $map  = $game->map;
    my $player = $game->curplayer; # FIXME: dispatcher

    # find city clicked
    my $item = $canvas->find( withtag => 'current' );
    my ($id) = grep { s/^c-(.*)/$1/ } $canvas->gettags($item);
    my $city = $map->city($id);

    if ( $city eq $player->location ) {
        # FIXME: hilight possible travel destinations
    } else {
        return $K->post( controller => 'action', 'move', $player, $city )
            if $player->can_travel_to($city);
        return $K->post( controller => 'action', 'shuttle', $player, $city )
            if $player->can_shuttle_to($city);
        return $K->post( controller => 'action', 'charter', $player, $city )
            if $player->owns_city_card($player->location);
        return $K->post( controller => 'action', 'fly', $player, $city )
            if $player->owns_city_card($city);
    }
};


#
# event: _close()
#
# request to close current game.
#
event _close => sub {
    my $self = shift;
    my $game = Games::Pandemic->instance;

    # allow some actions
    $self->_action('new')->enable;
    $self->_action('load')->enable;
    $self->_action('close')->disable;

    # remove everything from current game
    my $tb = $self->_del_w('tbactions');
    $tb->{CONTAINER}->packForget; # FIXME: breaking encapsulation
    $tb->destroy;
    $self->_del_w('infobar')->destroy;

    my $c = $self->_w('canvas');
    $c->delete('all');

    # destroy player cards window
    $self->_playercards->destroy;
    $self->_clear_playercards;

    # redraw initial actions
    $self->_draw_init_screen;

    $K->post( controller => 'close' );
};


#
# event: _continue()
#
# request to move game forward.
#
event _continue => sub {
    my $game = Games::Pandemic->instance;
    $K->post( controller => 'continue' );
};


#
# event: _new()
#
# request a new game to the controller
#
event _new => sub {
    my $game = Games::Pandemic->instance;
    return if $game->is_in_play;
    $K->post('controller' => 'new_game');
};


#
# event: _quit()
#
# user requested to quit the application.
#
event _quit => sub {
    exit; # FIXME: do better than that...
};


# -- gui creation

#
# $main->_build_action_bar;
#
# create the action bar at the bottom of the window, with the various
# action buttons that a player can press when it's her turn.
#
sub _build_action_bar {
    my $self = shift;
    my $session = $self->_session;

    # create the toolbar
    my $tbmain = $self->_w('toolbar');
    my $tb = $mw->ToolBar(-movable => 0, -in=>$tbmain );
    $self->_set_w('tbactions', $tb);

    # the toolbar widgets
    my @actions = (
        [ 'build',    T('Build a research station')                ],
        [ 'discover', T('Discover a cure')                         ],
        [ 'treat',    T('Treat a disease')                         ],
        [ 'share',    T('Give a card')                             ],
        [ 'pass',     T('Pass your turn')                          ],
        [ 'drop',     T('Drop some cards')                         ],
    );
    my @items = map {
        my ($action, $tip) = @$_;
        [
            'Button',
            image( catfile($SHAREDIR, 'actions', "$action.png") ),
            "but_action_$action",
            "_action_$action",
            $tip,
        ]
        } @actions;

    # create the widgets
    foreach my $item ( @items ) {
        my ($type, $image, $name, $event, $tip) = @$item;

        # separator is a special case
        $tb->separator( -movable => 0 ), next if $type eq 'separator';

        # regular toolbar widgets
        my $widget = $tb->$type(
            -image       => $image,
            -tip         => $tip,
            #-accelerator => $item->[2],
            -command     => $session->postback($event),
        );
        $self->_set_w( $name, $widget );
    }

    # player information
    $tb->separator( -movable => 0 );
    my $labcurp = $tb->Label; # for current player image
    $tb->Label( -text => T('actions left: ') );
    my $labturn = $tb->Label;
    $self->_set_w('lab_curplayer', $labcurp);
    $self->_set_w('lab_nbactions', $labturn);

    # continue button
    my $but = $tb->Button(
        -text    => T('Continue'),
        -command => $session->postback('_continue'),
        @ENOFF,
    );
    $self->_set_w('but_continue', $but);
}


#
# $main->_build_canvas;
#
# create the canvas, where the map will be drawn and the action
# take place.
#
sub _build_canvas {
    my $self = shift;
    my $s = $self->_session;

    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'canvas_width' );
    my $height = $config->get( 'canvas_height' );

    # creating the canvas
    my $c  = $mw->Canvas(-width=>$width,-height=>$height)->pack(@TOP, @XFILL2);
    $self->_set_w('canvas', $c);

    # removing class bindings
    foreach my $button ( qw{ 4 5 6 7 } ) {
        $mw->bind('Tk::Canvas', "<Button-$button>",       undef);
        $mw->bind('Tk::Canvas', "<Shift-Button-$button>", undef);
    }
    foreach my $key ( qw{ Down End Home Left Next Prior Right Up } ) {
        $mw->bind('Tk::Canvas', "<Key-$key>", undef);
        $mw->bind('Tk::Canvas', "<Control-Key-$key>", undef);
    }

    # initial actions
    $self->_draw_init_screen;
}


#
# $main->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;
    my $s = $self->_session;

    # hide window during its creation to avoid flickering
    $mw->withdraw;

    # prettyfying tk app.
    # see http://www.perltk.org/index.php?option=com_content&task=view&id=43&Itemid=37
    $mw->optionAdd('*BorderWidth' => 1);

    # set windowtitle
    $mw->title(T('Pandemic'));
    $mw->iconimage( pandemic_icon() );

    # make sure window is big enough
    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'win_width' );
    my $height = $config->get( 'win_height' );
    $mw->geometry($width . 'x' . $height);

    # create the actions
    foreach my $what ( qw{ new load close quit show_cards } ) {
        my $action = Games::Pandemic::Tk::Action->new(
            window   => $mw,
            callback => $s->postback("_$what"),
        );
        $self->_set_action($what, $action);
    }
    # allow some actions
    $self->_action('new')->enable;
    $self->_action('load')->enable;
    $self->_action('close')->disable;


    # WARNING: we need to create the toolbar object before anything
    # else. indeed, tk::toolbar loads the embedded icons in classinit,
    # that is when the first object of the class is created - and not
    # during compile time.
    $self->_build_toolbar;
    $self->_build_menubar;
    $self->_build_canvas;

    # center & show the window
    # FIXME: restore last position saved?
    $mw->Popup;
}


#
# $self->_build_menu( $mnuname, $mnulabel, @submenus );
#
# Create the menu $label, with all the @submenus.
# @submenus is a list of [$name, $icon, $accel, $label] items.
# Store the menu items under the name menu_$mnuname_$name.
#
sub _build_menu {
    my ($self, $mnuname, $mnulabel, @submenus) = @_;
    my $menubar = $self->_w('menubar');
    my $s = $self->_session;

    my $menu = $menubar->cascade(-label => $mnulabel);
    foreach my $item ( @submenus ) {
        my ($name, $icon, $accel, $label) = @$item;

        # separators are easier
        if ( $name eq '---' ) {
            $menu->separator;
            next;
        }

        # regular buttons
        my $action = $self->_action($name);
        my $widget = $menu->command(
            -label       => $label,
            -image       => $icon,
            -compound    => 'left',
            -accelerator => $accel,
            -command     => $action->callback,
        );
        $self->_set_w("menu_${mnuname}_${name}", $widget);

        # create the bindings. note: we also need to bind the lowercase
        # letter too!
        $action->add_widget($widget);
        $accel =~ s/Ctrl\+/Control-/;
        $action->add_binding("<$accel>");
        $accel =~ s/Control-(\w)/"Control-" . lc($1)/e;
        $action->add_binding("<$accel>");
    }
}


#
# $main->_build_menubar;
#
# create the window's menu.
#
sub _build_menubar {
    my $self = shift;
    my $s = $self->_session;

    # no tear-off menus
    $mw->optionAdd('*tearOff', 'false');

    #$h->{w}{mnu_run} = $menubar->entrycget(1, '-menu');

    my $menubar = $mw->Menu;
    $mw->configure(-menu => $menubar );
    $self->_set_w('menubar', $menubar);

    # menu game
    my @mnu_game = (
    [ 'new',   'filenew16',   'Ctrl+N', T('~New game')   ],
    [ 'load',  'fileopen16',  'Ctrl+O', T('~Load game')  ],
    [ 'close', 'fileclose16', 'Ctrl+W', T('~Close game') ],
    [ '---'                                              ],
    [ 'quit',  'actexit16',   'Ctrl+Q', T('~Quit')       ],
    );
    $self->_build_menu('game', T('~Game'), @mnu_game);

    # menu view
    my @mnu_view = (
    [ 'show_cards', '', 'F2', T('Player ~cards') ],
    );
    $self->_build_menu('view', T('~View'), @mnu_view);
}


#
# $main->_build_status_bar;
#
# create the status bar at the right of the window.
#
sub _build_status_bar {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;

    # the status bar itself is a frame
    my $sb = $mw->Frame->pack(@RIGHT, @FILLX, -before=>$self->_w('canvas'));
    $self->_set_w( infobar => $sb );

    # research stations
    my $fstations = $sb->Frame->pack(@TOP, @PADX10);
    $fstations->Label(
        -image => image( catfile( $SHAREDIR, 'research-station-32.png' ) ),
    )->pack(@TOP);
    my $lab_nbstations = $fstations->Label->pack(@TOP);
    $self->_set_w('lab_nbstations', $lab_nbstations );

    # diseases information
    my $fdiseases = $sb->Frame->pack(@TOP, @PADX10);
    my $fcures    = $sb->Frame->pack(@TOP, @PADX10);
    foreach my $disease ( $map->all_diseases ) {
        $fdiseases->Label(
            -image => image( $disease->image('cube', 32) ),
        )->pack(@TOP);
        my $lab_disease = $fdiseases->Label->pack(@TOP);
        my $lab_cure = $fcures->Label(
            -image => image( $disease->image('cure', 32) ),
        )->pack(@TOP);
        $self->_set_w("lab_disease_$disease", $lab_disease);
        $self->_set_w("lab_cure_$disease", $lab_cure);
    }

    # player cards information
    my $cards  = $game->cards;
    my $fcards = $sb->Frame->pack(@TOP, @PADX10);
    $fcards->Label(
        -image => image( catfile( $SHAREDIR, 'card-player.png' ) ),
    )->pack(@TOP);
    my $lab_cards = $fcards->Label->pack(@TOP);
    $self->_set_w('lab_cards', $lab_cards);

    # infection information
    my $infection = $game->infection;
    my $finfection = $sb->Frame->pack(@TOP, @PADX10);
    $finfection->Label(
        -image => image( catfile( $SHAREDIR, 'card-infection.png' ) ),
    )->pack(@TOP);
    my $lab_infection = $finfection->Label->pack(@TOP);
    $self->_set_w('lab_infection', $lab_infection);
}


#
# $main->_build_toolbar;
#
# create the window toolbar (the one just below the menu).
#
sub _build_toolbar {
    my $self = shift;
    my $session = $self->_session;

    # create the toolbar
    my $tb = $mw->ToolBar( -movable => 0, @TOP );
    $self->_set_w('toolbar', $tb);

    # the toolbar widgets
    my @tb = (
        [ 'Button', 'filenew22',   'new',   T('New game')   ],
        [ 'Button', 'fileopen22',  'load',  T('Load game')  ],
        [ 'Button', 'fileclose22', 'close', T('Close game') ],
        [ 'Button', 'actexit22',   'quit',  T('Quit')       ],
    );

    # create the widgets
    foreach my $item ( @tb ) {
        my ($type, $image, $name, $tip) = @$item;

        # separator is a special case
        $tb->separator( -movable => 0 ), next if $type eq 'separator';
        my $action = $self->_action($name);

        # regular toolbar widgets
        my $widget = $tb->$type(
            -image       => $image,
            -tip         => $tip,
            #-accelerator => $item->[2],
            -command     => $action->callback,
        );
        $self->_set_w( "tbut_$name", $widget );
        $action->add_widget( $widget );
    }
}


# -- private methods

#
# $main->_draw_city($city);
#
# draw $city on the canvas.
# note: this does not draw the diseases, players and research stations.
#
sub _draw_city {
    my ($self, $city) = @_;
    my $c = $self->_w('canvas');

    # fetch city information
    my $id    = $city->id;
    my $name  = $city->name;
    my $color = $city->disease->color(0);
    my $xreal = $city->xreal;
    my $yreal = $city->yreal;
    my $x     = $city->coordx;
    my $y     = $city->coordy;

    # join the 2 circles. this is done first in order to be overwritten
    # by other drawings on the canvas, such as the circles themselves.
    $c->createLine( $xreal, $yreal, $x, $y,
        -width       => 2,
        -fill        => $color,
        -tags        => [ 'city', 'draw', $name ],
        -smooth      => 1,
        -splinesteps => 5,
    );

    # draw the small circle with real position on map
    my $rreal = 2; # 4 pixels diameter
    $c->createOval(
        $xreal-$rreal, $yreal-$rreal, $xreal+$rreal, $yreal+$rreal,
        -fill => $color,
        -tags => ['city', 'draw', $name],
    );

    # draw the big circle that user can click
    $c->createOval(
        $x-$RADIUS, $y-$RADIUS, $x+$RADIUS, $y+$RADIUS,
        -fill => $color,
        -tags => ['city', 'draw', 'spot', $name, "c-$id"],
    );

    # write the city name
    $c->createText(
        $x, $y - $RADIUS * 1.5,
        -text   => $name,
        -fill   => 'black',
        -anchor => 'center',
        -tag    => ['city', $name],
    );
}


#
# $main->_draw_infection($city);
#
# re-draw the infection squares on the canvas for the given $city.
#
sub _draw_infection {
    my ($self, $city) = @_;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;

    # get number of main infection
    my $maindis = $city->disease;
    my $mainnb  = $city->get_infection( $maindis );
    my $color   = $maindis->color($mainnb);
    my @infections = ( $color ) x $mainnb;

    # update city color
    my $c    = $self->_w('canvas');
    my $name = $city->name;
    $c->itemconfigure( "$name&&draw", -fill => $color );

    # get list of disease items, with their color
    my @diseases =
        sort { $a->id <=> $b->id }
        grep { $_ ne $maindis }
        $map->all_diseases;
    foreach my $disease ( @diseases ) {
        my $nb  = $city->get_infection( $disease );
        my $col = $disease->color($nb);
        push @infections, ( $col ) x $nb;
    }

    # remove all infection items for the city
    $c->delete( "$name&&disease" );

    # draw the infection items
    my $x = $city->coordx;
    my $y = $city->coordy;
    my $tags = [ $name, 'disease' ];

    my $len = 8;
    my $pad = 4;
    foreach my $i ( 0 .. $#infections ) {
        my $xorig = $x + ($#infections/2 -$i) * $len + (($#infections-$i)/2-1) * $pad;
        my $yorig = $y + $RADIUS + $pad;
        $c->createRectangle(
            $xorig, $yorig,
            $xorig+$len, $yorig+$len,
            -fill    => $infections[$i],
            #-outline => undef,
            -tags    => $tags,
        );
    }
}


#
# $main->_draw_init_screen;
#
# draw splash image on canvas + initial actions, to present user with a
# non-empty window by default.
#
sub _draw_init_screen {
    my $self = shift;
    my $c = $self->_w('canvas');
    my $s = $self->_session;

    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'canvas_width' );
    my $height = $config->get( 'canvas_height' );

    # create the initial welcome screen
    my @tags = ( -tags => ['startup'] );
    # first a background image...
    $c->createImage (
        $width/2, $height/2,
        -anchor => 'center',
        -image  => image( catfile($SHAREDIR, "background.png") ),
        @tags,
    );
    # ... then some basic actions
    my @buttons = (
        [ T('New game') ,  1, '_new'  ],
        [ T('Join game') , 0, '_join' ],
        [ T('Load game') , 0, '_load' ],
    );
    my $pad = 25;
    my $font = $mw->Font(-weight=>'bold');
    foreach my $i ( 0 .. $#buttons ) {
        my ($text, $active, $event) = @{ $buttons[$i] };
        # create the 'button' (really a clickable text)
        my $id = $c->createText(
            $width/2, $height/2 - (@buttons)/2*$pad + $i*$pad,
            $active ? @ENON : @ENOFF,
            -text         => $text,
            -fill         => '#dddddd',
            -activefill   => 'white',
            -disabledfill => '#999999',
            -font         => $font,
            @tags,
        );
        # now bind click on this text
        $c->bind( $id, '<1>', $s->postback($event) );
    }
}


#
# $main->_draw_station($city);
#
# draw a research station on the canvas for the given $city.
#
sub _draw_station {
    my ($self, $city) = @_;
    my $c = $self->_w('canvas');

    my $x = $city->coordx;
    my $y = $city->coordy;
    my $name = $city->name;
    my $tags = [ 'station', $name ];
    $c->createImage(
        $x, $y,
        -anchor=>'e',
        -image => image( catfile($SHAREDIR, 'research-station-32.png') ),
        -tags  => $tags,
    );
}

#
# $main->_update_actions;
#
# update action buttons state depending on player.
#
sub _update_actions {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;

    my @actions = qw{ build discover treat share pass drop };
    given ( $game->state ) {
        when ('actions') {
            foreach my $action ( @actions ) {
                my $method = "is_${action}_possible";
                $self->_w("but_action_$action")->configure(
                    $player->$method ? @ENON : @ENOFF );
            }
            $self->_w('but_continue')->configure(@ENOFF);
        }
        when ('end_of_actions' || 'end_of_cards') {
            $self->_w("but_action_$_")->configure(@ENOFF) for @actions;
            $self->_w('but_continue')->configure(@ENON);
        }
    }
}


#
# $main->_update_status;
#
# update the status bar with relevant information.
#
sub _update_status {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $curp = $game->curplayer;
    my $map  = $game->map;

    # research stations
    $self->_w('lab_nbstations')->configure(-text => $game->stations);

    # diseases information
    foreach my $disease ( $map->all_diseases ) {
        $self->_w("lab_disease_$disease")->configure(-text => $disease->nbleft);
        $self->_w("lab_cure_$disease")->configure(
            $disease->is_cured ? (@ENON) : (@ENOFF) );
    }

    # cards information
    my $deck1 = $game->cards;
    my $deck2 = $game->infection;
    my $text1 = $deck1->nbcards . '-' . $deck1->nbdiscards;
    my $text2 = $deck2->nbcards . '-' . $deck2->nbdiscards;
    $self->_w('lab_cards')->configure( -text => $text1 );
    $self->_w('lab_infection')->configure(-text => $text2 );

    # actions left
    $self->_w('lab_nbactions')->configure(-text=>$curp->actions_left);
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

START

=end Pod::Coverage


=head1 ACKNOWLEDGEMENT

Thanks to the various artists that provide their work for free, we need
them just as much we need coders.

I used the following icons:

=over 4

=item * research station symbol by Klukeart (Miriam Moshinsky), under a
free license for non-commercial use

=item * research station icon by IconsLand, under a free license for non-
commercial use

=item * discover icon by Klukeart (Miriam Moshinsky), under a free
license for non commercial use

=item * syringue icon by Everaldo Coelho, under an lgpl license

=item * share icon by Everaldo Coelho , under a gpl license

=item * pass icon by Zeus Box Studio, under a cc-by license

=item * trash icon by Jojo Mendoza, under a cc-nd-nc license

=item * warning icon by Gnome artists, under a gpl license

=back

