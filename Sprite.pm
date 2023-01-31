#!/usr/bin/perl
package Sprite;
use strict;
use warnings;

use constant TILE_HEIGHT => 16;
use constant TILE_WIDTH => 8;
# includes background color
use constant TILE_COLORS_MAX => 4;

sub new{
	my $class = shift;
	my $pixels = shift;

	my $pixel_width = scalar @{$pixels->[0]};
	my $pixel_height = scalar @{$pixels};
	my $tile_width = $pixel_width / 8;
	my $tile_height = $pixel_height / TILE_HEIGHT;
	my $tile_count = $tile_width * $tile_height;
	my $center_x = $pixel_width / 2;
	my $center_y = $pixel_height / 2;
	my $background_color = $pixels->[0][0];
	my $self = {
		pixels => $pixels,
		pixel_width => $pixel_width,
		pixel_height => $pixel_height,
		tile_width => $tile_width,
		tile_height => $tile_height,
		tile_count => $tile_count,
		center_x => $center_x,
		center_y => $center_y,
		background_color => $background_color
	};
	bless $self, $class;
	return $self;
};


sub pixels{
	my $self = shift;
	return $self->{pixels};
}


sub pixel_width{
	my $self = shift;
	return $self->{pixel_width};
}


sub pixel_height{
	my $self = shift;
	return $self->{pixel_height};
}

sub center_x{
	my $self = shift;
	if (@_) {
		$self->{center_x} = shift;	
	}
	return $self->{center_x};
}


sub center_y{
	my $self = shift;
	if (@_) {
		$self->{center_y} = shift;
	}
	return $self->{center_y};
}


sub background_color{
	my $self = shift;
	return $self->{background_color};
}


sub tile_width{
	my $self = shift;
	return $self->{tile_width};
}


sub tile_height{
	my $self = shift;
	return $self->{tile_height};
}


sub tile_count{
	my $self = shift;
	return $self->{tile_count};
}


sub tile_palette{
	my $self = shift;
	my $tile = shift;
	my %palette=();

	#get the top left pixel of the pixel data
	my $tile_x = ($tile % ($self->pixel_width / 8)) * 8;
	my $tile_y = (int(($tile) / ($self->pixel_width / 8))) * TILE_HEIGHT;
	#for each pixel row in this tile	
	for my $row ($tile_y..($tile_y + (TILE_HEIGHT - 1))) {
		#for each pixel in that row
		for my $column ($tile_x..($tile_x + 8)-1) {
			#get the hex color
			my $color = $self->pixels->[$row][$column];
			#pop the color in the hash
			$palette{$color}=(1);
		}
	}
	return (\%palette);
}


sub resolve_tile_layout{
	my $self = shift;
	my $best_x_offset = 0;
	my $best_y_offset = 0;
	my $best_valid_tiles = $self->measure_valid_tiles;
	for my $i (1..TILE_WIDTH) {
		#move sprite
		$self->move_sprite(-1,0);
		#count valid tiles
		my $valid_tiles = $self->measure_valid_tiles;
		my $palette_count = $self->measure_palettes;
		#if this configuration gives more valid tiles
		if ($valid_tiles > $best_valid_tiles) {
			$best_x_offset = $i * -1;
			$best_valid_tiles = $valid_tiles;
		}
	}
	#move back to center
	$self->move_sprite(TILE_WIDTH, 0);
	#move sprite to the best offset
	$self->move_sprite($best_x_offset, 0);
	
	for my $i (1..TILE_HEIGHT) {
		$self->move_sprite(0,-1);
		my $valid_tiles = $self->measure_valid_tiles;
		if ($valid_tiles > $best_valid_tiles) {
			$best_y_offset = $i * -1;
			$best_valid_tiles = $valid_tiles;
		}
	}
	#move sprite back to center
	$self->move_sprite(0, TILE_HEIGHT);
	#move to the best y offset
	$self->move_sprite(0, $best_y_offset);

	if ($best_valid_tiles == $self->tile_count) {
		return 1;
	} else {
		return 0;
	}
}


sub optimize_tiles{
	my $self = shift;
	#this is the current best position for this row
	my @best_offsets = ();
	
	for my $tile_row (0..$self->tile_height - 1){
		my $tiles_used = $self->measure_tiles_used;
		my $best_count = $tiles_used;
		my $best_offset = 0;
		for my $i (1..8) {
			$self->move_tile_row_horizontal($tile_row, 1);
			$tiles_used = $self->measure_tiles_used;
			if ($tiles_used < $best_count ) {
				$best_count = $tiles_used;
				$best_offset = $i;
			}
		}
		push(@best_offsets, $best_offset);
	}
}


sub measure_valid_tiles{
	my $self = shift;
	my $valid_count = 0;
	for my $tile (0..$self->tile_count-1) {
		if ($self->is_tile_valid($tile)) {
			$valid_count++;
		}
	}
	return $valid_count;
}


sub measure_palettes{


}


sub is_tile_valid{
	my $self = shift;
	my $tile = shift;
	# get palette
	my $palette = $self->tile_palette($tile);
	# if under 5
	if ((scalar %{$palette}) < 5){
		return 1;
	}
	return 0;
}

sub measure_tiles_used{
	my $self = shift;
	my $used = 0;
	for my $tile (0..$self->tile_count-1) {
		if ($self->is_tile_used($tile)) {
			$used++;
		}
	}
	return $used;
}


sub is_tile_used{
	my $self = shift;
	my $tile = shift;
	# get palette
	my $palette = $self->tile_palette($tile);
	# if only 1 color, and that color is background
	if (scalar (%{$palette}) == 1 && exists $palette->{$self->background_color}){
		return 0;
	}
	return 1;
}

sub move_sprite{
	my $self = shift;
	my $x_movements = shift;
	my $y_movements = shift;
	
	$self->move_sprite_horizontal($x_movements);
	$self->move_sprite_vertical($y_movements);
}


sub move_sprite_horizontal{
	my $self = shift;
	my $x_movements = shift;
	#if moving left
	if ($x_movements < 0) {
		#cut off the front of every row and append it
		for my $row (@{$self->pixels}) {
			push(@{$row},
				splice(@{$row}, 0, $x_movements * -1));
		}
	}
	#if moving right
	if ($x_movements > 0) {
		#cut off the end of every row and prepend it
		for my $row (@{$self->pixels}) {
			unshift(@{$row},
				splice(@{$row}, $x_movements * -1));
		}
	}
	$self->center_x($self->center_x + $x_movements);
}


sub move_sprite_vertical{
	my $self = shift;
	my $y_movements = shift;
	#if moving up
	if ($y_movements < 0) {
		#cut off the top rows and append it
		push(@{$self->pixels},
			splice(@{$self->pixels}, 0, $y_movements * -1));
	}
	#if moving down 
	if ($y_movements > 0) {
		#cut off the bottom rows and prepend them
		unshift(@{$self->pixels},
			splice(@{$self->pixels}, $y_movements * -1));
	}
	$self->center_y($self->center_y + $y_movements);
}


sub move_tile_row_horizontal{
	my $self = shift;
	my $tile_row = shift;
	my $x_movements = shift;
	
	my $pixel_row_start = $tile_row * TILE_HEIGHT;
	my $pixel_row_end = ($tile_row * TILE_HEIGHT) + (TILE_HEIGHT - 1);

	#if moving left
	if ($x_movements < 0) {
		#cut off the front of every row and append it
		for my $i ($pixel_row_start..$pixel_row_end) {
			my $pixel_row = @{$self->pixels}[$i];
			push(@{$pixel_row},
				splice(@{$pixel_row}, 
					0, $x_movements * -1));
		}
	}
	#if moving right
	if ($x_movements > 0) {
		#cut off the end of every row and prepend it
		for my $i ($pixel_row_start..$pixel_row_end) {
			my $pixel_row = @{$self->pixels}[$i];
			unshift(@{$pixel_row}, 
				splice(@{$pixel_row}, $x_movements * -1));
		}
	}
	#$self->center_x($self->center_x + $x_movements);
}
1;




sub validate_sprite{
	my $self = shift;
	if ($self->pixel_width % TILE_WIDTH){
		die qq(nonstandard tile width, width must divide by 8);
	}
	if ($self->pixel_height % TILE_HEIGHT){
		die qq(nonstandard tile height, must divide by 8 for 8x8 mode, 16 for 8x16 mode);
	}
	for my $row (@{$self->pixels}){
		if (scalar(@{$row}) != $self->pixel_width){
			die qq(fatal error, tile row found of differing pixels);
		}
	}
}

