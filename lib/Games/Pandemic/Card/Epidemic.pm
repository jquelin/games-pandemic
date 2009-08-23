use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Epidemic;
# ABSTRACT: epidemic card for pandemic

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card';

# -- default builders

sub _build_icon  { '' }
sub _build_label { T('epidemic') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements a simple epidemic card, not meant to be
displayed at all. It is here only to mark an epidemic event, drawn among
other cards.

