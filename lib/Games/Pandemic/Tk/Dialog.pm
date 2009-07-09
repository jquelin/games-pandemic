package Games::Pandemic::Tk::Dialog;
# ABSTRACT: generic dialog window for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;


# -- accessors

has parent => ( is=>'ro', required=>1, weak_ref=>1, isa=>'Tk::Widget' );
has header => ( is=>'ro', isa=>'Str', required=>1 );
has text   => ( is=>'ro', isa=>'Str', required=>1 );
has title  => ( is=>'ro', isa=>'Str', required=>1 );
has icon   => ( is=>'ro', isa=>'Str' );
has _toplevel => ( is=>'rw', isa=>'Tk::Toplevel' );


# -- initialization

#
# BUILD()
#
# called as constructor initialization
#
sub BUILD {
    my $self = shift;
    $self->_build_gui;
}


# -- gui methods

#
# $dialog->_close;
#
# request to destroy the dialog.
#
sub _close {
    my $self = shift;
    $self->_toplevel->destroy;
}


# -- private methods

#
# dialog->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;
    my $parent = $self->parent;

    my $top = $parent->Toplevel;
    $self->_set_toplevel($top);
    $top->withdraw;

    # window title
    $top->title( $self->title );
    $top->iconimage( pandemic_icon($top) );

    # dialog name
    my $font = $top->Font(-size=>16);
    $top->Label(
        -text => $self->header,
        -bg   => 'black',
        -fg   => 'white',
        -font => $font,
    )->pack(@TOP, @PAD10, @FILL2);

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
    
    # center window & make it appear
    $top->Popup( -popover => $parent );
    $top->resizable(0,0);
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD

=end Pod::Coverage
