package Games::Pandemic::Utils;

use 5.010;
use Moose;
use Devel::CheckOS        qw{ os_is };
use File::HomeDir         qw{ my_data };
use File::Spec::Functions qw{ catdir rel2abs };
use Readonly;
 
extends 'Exporter';
our @EXPORT = qw{ $CONFIG_DIR };

Readonly our $CONFIG_DIR => rel2abs( catdir(
    my_data(),
    ( os_is('MicrosoftWindows' ) ? 'Perl' : '.perl' ),
    'Games-Pandemic',
) );


1;
