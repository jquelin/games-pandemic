package Games::Pandemic::Role::Researcher;
# ABSTRACT: researcher pandemic role

use 5.010;
use strict;
use warnings;

use Moose::Role;
use Games::Pandemic::Utils;


around can_share => sub { 1 };
sub color     { '#aa7826' }
sub _image    { 'researcher' }
sub role_name { T('Researcher') }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

color
role_name

=end Pod::Coverage
