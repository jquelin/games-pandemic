package Games::Pandemic::Tk::Main;
# ABSTRACT: main window for Games::Pandemic

use 5.010;
use Moose;
use MooseX::POE;
use Readonly;
use Tk;

Readonly my $K => $poe_kernel;

# -- accessors

# -- initialization

sub START {
    my $self = shift;
    $K->alias_set('main');
}

# -- public events


1;
__END__