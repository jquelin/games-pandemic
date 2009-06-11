package Games::Pandemic::Role::Dispatcher;
# ABSTRACT: dispatcher pandemic role

use 5.010;
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_join_others_builder { 1 }
sub _can_move_others_builder { 1 }
sub _color_builder           { '#af4377' }
sub _image_builder           { 'dispatcher.png' }
sub _role_name_builder       { T('Dispatcher') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__