use 5.010;
use strict;
use warnings;

package Games::Pandemic::Role::Scientist;
# ABSTRACT: scientist pandemic role

use Moose::Role;
use Games::Pandemic::Utils;


around cards_needed => sub { 4 };
sub color { '#d1d0c2'      }
sub role  { T('Scientist') }
sub _role { 'scientist'    }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

color
role

=end Pod::Coverage
