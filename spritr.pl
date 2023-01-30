#!/usr/bin/perl
#converts 8bit bmp to 2bit nes
use strict;
use warnings;
use diagnostics;
use autodie;
use FindBin;                     # locate this script
use lib "$FindBin::RealBin";  # use the parent directory

use Sprite;

sub get_pixels{
	my @pixels = ();
	while (<>){
		push @pixels, [split];
	}
	return (\@pixels);
}

my $sprite = Sprite->new(get_pixels);

$sprite->resolve_tile_layout();

