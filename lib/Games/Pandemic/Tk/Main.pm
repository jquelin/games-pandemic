package Games::Pandemic::Tk::Main;
# ABSTRACT: main window for Games::Pandemic

use 5.010;
use File::Spec::Functions qw{ catfile };
use Image::Size;
use Moose;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;
use Tk;
use Tk::Font;
use Tk::JPEG;
use Tk::PNG;

use Games::Pandemic::Config;
use Games::Pandemic::Tk::Constants;
use Games::Pandemic::Utils;

Readonly my $K  => $poe_kernel;
Readonly my $mw => $poe_main_window; # already created by poe

# -- accessors

has _canvas => (
    is       => 'rw',
    isa      => 'Tk::Canvas',
    weak_ref => 1,
);

# it's not usually a good idea to retain a reference on a poe session,
# since poe is already taking care of the references for us. however, we
# need the session to call ->postback() to set the various gui callbacks
# that will be fired upon gui events.
has _session => ( is=>'rw', isa=>'POE::Session', weak_ref=>1 );


# -- initialization

sub START {
    my ($self, $session) = @_[OBJECT, SESSION];
    $K->alias_set('main');
    $self->_set_session($session);
    $self->_build_gui;
}

# -- public events

event new_game => sub {
    my $self = shift;
    my $c = $self->_canvas;
    my $s = $self->_session;


    #
    $self->_build_action_bar;
    $self->_build_status_bar;

    # remove everything on the canvas
    $c->delete('all');

    # the background image
    my $map    = Games::Pandemic->instance->map;
    my $bgpath = $map->background_path;
    my ($xmax, $ymax) = imgsize($bgpath);
    my $bg = $c->Photo( -file => $bgpath );
    $c->createImage(0, 0, -anchor=>'nw', -image=>$bg, -tags=>['background']);
    $c->lower('background', 'all');

    # place the cities on the map
    my @smooth = ( -smooth => 1, -splinesteps => 5 );
    foreach my $city ( $map->all_cities ) {
        $self->_draw_city($city);
        my $x = $city->x;
        my $y = $city->y;

        # draw connections between cities
        foreach my $n ( $city->neighbours ) {
            my $xn = $n->x;
            my $yn = $n->y;
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

    # draw the starting station
    my $start = $map->start_city;
    $self->_draw_station($start);
};


# -- private events

#
# _new()
#
# request a new game to the controller
#
event _new => sub { $K->post('controller' => 'new_game'); };


#
# _quit()
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
    my $s = $self->_session;
    my $f = $mw->Frame->pack(@TOP, -before=>$self->_canvas);

    my @actions = qw{ move flight charter shuttle join build discover cure share pass };
    foreach my $action ( @actions ) {
        my $image = $mw->Photo(-file=> catfile($SHAREDIR, 'actions', "$action.png"));
        $f->Button(
            -image => $image,
        )->pack(@LEFT);
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
    $self->_set_canvas($c);

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
        -image  => $mw->Photo(-file=>catfile($SHAREDIR, "background.png")),
        @tags,
    );
    # ... then some basic actions
    my @buttons = (
        [ T('New game'),    1, '_new'  ],
        [ T('Join a game'), 0, '_join' ],
        [ T('Load a game'), 0, '_load' ],
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

    # prettyfying tk app.
    # see http://www.perltk.org/index.php?option=com_content&task=view&id=43&Itemid=37
    $poe_main_window->optionAdd('*BorderWidth' => 1);

    # set windowtitle
    $mw->title(T('Pandemic'));
    $mw->iconimage( $mw->Photo(-file=>catfile($SHAREDIR, 'icon.png')) );

    $self->_build_menu;
    $self->_build_canvas;
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

    # create the menu for the window
    my $menubar = $mw->Menu;
    $mw->configure(-menu => $menubar );

    # menu game
    my $game = $menubar->cascade(-label => T('~Game'));
    $game->command(
        -label       => T('~Close'),
        -accelerator => 'Ctrl+W',
        -command     => $s->postback('_window_close'),
        -image       => $mw->Photo('fileclose16'),
        -compound    => 'left',
    );
    $mw->bind('<Control-w>', $s->postback('_window_close'));
    $mw->bind('<Control-W>', $s->postback('_window_close'));

    $game->command(
        -label       => T('~Quit'),
        -accelerator => 'Ctrl+Q',
        -command     => $s->postback('_quit'),
        -image       => $mw->Photo('actexit16'),
        -compound    => 'left',
    );
    $mw->bind('<Control-q>', $s->postback('_quit'));
    $mw->bind('<Control-Q>', $s->postback('_quit'));
}


sub _build_status_bar {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $map  = $game->map;

    my $sb = $mw->Frame->pack(@BOTTOM, @FILLX, -before=>$self->_canvas);

    my $fdiseases = $sb->Frame->pack(@LEFT, @PADX10);
    my $fcures    = $sb->Frame->pack(@RIGHT, @PADX10);

    foreach my $disease ( $map->all_diseases ) {
        $fdiseases->Label(
            -image => $mw->Photo( -file => $disease->image('cube') ),
        )->pack(@LEFT);
        $fdiseases->Label(
            -text => $disease->nb . '/' . $disease->nbmax,
        )->pack(@LEFT);
        $fcures->Label(
            -image => $mw->Photo( -file => $disease->image('cure') ),
            @ENOFF,
        )->pack(@LEFT);
   }
}


# -- private subs

#
# $main->_draw_city($city);
#
# draw $city on the canvas.
# note: this does not draw the diseases, players and research stations.
#
sub _draw_city {
    my ($self, $city) = @_;
    my $c = $self->_canvas;

    # fetch city information
    my $name  = $city->name;
    my $color = $city->disease->color(0);
    my $xreal = $city->xreal;
    my $yreal = $city->yreal;
    my $x     = $city->x;
    my $y     = $city->y;

    # join the 2 circles. this is done first in order to be overwritten
    # by other drawings on the canvas, such as the circles themselves.
    $c->createLine( $xreal, $yreal, $x, $y,
        -width       => 2,
        -fill        => $color,
        -tags        => [ $name ],
        -smooth      => 1,
        -splinesteps => 5,
    );

    # draw the small circle with real position on map
    my $rreal = 2; # 4 pixels diameter
    $c->createOval(
        $xreal-$rreal, $yreal-$rreal, $xreal+$rreal, $yreal+$rreal,
        -fill => $color,
        -tags => ['city', $name],
    );

    # draw the big circle that user can click
    my $r = 10;
    $c->createOval(
        $x-$r, $y-$r, $x+$r, $y+$r,
        -fill => $color,
        -tags => ['city', $name],
    );

    # write the city name
    $c->createText(
        $x, $y - $r - 5,
        -text   => $name,
        -fill   => 'black',
        -anchor => 'center',
        -tag    => ['city', $name],
    );
}


#
# $main->_draw_station($city);
#
# draw a research station on the canvas for the given $city.
#
sub _draw_station {
    my ($self, $city) = @_;
    my $c = $self->_canvas;

    my $x = $city->x;
    my $y = $city->y;
    my $name = $city->name;
    my $tags = [ 'station', $name ];
    $c->createPolygon(
        $x-6, $y-6,
        $x-6, $y+6,
        $x+6, $y+6,
        $x+6, $y-6,
        -fill    => 'white',
        -outline => 'black',
        -tags    => $tags,
    );
    $c->createLine( $x-2, $y, $x+3, $y, -width=>1, -fill=> '#007c00', -tags=>$tags );
    $c->createLine( $x, $y-3, $x, $y+3, -width=>1, -fill=> '#007c00', -tags=>$tags );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
