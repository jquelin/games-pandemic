use 5.010;
use strict;
use warnings;

package Games::Pandemic::Deck;
# ABSTRACT: pandemic card deck

use Moose 0.92;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- builders / finishers

sub DEMOLISH {
    my $self = shift;
    debug( "~deck: $self\n" );
}


# -- accessors

has cards => (
    traits     => ['Array'],
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    required   => 1,
    auto_deref => 1,
    handles => {
        clear_cards => 'clear',
        nbcards     => 'count',
        future      => 'elements',
        next        => 'pop',
        refill      => 'push',
        last        => 'shift',
    },
);

has _pile => (
    traits => ['Array'],
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    default    => sub { [] },
    auto_deref => 1,
    handles => {
        _clear_pile => 'clear',
        nbdiscards  => 'count',
        past        => 'elements',
        discard     => 'push',
    },
);

has previous_nbdiscards => ( is=>'rw', isa=>'Int' );


# -- public methods

=method $deck->clear_pile;

Store the number of cards in the pile in C<previous_nbdiscards> and
clear the pile.

=cut

sub clear_pile {
    my $self = shift;
    $self->set_previous_nbdiscards( $self->nbdiscards );
    $self->_clear_pile;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for Pod::Coverage
    DEMOLISH

=head1 DESCRIPTION

A C<Games::Pandemic::Deck> contains 2 sets of C<Games::Pandemic::Card>:
a drawing deck and a discard pile.

