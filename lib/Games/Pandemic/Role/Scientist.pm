package Games::Pandemic::Role::Scientist;
# ABSTRACT: scientist pandemic role

use 5.010;
use strict;
use warnings;

use Moose::Role;
use Games::Pandemic::Utils;


around cards_needed => sub { 4 };
sub color     { '#d1d0c2' }
sub _image    { 'scientist' }
sub role_name { T('Scientist') }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__
