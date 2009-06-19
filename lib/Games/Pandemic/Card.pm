package Games::Pandemic::Card;
# ABSTRACT: base class for pandemic cards

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

# -- accessors

has label => ( is => 'ro', isa => 'Str', lazy_build => 1 );


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
