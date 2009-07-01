package Games::Pandemic::Role::Researcher;
# ABSTRACT: researcher pandemic role

use 5.010;
use strict;
use warnings;

use Moose::Role;
use Games::Pandemic::Utils;


around can_share_anywhere => sub { 1 };
sub color { '#aa7826'       }
sub role  { T('Researcher') }
sub _role { 'researcher'    }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

color
role

=end Pod::Coverage
