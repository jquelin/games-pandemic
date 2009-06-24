package Games::Pandemic::Role::Dispatcher;
# ABSTRACT: dispatcher pandemic role

use 5.010;
use strict;
use warnings;

use Moose::Role;
use Games::Pandemic::Utils;


around can_join_others => sub { 1 };
around can_move_others => sub { 1 };
sub color { '#af4377' }
sub role  { T('Dispatcher') }
sub _role { 'dispatcher' }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

color
role

=end Pod::Coverage
