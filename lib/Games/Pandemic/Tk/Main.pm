package Games::Pandemic::Tk::Main;
# ABSTRACT: main window for Games::Pandemic

use 5.010;
use Moose;
use MooseX::POE;
use Readonly;
use Tk;

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


sub _build_gui {
    my ($self, $session) = @_;
    $self->_build_menu($session);
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

1;
__END__
