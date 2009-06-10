package Games::Pandemic::Controller;
# ABSTRACT: controller for a pandemic game

use 5.010;
use MooseX::Singleton;  # should come before any other moose
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;

Readonly my $K  => $poe_kernel;

# -- accessors

# -- initialization

sub START {
    $K->alias_set('controller');
}

# -- public events

event new_game => sub {
    say "new game!";
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
