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

sub _cards_needed_builder { 4 }
sub _color_builder        { '#d1d0c2' }
sub _image_builder        { 'scientist.png' }
sub _role_name_builder    { T('Scientist') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__