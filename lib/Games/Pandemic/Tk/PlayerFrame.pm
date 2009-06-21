package Games::Pandemic::Tk::PlayerFrame;
# ABSTRACT: frame to display a player

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Tk::Constants;

# -- attributes

has parent => (
    is => 'ro',
    isa => 'Tk::Widget',
    required => 1,
    weak_ref => 1,
);

has player => (
    is       => 'ro',
    isa      => 'Games::Pandemic::Player',
    required => 1,
    weak_ref => 1,
);

has _frame => (
    is => 'rw',
    isa => 'Tk::Frame',
    weak_ref => 1,
    lazy_build => 1,
    handles => [ qw{ pack } ],
);


# -- initialization

sub _build__frame {
    my $self = shift;
    my $parent = $self->parent;
    my $f = $parent->Frame;

    $f->Label(
        -image => $parent->Photo( -file=>$self->player->role->icon ),
    )->pack(@LEFT);

    return $f;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
