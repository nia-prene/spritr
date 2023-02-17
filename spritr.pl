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
		convert_to_nes($color);
	
		# remap it to the colorspace
		if ($colorspace) {
			#push @{$pixel_row}, $colorspace->{hex($color)};
			push @{$pixel_row}, convert_to_nes($color);
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
	
	my $red = hex(substr($hex, 0, 2));
	my $green = hex(substr($hex, 2, 2));
	my $blue = hex(substr($hex, 4, 2));
	
	my %palette = (
		"7C7C7C" => "00",
		"0000FC" => "01",
		"0000BC" => "02",
		"4428BC" => "03",
		"940084" => "04",
		"A80020" => "05",
		"A81000" => "06",
		"881400" => "07",
		"503000" => "08",
		"007800" => "09",
		"006800" => "0A",
		"005800" => "0B",
		"004058" => "0C",
		"000000" => "0F",
		"000000" => "0F",
		"000000" => "0F",
		"BCBCBC" => "10",
		"0078F8" => "11",
		"0058F8" => "12",
		"6844FC" => "13",
		"D800CC" => "14",
		"E40058" => "15",
		"F83800" => "16",
		"E45C10" => "17",
		"AC7C00" => "18",
		"00B800" => "19",
		"00A800" => "1A",
		"00A844" => "1B",
		"008888" => "1C",
		"000000" => "0F",
		"000000" => "0F",
		"000000" => "0F",
		"F8F8F8" => "20",
		"3CBCFC" => "21",
		"6888FC" => "22",
		"9878F8" => "23",
		"F878F8" => "24",
		"F85898" => "25",
		"F87858" => "26",
		"FCA044" => "27",
		"F8B800" => "28",
		"B8F818" => "29",
		"58D854" => "2A",
		"58F898" => "2B",
		"00E8D8" => "2C",
		"787878" => "2D",
		"000000" => "0F",
		"000000" => "0F",
		"FCFCFC" => "30",
		"A4E4FC" => "31",
		"B8B8F8" => "32",
		"D8B8F8" => "33",
		"F8B8F8" => "34",
		"F8A4C0" => "35",
		"F0D0B0" => "36",
		"FCE0A8" => "37",
		"F8D878" => "38",
		"D8F878" => "39",
		"B8F8B8" => "3A",
		"B8F8D8" => "3B",
		"00FCFC" => "3C",
		"F8D8F8" => "3D",
		"000000" => "0F",
		"000000" => "0F"
	);
	
	my $closest_color = "";
	my $closest_distance = (2*(255 ** 2))+(3*(255 ** 2))+(2*(255 ** 2));
	for my $reference (keys %palette) {
		my $reference_red = hex(substr($reference, 0, 2));
		my $reference_green = hex(substr($reference, 2, 2));
		my $reference_blue = hex(substr($reference, 4, 2));

		my $red_delta = $red - $reference_red;
		my $green_delta = $green - $reference_green;
		my $blue_delta = $blue - $reference_blue;

		my $distance_red = 2 * ($red_delta ** 2);
		my $distance_green = 3 * ($green_delta ** 2);
		my $distance_blue = 2 * ($blue_delta ** 2);

		my $distance = $distance_red+$distance_green+$distance_blue;
		if ($distance < $closest_distance) {
			$closest_distance = $distance;
			$closest_color = $reference;
		}
	}
	return $palette{$closest_color};
}


