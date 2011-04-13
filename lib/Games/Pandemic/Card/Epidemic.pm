use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Epidemic;
# ABSTRACT: epidemic card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'epidemic-16.png' ) }
sub _build_label { T('epidemic') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements a simple epidemic card. An epidemic event will:

=over 4

=item * Increase the infection rate

=item * Infect a new city with 3 cubes

=item * Intensify the propagation by shuffling the past infections and
putting them back upon the infection deck

=back

