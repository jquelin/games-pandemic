use 5.010;
use strict;
use warnings;

package Games::Pandemic::Deck;
# ABSTRACT: pandemic card deck

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- builders / finishers

sub DEMOLISH {
    my $self = shift;
    debug( "~deck: $self\n" );
}


# -- accessors

has cards => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    required   => 1,
    auto_deref => 1,
    provides   => {
        count    => 'nbcards',
        elements => 'future',
        pop      => 'next',
        push     => 'refill',
        shift    => 'last',
    },
);

has _pile => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        clear    => 'clear_pile',
        count    => 'nbdiscards',
        elements => 'past',
        push     => 'discard',
    },
);


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

DEMOLISH

=end Pod::Coverage


=head1 DESCRIPTION

A C<Games::Pandemic::Deck> contains 2 sets of C<Games::Pandemic::Card>:
a drawing deck and a discard pile.

