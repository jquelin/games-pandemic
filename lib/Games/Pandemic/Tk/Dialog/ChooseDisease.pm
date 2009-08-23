use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog::ChooseDisease;
# ABSTRACT: pandemic dialog to select which disease to treat

use Moose;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;

Readonly my $K => $poe_kernel;

# -- accessors

has diseases => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has _disease => ( is=>'rw', isa=>'Games::Pandemic::Disease' );

# -- initialization

sub _build_title   { T('Treatment') }
sub _build_header  { T('Treat a disease') }
sub _build__ok     { T('Treat') }
sub _build__cancel { T('Cancel') }


# -- gui methods

#
# $dialog->_valid;
#
# request to treat a disease & destroy the dialog.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'action', 'treat', $self->_disease );
    $self->_close;
}


# -- private methods

#
# $main->_valid;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;

    my $f = $top->Frame->pack(@TOP, @XFILL2, @PAD10);
    my @diseases = $self->diseases;
    $self->_set_disease( $diseases[0] );
    # enclosed cards in their own frame
    #my $f = $fcenter->Frame->pack(@LEFT, @FILLX, @PAD10, -anchor=>'nw');
    $f->Label(
        -text   => T('Select which disease to treat:'),
        -anchor => 'w',
    )->pack(@TOP, @FILLX);

    # display cards
    my $seldisease = $self->_disease->name;
    foreach my $disease ( @diseases ) {
        # to display a radiobutton with image + text, we need to
        # create a radiobutton with a label just next to it.
        my $fdisease = $f->Frame->pack(@TOP, @FILLX);
        my $rb = $fdisease->Radiobutton(
            -image    => image($disease->image('cube', 16), $top),
            -variable => \$seldisease,
            -value    => $disease->name,
            -command  => sub { $self->_set_disease($disease); },
        )->pack(@LEFT);
        my $lab = $fdisease->Label(
            -text   => $disease->name,
            -anchor => 'w',
        )->pack(@LEFT, @FILLX);
        $lab->bind( '<1>', sub { $rb->invoke; } );
    }
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage


=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::ChooseDisease->new(
        parent   => $mw,
        diseases => \@diseases,
    );

=head1 DESCRIPTION

When cleaning a city multi-infected, the player must choose which
disease to treat.

This dialog will show the C<@diseases> of current city. When clicking
ok, the selected disease will be treated. This takes one action, and is
handled by L<Games::Pandemic::Controller>.
