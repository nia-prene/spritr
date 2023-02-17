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
#!/usr/bin/perl

package Colorspace;
use strict;
use warnings;


sub NES{
	return {
	0x7C7C7C => "00",
	0x0000FC => "01",
	0x0000BC => "02",
	0x4428BC => "03",
	0x940084 => "04",
	0xA80020 => "05",
	0xA81000 => "06",
	0x881400 => "07",
	0x503000 => "08",
	0x007800 => "09",
	0x006800 => "0A",
	0x005800 => "0B",
	0x004058 => "0C",
	0x000000 => "0F",
	0x000000 => "0F",
	0x000000 => "0F",
	0xBCBCBC => "10",
	0x0078F8 => "11",
	0x0058F8 => "12",
	0x6844FC => "13",
	0xD800CC => "14",
	0xE40058 => "15",
	0xF83800 => "16",
	0xE45C10 => "17",
	0xAC7C00 => "18",
	0x00B800 => "19",
	0x00A800 => "1A",
	0x00A844 => "1B",
	0x008888 => "1C",
	0x000000 => "0F",
	0x000000 => "0F",
	0x000000 => "0F",
	0xF8F8F8 => "20",
	0x3CBCFC => "21",
	0x6888FC => "22",
	0x9878F8 => "23",
	0xF878F8 => "24",
	0xF85898 => "25",
	0xF87858 => "26",
	0xFCA044 => "27",
	0xF8B800 => "28",
	0xB8F818 => "29",
	0x58D854 => "2A",
	0x58F898 => "2B",
	0x00E8D8 => "2C",
	0x787878 => "2D",
	0x000000 => "0F",
	0x000000 => "0F",
	0xFCFCFC => "30",
	0xA4E4FC => "31",
	0xB8B8F8 => "32",
	0xD8B8F8 => "33",
	0xF8B8F8 => "34",
	0xF8A4C0 => "35",
	0xF0D0B0 => "36",
	0xFCE0A8 => "37",
	0xF8D878 => "38",
	0xD8F878 => "39",
	0xB8F8B8 => "3A",
	0xB8F8D8 => "3B",
	0x00FCFC => "3C",
	0xF8D8F8 => "3D",
	0x000000 => "0F",
	0x000000 => "0F"
	}
}


1;


