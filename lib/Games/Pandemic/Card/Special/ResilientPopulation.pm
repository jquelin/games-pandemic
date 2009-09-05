use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Special::ResilientPopulation;
# ABSTRACT: "resilient population" event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'resilient-population-16.png' ) }
sub _build_label { T('Resilient population') }
sub _build_description {
    T( 'This event allows to pick a city from past infections '
     . 'and remove it from the game.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements the special event card C<resilient population>.
When played, this event allows to pick a city from past infections and
remove it from the game.
