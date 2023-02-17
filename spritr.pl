#!/usr/bin/perl
#converts images to metasprites
use strict;
use warnings;
use diagnostics;
use autodie;
use FindBin;                     # locate this script
use lib "$FindBin::RealBin";  # use the parent directory

use Getopt::Long;
use Sprite;
use Colorspace;


my $join = '';
my $palette = 0;
my $size = '8x8';
my $depth = 2;

GetOptions (
	'size=s' => \$size,
	'join' => \$join,
	'palette=i' => \$palette,
	'depth=i' => \$depth
);

my ($tile_width, $tile_height) = split /[^0-9]+/, $size;

convert_to_nes("#123456");

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
	my $sprite = Sprite->new(
		$name, $pixel_lattice, $tile_width, $tile_height, $depth);
	push @sprites, $sprite;
}


if ($join) {
	my @palettes= ();
	for my $sprite (@sprites) {
		for my $palette (@{$sprite->palettes}) {
			push @palettes, $palette;
		}
	}
	for my $sprite (@sprites) {
		$sprite->palettes(\@palettes);
	}
}


for my $sprite (@sprites) {
	$sprite->write_header;
	$sprite->write_palettes;
}

sub convert_to_nes{
	my $hex = shift;
	
	my $red = hex(substr($hex, 1, 2));
	my $green = hex(substr($hex, 3, 2));
	my $blue = hex(substr($hex, 5, 2));

}
