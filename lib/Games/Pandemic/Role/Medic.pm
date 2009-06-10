package Games::Pandemic::Role::Medic;
# ABSTRACT: medic pandemic role

use 5.010;
use Locale::TextDomain 'Games-Pandemic';
use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Role';


# -- default builders

sub _auto_clean_on_cure_builder { 1 }
sub _color_builder              { '#79af00' }
sub _cure_all_builder           { 1 }
sub _role_name_builder          { __('Medic') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__