#!/usr/bin/perl
#converts 8bit bmp to 2bit nes
use strict;
use warnings;
use diagnostics;
use autodie;
use FindBin;                     # locate this script
use lib "$FindBin::RealBin";  # use the parent directory

use Sprite;
use Colorspace;

my @sprites = ();
# for every file passed
for my $file (@ARGV) {
	
	# get the images dimension
	my $name = (split ('\.', $file))[0];
	my $dimensions = `identify $file | awk '{print \$3}'`;
	my ($width, $height) = split ("x",$dimensions);

	# get all pixels, removing the column header and hex #
	my @colors=`convert +dither $file -remap pal.bmp txt:- | awk '{print \$3}' | sed 1d | sed 's/#//'`;
	# remove whitespace
	chomp @colors;

	my $colorspace = Colorspace->NES;
	my $pixel_lattice = [];
	my $pixel_row = [];

	for my $i (0..$#colors) {
	
		#get the color
		my $color = $colors[$i];
	
		# remap it to the colorspace
		if ($colorspace) {
			push @{$pixel_row}, $colorspace->{hex($color)};
		} else {
			push @{$pixel_row}, $color;
		}
	
		# if the end of a row
		if (!(($i + 1) % $width)) {

			# add it to the pixle lattice
			push @$pixel_lattice, $pixel_row;
			$pixel_row = [];
		}
	}
	# make a new sprite out of pixel lattice
	my $sprite = Sprite->new($name, $pixel_lattice);
	#push @sprites, $sprite;
}
