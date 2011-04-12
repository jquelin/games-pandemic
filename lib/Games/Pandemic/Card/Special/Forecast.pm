use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card::Special::Forecast;
# ABSTRACT: "forecast" event card for pandemic

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18N      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Card::Special';

# -- default builders

sub _build_icon  { catfile($SHAREDIR, 'cards', 'forecast-16.png' ) }
sub _build_label { T('Forecast') }
sub _build_description {
    T( 'This event allows to examine the top 6 infections to come and '
     . 'rearrange them in the order of your choice.' );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

This package implements the special event card C<forecast>. When played,
this event allows to examine the top 6 infections to come and rearrange
them in the order of your choice.
