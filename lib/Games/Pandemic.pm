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
use MooseX::FollowPBP;
use MooseX::POE;

use Games::Pandemic::Config;
use Games::Pandemic::Tk::Main;
use Games::Pandemic::Utils;

has config => (
    is       => 'ro',
    writer   => '_set_config',
    default  => sub { Games::Pandemic::Config->new },
    isa      => 'Games::Pandemic::Config'
);


sub run {
    Games::Pandemic::Tk::Main->new;
    POE::Kernel->run;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__