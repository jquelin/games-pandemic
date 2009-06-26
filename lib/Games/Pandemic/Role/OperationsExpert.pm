package Games::Pandemic::Role::OperationsExpert;
# ABSTRACT: operations expert pandemic role

use 5.010;
use strict;
use warnings;

use Moose::Role;
use Games::Pandemic::Utils;


around can_build_anywhere => sub { 1 };
sub color { '#79af00'              }
sub role  { T('Operations Expert') }
sub _role { 'ops-expert'           }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

color
role

=end Pod::Coverage
