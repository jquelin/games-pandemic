package Games::Pandemic::Role::Dispatcher;
# ABSTRACT: dispatcher pandemic role

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _build_can_join_others { 1 }
sub _build_can_move_others { 1 }
sub _build_color           { '#af4377' }
sub _build__image          { 'dispatcher' }
sub _build_role_name       { T('Dispatcher') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__