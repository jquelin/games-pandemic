package Games::Pandemic::Role::OperationsExpert;
# ABSTRACT: operations expert pandemic role

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _build_can_build    { 1 }
sub _build_color        { '#79af00' }
sub _build_image        { 'ops-expert.png' }
sub _build_role_name    { T('Operations Expert') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__