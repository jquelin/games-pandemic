package Games::Pandemic;
# ABSTRACT: cooperative pandemic board game

use 5.010;

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
use Games::Pandemic::Map::Pandemic;
use Games::Pandemic::Tk::Main;
use Games::Pandemic::Utils;

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


# -- public methods

sub run {
    my $self = shift;

    # fetch the singleton if called as a class method
    $self = $self->instance unless ref($self);

    # create the initial map
    # FIXME: does it really belong here?
    my $map = Games::Pandemic::Map::Pandemic->new;
    $self->set_map( $map );

    # build the gui
    Games::Pandemic::Tk::Main->new;

    # and let's start the fun!
    POE::Kernel->run;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__