package Games::Pandemic::Card::City;
# ABSTRACT: pandemic city card

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Card';

# -- accessors

has city => (
    is => 'ro',
    isa => 'Games::Pandemic::City',
    weak_ref => 1,
);


# -- default builders

sub _build_icon {
    my $self = shift;
    return $self->city->disease->image('cube',16);
}

sub _build_label {
    my $self = shift;
    return $self->city->name;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
