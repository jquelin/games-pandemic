package Games::Pandemic::Role::Researcher;
# ABSTRACT: researcher pandemic role

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _build_can_share    { 1 }
sub _build_color        { '#aa7826' }
sub _build__image       { 'researcher' }
sub _build_role_name    { T('Researcher') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__