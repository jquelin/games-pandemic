use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Special;
# ABSTRACT: base class for special pandemic event cards

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Card';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package is the base class for all special event cards in
L<Games::Pandemic>. Nothing really interesting, check the
subclasses instead.
