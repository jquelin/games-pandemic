package Games::Pandemic::Player;
# ABSTRACT: pandemic game player

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;


# -- accessors

# -- default builders



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 DESCRIPTION

This is a class implementing a player. Note that the player role in the
game is described in a C<Games::Pandemic::Role> subclass.

