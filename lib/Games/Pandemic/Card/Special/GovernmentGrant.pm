use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Special::GovernmentGrant;
# ABSTRACT: government grant event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18N      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'government-grant-16.png' ) }
sub _build_label { T('Government grant') }
sub _build_description {
    T( 'This event allows to add a research station to any city for free.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements the special event card C<government grant>.
When played, this event allows to add a research station to any
city for free.
