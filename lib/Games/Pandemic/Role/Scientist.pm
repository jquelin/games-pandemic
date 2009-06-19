package Games::Pandemic::Role::Scientist;
# ABSTRACT: scientist pandemic role

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _build_cards_needed { 4 }
sub _build_color        { '#d1d0c2' }
sub _build_image        { 'scientist.png' }
sub _build_role_name    { T('Scientist') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__