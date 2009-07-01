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
use Games::Pandemic::Tk::GiveCard;
use Games::Pandemic::Tk::PlayerFrame;
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
        'set' => '_set_w',
        'get' => '_w',
    },
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

=method event: build_station($city)

Received when C<$city> gained a research station.

=cut

event build_station => sub {
    my ($self, $city) = @_[OBJECT, ARG0];
    $self->_draw_station($city);
};


=method event: drop_card($player, $card)

Received when C<$player> drops a C<$card>.

=cut

event drop_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];
    $self->_w("f$player")->rm_card($card);
    $self->_update_status; # deck count
};


=method event: got_card($player, $card)

Received when C<$player> got a new C<$card>.

=cut

event got_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0..$#_];

    $self->_w("f$player")->add_card($card);
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


    #
    $self->_build_action_bar;
    $self->_build_status_bar;
    $self->_build_players_bar;

    # remove everything on the canvas
    $c->delete('all');

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

    # creating the frame holding the player cards
    my $fplayers = $self->_w( 'fplayers' );
    my $f = Games::Pandemic::Tk::PlayerFrame->new(player=>$player, parent=>$fplayers);
    $self->_set_w( "f$player", $f );
    $f->pack(@LEFT);

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
    my $game = Games::Pandemic->instance;
    my $player = $game->curplayer;
    $self->_w('lab_nbactions')->configure(-text=>$player->actions_left);
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
        Games::Pandemic::Tk::GiveCard->new(
            parent  => $mw,
            cards   => \@cards,
            players => \@players,
        );
    }
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
# event: _city_click( undef, [ $canvas ] )
#
# called when used clicked on a city on the canvas.
#
event _city_click => sub {
    my $args = $_[ARG1];
    my ($canvas) = @$args;

    my $game = Games::Pandemic->instance;
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
# event: _new()
#
# request a new game to the controller
#
event _new => sub { $K->post('controller' => 'new_game'); };


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
    my $tb = $self->_w('toolbar');

    # the toolbar widgets
    my @actions = (
        [ 'build',    T('Build a research station')                ],
        [ 'discover', T('Discover a cure')                         ],
        [ 'cure',     T('Treat a disease')                         ],
        [ 'share',    T('Give a card')                             ],
        [ 'pass',     T('Pass your turn')                          ],
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

    # add a separator
    unshift @items, ['separator'];

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
# $main->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;

    # hide window during its creation to avoid flickering
    $mw->withdraw;

    # prettyfying tk app.
    # see http://www.perltk.org/index.php?option=com_content&task=view&id=43&Itemid=37
    $mw->optionAdd('*BorderWidth' => 1);

    # set windowtitle
    $mw->title(T('Pandemic'));
    $mw->iconimage( pandemic_icon() );

    # WARNING: we need to create the toolbar object before anything
    # else. indeed, tk::toolbar loads the embedded icons in classinit,
    # that is when the first object of the class is created - and not
    # during compile time.
    $self->_build_toolbar;
    $self->_build_menu;
    $self->_build_canvas;

    # center & show the window
    # FIXME: restore last position saved?
    $mw->Popup;
}


#
# $main->_build_menu;
#
# create the window's menu.
#
sub _build_menu {
    my $self = shift;
    my $s = $self->_session;

    # no tear-off menus
    $mw->optionAdd('*tearOff', 'false');

    #$h->{w}{mnu_run} = $menubar->entrycget(1, '-menu');

    my $menubar = $mw->Menu;
    $mw->configure(-menu => $menubar );

    # menu game
    my @mnu_game = (
    [ '_new',   'filenew16',   'Ctrl+N', T('~New game')   ],
    [ '_load',  'fileopen16',  'Ctrl+O', T('~Load game')  ],
    [ '_close', 'fileclose16', 'Ctrl+W', T('~Close game') ],
    [ '---'                                               ],
    [ '_quit',  'actexit16',   'Ctrl+Q', T('~Quit')       ],
    );

    my $game = $menubar->cascade(-label => T('~Game'));
    foreach my $item ( @mnu_game ) {
        my ($action, $icon, $accel, $label) = @$item;

        # separators are easier
        if ( $action eq '---' ) {
            $game->separator;
            next;
        }

        # regular buttons
        $game->command(
            -label       => $label,
            -image       => $icon,
            -compound    => 'left',
            -accelerator => $accel,
            -command     => $s->postback($action),
        );

        # create the bindings. note: we also need to bind the lowercase
        # letter too!
        $accel =~ s/Ctrl\+/Control-/;
        $mw->bind("<$accel>", $s->postback($action));
        $accel =~ s/Control-(\w)/"Control-" . lc($1)/e;
        $mw->bind("<$accel>", $s->postback($action));
    }
}


#
# $main->_build_players_bar;
#
# create the players bar, with the various players and their cards.
#
sub _build_players_bar {
    my $self = shift;

    my $fplayers = $mw->Scrolled(
        'Frame',
        -scrollbars => 's',
        -height     => 40,  # 32 pixels + border
    )->pack(@BOTTOM, @FILLX, -before=>$self->_w('canvas'));
    $self->_set_w( fplayers => $fplayers );
}


#
# $main->_build_status_bar;
#
# create the status bar at the bottom of the window.
#
sub _build_status_bar {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;

    # the status bar itself is a frame
    my $sb = $mw->Frame->pack(@BOTTOM, @FILLX, -before=>$self->_w('canvas'));

    # research stations
    my $fstations = $sb->Frame->pack(@LEFT, @PADX10);
    $fstations->Label(
        -image => image( catfile( $SHAREDIR, 'research-station-32.png' ) ),
    )->pack(@LEFT);
    $fstations->Label(
        -text => $game->stations,
    )->pack(@LEFT);

    # diseases information
    my $fdiseases = $sb->Frame->pack(@LEFT, @PADX10);
    my $fcures    = $sb->Frame->pack(@LEFT, @PADX10);
    foreach my $disease ( $map->all_diseases ) {
        $fdiseases->Label(
            -image => image( $disease->image('cube', 32) ),
        )->pack(@LEFT);
        $fdiseases->Label(
            -text => $disease->nbleft,
        )->pack(@LEFT);
        $fcures->Label(
            -image => image( $disease->image('cure', 32) ),
            @ENOFF,
        )->pack(@LEFT);
    }

    # player cards information
    my $cards  = $game->cards;
    my $fcards = $sb->Frame->pack(@LEFT, @PADX10);
    $fcards->Label(
        -image => image( catfile( $SHAREDIR, 'card-player.png' ) ),
    )->pack(@LEFT);
    $fcards->Label(
        -text => $cards->nbcards . '-' . $cards->nbdiscards,
    )->pack(@LEFT);

    # infection information
    my $infection = $game->infection;
    my $finfection = $sb->Frame->pack(@LEFT, @PADX10);
    $finfection->Label(
        -image => image( catfile( $SHAREDIR, 'card-infection.png' ) ),
    )->pack(@LEFT);
    $finfection->Label(
        -text => $infection->nbcards . '-' . $infection->nbdiscards,
    )->pack(@LEFT);

    # player information
    my $fplayer = $sb->Frame->pack(@LEFT, @PADX10);
    my $labcurp = $fplayer->Label->pack(@LEFT); # for current player image
    $fplayer->Label( -text => T('actions left: ') )->pack(@LEFT);
    my $labturn = $fplayer->Label->pack(@LEFT);
    $self->_set_w('lab_curplayer', $labcurp);
    $self->_set_w('lab_nbactions', $labturn);
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
        [ 'Button', 'filenew22',   'tbut_new',   '_new',   T('New game')   ],
        [ 'Button', 'fileopen22',  'tbut_load',  '_load',  T('Load game')  ],
        [ 'Button', 'fileclose22', 'tbut_close', '_close', T('Close game') ],
        [ 'Button', 'actexit22',   'tbut_quit',  '_quit',  T('Quit')       ],
        #[ 'separator'                                                     ],
    );

    # create the widgets
    foreach my $item ( @tb ) {
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

    my @actions = qw{ build discover cure share pass };
    foreach my $action ( @actions ) {
        my $method = "is_${action}_possible";
        $self->_w("but_action_$action")->configure(
            $player->$method ? @ENON : @ENOFF );
    }

}


#
# $main->_update_status;
#
# update the status bar with relevant information.
#
sub _update_status {
    my $self = shift;
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

=item * research station symbol by Klukeart (Miriam Moshinsky)
L<http://www.klukeart.com>, under a free license for non-commercial use
(see L<http://www.veryicon.com/icons/object/medical/symbol-
1.html>)

=item * research station icon by IconsLand L<http://www.icons-
land.com/>, under a free license for non- commercial use (see
L<http://www.iconspedia.com/icon/hospital--632.html>)

=item * share icon by Everaldo Coelho L<http://www.everaldo.com/>, under
a gpl license (see L<http://www.iconfinder.net/icondetails/15612/32>)

=item * pass icon by Zeus Box Studio L<http://www.zeusboxstudio.com/>,
under a cc-by license (see L<http://www.iconfinder.net/icondetails/12788/32>)

=back

