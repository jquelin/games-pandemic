use 5.010;
use strict;
use warnings;

package Games::Pandemic::Card;
# ABSTRACT: base class for pandemic cards

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- builders / finishers

sub DEMOLISH {
    my $self = shift;
    #debug( "~card: " . $self->label . "\n" );
}


# -- accessors

has label => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has icon  => ( is => 'ro', isa => 'Str', lazy_build => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

DEMOLISH

=end Pod::Coverage

