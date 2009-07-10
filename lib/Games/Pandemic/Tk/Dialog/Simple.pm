package Games::Pandemic::Tk::Dialog::Simple;
# ABSTRACT: generic dialog window for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;


# -- accessors

has text   => ( is=>'ro', isa=>'Str', required=>1 );
has icon   => ( is=>'ro', isa=>'Str' );


# -- initialization


# -- private methods

#
# dialog->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;

    # icon + text
    my $f = $top->Frame->pack(@TOP,@XFILL2);
    $f->Label(-image => image($self->icon,$top))->pack(@LEFT, @FILL2, @PAD10)
        if defined $self->icon;
    $f->Label(
        -text       => $self->text,
        -justify    => 'left',
        -wraplength => '6c',
    )->pack(@LEFT, @XFILL2, @PAD10);

    # close button
    $top->Button(
        -text    => T('Close'),
        -command => sub { $self->_close; },
    )->pack(@TOP, @FILLX);
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage
