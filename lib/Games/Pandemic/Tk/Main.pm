package Games::Pandemic::Tk::Main;
# ABSTRACT: main window for Games::Pandemic

use 5.010;
use Encode;
use Image::Size;
use Moose;
use MooseX::FollowPBP;
use MooseX::POE;
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

    my @actions = qw{ move flight charter shuttle build discover cure share };
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
    my $map    = Games::Pandemic->instance->get_map;
    my $bgpath = $map->background_path;
    my ($xmax, $ymax) = imgsize($bgpath);

    # creating the canvas
    my $c  = $mw->Canvas(-width=>$xmax,-height=>$ymax)->pack(@XFILL2);
    my $bg = $c->Photo( -file => $bgpath );
    $c->createImage(0, 0, -anchor=>'nw', -image=>$bg, -tags=>['background']);
    $c->lower('background', 'all');

    # place the cities on the map
    my @smooth = ( -smooth => 1, -splinesteps => 5 );
    foreach my $city ( $map->all_cities ) {
        my $name  = decode( 'utf-8', $city->get_name );
        my $xreal = $city->get_xreal;
        my $yreal = $city->get_yreal;
        my $x = $city->get_x;
        my $y = $city->get_y;
        my ($rreal, $r) = (2, 12);
        my $color = $city->get_disease->color(0);
        $c->createOval(
            $xreal-$rreal, $yreal-$rreal, $xreal+$rreal, $yreal+$rreal,
            -fill => $color,
            -tags => ['city', $name],
        );
        $c->createOval(
            $x-$r, $y-$r, $x+$r, $y+$r,
            -fill => $color,
            -tags => ['city', $name ],
        );
        $c->createLine( $xreal, $yreal, $x, $y,
            -width => 2,
            -fill  => $color,
            -tags  => [ $name ],
            @smooth,
        );
        $c->createText( $x, $y - $r-6, -text=>$name, -fill=>'black', -anchor=>'center', -tag=>['name'] );

        # draw connections between cities
        foreach my $n ( $city->neighbours ) {
            my $xn = $n->get_x;
            my $yn = $n->get_y;
            next if $xn < $x; # line already drawn
            if ( ($xn-$x) > $xmax/2 ) {
                $c->createLine( $x, $y, 0, ($y+$yn)/2, -fill => 'red', -tags=>['line'], @smooth );
                $c->createLine( $xn, $yn, $xmax, ($y+$yn)/2, -fill => 'red', -tags=>['line'], @smooth );
            } else {
                $c->createLine( $x, $y, $xn, $yn, -fill => 'red', -tags=>['line'], @smooth );
            }
        }
    }
    $c->raise('name', 'all');
    $c->raise('city', 'all');

    my $start = $map->get_start_city;
    my $x = $start->get_x;
    my $y = $start->get_y;
    $c->createPolygon(
        $x-6, $y-6,
        $x-6, $y+6,
        $x+6, $y+6,
        $x+6, $y-6,
        -fill => 'white',
        -outline =>'black',
    );
    $c->createLine( $x-2, $y, $x+3, $y, -width=>1, -fill=> '#007c00' );
    $c->createLine( $x, $y-3, $x, $y+3, -width=>1, -fill=> '#007c00' );
}


sub _build_gui {
    my ($self, $session) = @_;
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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
