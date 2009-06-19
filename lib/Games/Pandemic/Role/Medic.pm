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

sub _auto_clean_on_cure_builder { 1 }
sub _color_builder              { '#e48006' }
sub _cure_all_builder           { 1 }
sub _image_builder              { 'medic.png' }
sub _role_name_builder          { T('Medic') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__