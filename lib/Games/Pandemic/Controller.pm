package Games::Pandemic::Controller;
# ABSTRACT: controller for a pandemic game

use 5.010;
use Moose;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;

# -- accessors

# -- public events


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
