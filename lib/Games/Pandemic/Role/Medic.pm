use 5.010;
use strict;
use warnings;

package Games::Pandemic::Role::Medic;
# ABSTRACT: medic pandemic role

use Moose::Role;
use Games::Pandemic::Utils;


around auto_clean_on_cure => sub { 1 };
around treat_all          => sub { 1 };
sub color { '#e48006'  }
sub role  { T('Medic') }
sub _role { 'medic'    }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

color
role

=end Pod::Coverage
