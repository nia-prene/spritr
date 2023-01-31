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
$sprite->validate_sprite();
if (!$sprite->resolve_tile_layout) {
	die "could not resolve tile, multilayer not yet supported";
}
print "resolved at: \tx: ";
print $sprite->center_x - ($sprite->pixel_width / 2);
print "\ty: ";
print $sprite->center_y - ($sprite->pixel_height / 2);
print "\n";

#$sprite->optimize_tiles;
