package Games::Pandemic::Role::Medic;
# ABSTRACT: medic pandemic role

use 5.010;
use strict;
use warnings;

use Moose::Role;
use Games::Pandemic::Utils;


around auto_clean_on_cure => sub { 1 };
around cure_all           => sub { 1 };
sub color              { '#e48006' }
sub _image             { 'medic' }
sub role_name          { T('Medic') }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;
__END__
