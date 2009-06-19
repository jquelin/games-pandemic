package Games::Pandemic::Deck;
# ABSTRACT: pandemic card deck

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;


# -- accessors

has cards => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    required   => 1,
    auto_deref => 1,
    provides   => {
        count => 'nbcards',
        pop   => 'next',
        shift => 'last',
    },
);

has _pile => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        clear    => '_clear_pile',
        count    => 'nbdiscards',
        push     => 'discard',
        elements => 'past',
    },
);


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 DESCRIPTION

A C<Games::Pandemic::Deck> contains 2 sets of C<Games::Pandemic::Card>:
a drawing deck and a discard pile.

