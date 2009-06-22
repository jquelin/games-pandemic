package Games::Pandemic::Player;
# ABSTRACT: pandemic game player

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use UNIVERSAL::require;


# -- accessors

has role_class => ( is=>'ro', isa=>'Str', required => 1, );
has role       => ( is=>'rw', isa=>'Games::Pandemic::Role', lazy_build=>1 );
has _cards => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        elements => 'all_cards',       # my @c = $player->all_cards;
        push     => 'give_card',       # $player->give_card( $card );
    }
);

has location => ( is=>'rw', isa=>'Games::Pandemic::City', lazy_build => 1 );


# -- default builders

sub _build_location {
    return Games::Pandemic->instance->map->start_city;
}

sub _build_role {
    my $self = shift;

    # load the wanted role module
    my $class = 'Games::Pandemic::Role::' . $self->role_class;
    $class->require;

    # create the new role and return it
    return $class->new;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 DESCRIPTION

This is a class implementing a player. Note that the player role in the
game is described in a C<Games::Pandemic::Role> subclass.

