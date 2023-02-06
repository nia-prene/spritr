#!/usr/bin/perl
#converts 8bit bmp to 2bit nes
use strict;
use warnings;
use diagnostics;
use autodie;
use FindBin;                     # locate this script
use lib "$FindBin::RealBin";  # use the parent directory

use Sprite;

#capture stdin text sprite
sub get_pixels{
	my @pixels = ();
	while (<>){
		push @pixels, [split];
	}
	return (\@pixels);
}


#make a new sprite out of stdin
my $sprite = Sprite->new(get_pixels);

