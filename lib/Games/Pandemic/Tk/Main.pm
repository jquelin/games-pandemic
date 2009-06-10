package Games::Pandemic::Tk::Main;
# ABSTRACT: main window for Games::Pandemic

use 5.010;
use Encode;
use Image::Size;
use Locale::TextDomain 'Games-Pandemic';
use Moose;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;
use Tk;
use Tk::JPEG;
use Tk::PNG;

use Games::Pandemic;
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


# -- initialization

sub START {
    my ($self, $session) = @_[OBJECT, SESSION];
    $K->alias_set('main');
    $self->_build_gui($session);
}

# -- public events

# -- private events

#
# _quit()
#
# user requested to quit the application.
#
event _quit => sub {
    exit; # FIXME: do better than that...
};


# -- gui creation

sub _build_action_bar {
    my ($self, $session) = @_;
    my $f = $mw->Frame->pack(@BOTTOM, @FILLX);

    my @actions = qw{ move flight charter shuttle join build discover cure share };
    foreach my $action ( @actions ) {
        my $image = $mw->Photo(-file=> "$SHAREDIR/actions/$action.png");
        $f->Button(
            -image => $image,
        )->pack(@LEFT);
    }
}

sub _build_canvas {
    my ($self, $session) = @_;

    # the background image
    my $map    = Games::Pandemic->instance->map;
    my $bgpath = $map->background_path;
    my ($xmax, $ymax) = imgsize($bgpath);

    # creating the canvas
    my $c  = $mw->Canvas(-width=>$xmax,-height=>$ymax)->pack(@XFILL2);
    $self->_set_canvas($c);

    my $bg = $c->Photo( -file => $bgpath );
    $c->createImage(0, 0, -anchor=>'nw', -image=>$bg, -tags=>['background']);
    $c->lower('background', 'all');

    # removing class bindings
    foreach my $button ( qw{ 4 5 6 7 } ) {
        $mw->bind('Tk::Canvas', "<Button-$button>",       undef);
        $mw->bind('Tk::Canvas', "<Shift-Button-$button>", undef);
    }
    foreach my $key ( qw{ Down End Home Left Next Prior Right Up } ) {
        $mw->bind('Tk::Canvas', "<Key-$key>", undef);
        $mw->bind('Tk::Canvas', "<Control-Key-$key>", undef);
    }

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
}


sub _build_gui {
    my ($self, $session) = @_;

    # set windowtitle
    $mw->title(decode('utf8', __('Pandemic') ));

    $self->_build_menu($session);
    $self->_build_action_bar($session);
    $self->_build_canvas($session);
}

sub _build_menu {
    my ($self, $s) = @_;

    # no tear-off menus
    $mw->optionAdd('*tearOff', 'false');

    # create the menu for the window
    my $menubar = $mw->Menu;
    $mw->configure(-menu => $menubar );

    # menu game
    my $game = $menubar->cascade(-label => '~Game');
    $game->command(
        -label       => '~Close',
        -accelerator => 'Ctrl+W',
        -command     => $s->postback('_window_close'),
        -image       => $mw->Photo('fileclose16'),
        -compound    => 'left',
    );
    $mw->bind('<Control-w>', $s->postback('_window_close'));
    $mw->bind('<Control-W>', $s->postback('_window_close'));

    $game->command(
        -label       => '~Quit',
        -accelerator => 'Ctrl+Q',
        -command     => $s->postback('_quit'),
        -image       => $mw->Photo('actexit16'),
        -compound    => 'left',
    );
    $mw->bind('<Control-q>', $s->postback('_quit'));
    $mw->bind('<Control-Q>', $s->postback('_quit'));
}

# -- private subs

sub _draw_city {
    my ($self, $city) = @_;
    my $c = $self->_canvas;

    # fetch city information
    my $name  = decode( 'utf-8', $city->name );
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
