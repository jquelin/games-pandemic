use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Special::OneQuietNight;
# ABSTRACT: quiet night event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18N      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'one-quiet-night-16.png' ) }
sub _build_label { T('One quiet night') }
sub _build_description {
    T( 'This event prevents the next infection phase to be '
    . 'played: it will be skipped.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements the special event card C<one quiet night>. When
played, this event prevents the next infection phase to be played: it
will be skipped.
