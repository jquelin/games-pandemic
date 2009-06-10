package Games::Pandemic::Role::Dispatcher;
# ABSTRACT: dispatcher pandemic role

use 5.010;
use Locale::TextDomain 'Games-Pandemic';
use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_join_others_builder { 1 }
sub _can_move_others_builder { 1 }
sub _color_builder           { '#af4377' }
sub _role_name_builder       { __('Dispatcher') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__