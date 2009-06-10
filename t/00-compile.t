#!perl

use 5.010;
use strict;
use warnings;

use File::Find::Rule;
use Test::More;
use Test::Script;

my @files = File::Find::Rule->relative->file->name('*.pm')->in('lib');
plan tests => scalar(@files) + 1;

foreach my $file ( @files ) {
    my $module = $file;
    $module =~ s/[\/\\]/::/g;
    $module =~ s/\.pm$//;
    is( qx{ $^X -M$module -e "print '$module ok'" }, "$module ok", "$module loaded ok" );
}

script_compiles_ok( 'bin/pandemic', 'main script compiles' );
