package Games::Pandemic::Card::Epidemic;
# ABSTRACT: epidemic card for pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Card';

# -- default builders

sub _build_icon  { '' }
sub _build_label { '' }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements a simple epidemic card, not meant to be
displayed at all.

