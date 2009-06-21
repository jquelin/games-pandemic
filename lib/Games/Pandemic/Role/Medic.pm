package Games::Pandemic::Role::Medic;
# ABSTRACT: medic pandemic role

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _build_auto_clean_on_cure { 1 }
sub _build_color              { '#e48006' }
sub _build_cure_all           { 1 }
sub _build__image             { 'medic.png' }
sub _build_role_name          { T('Medic') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__