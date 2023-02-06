#!/usr/bin/perl
package Sprite;
use strict;
use warnings;

#sprite tile dimensions
use constant TILE_HEIGHT => 16;
use constant TILE_WIDTH => 8;
use constant BIT_DEPTH => 4;

sub new{
	my $class = shift;
	my $pixels = shift;

	my $pixel_width = scalar @{$pixels->[0]};
	my $pixel_height = scalar @{$pixels};
	my $tile_width = $pixel_width / TILE_WIDTH;
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
	
	# confirm data is valid
	$self->confirm_sprite;

	# shift the sprite around to resolve at bitdepth
	if (!$self->resolve_tile_layout) {
		die "target exceeds bitdepth, no layered sprites yet";
	}
	# write resolve info
	#$self->write_resolved_coordinates;
	
	# find the cheapest version of this and move them there
	$self->optimize_tiles;
	$self->move_tiles_to_optimal_positions;
	
	# establish the cononical palettes
	$self->palettes($self->measure_valid_palettes);

	# write file header to stdout
	$self->write_header;
	
	$self->write_palettes;
	# print tile data to stdout
	$self->write_all_tiles;
	# $self->write_optimization_information;
	# $self->write_pixels;
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


sub best_offsets_column {
	my $self = shift;
	if (@_) {
		$self->{best_offsets_column} = shift;
	}
	return $self->{best_offsets_column};
}


sub best_offsets_row {
	my $self = shift;
	if (@_) {
		$self->{best_offsets_row} = shift;
	}
	return $self->{best_offsets_row};
}


sub lowest_tiles_row {
	my $self = shift;
	if (@_) {
		$self->{lowest_tiles_row} = shift;
	}
	return $self->{lowest_tiles_row};
}


sub lowest_tiles_column {
	my $self = shift;
	if (@_) {
		$self->{lowest_tiles_column} = shift;
	}
	return $self->{lowest_tiles_column};
}


sub palettes{
	my $self = shift;
	if (@_) {
		$self->{palettes} = shift;
	}
	return $self->{palettes};
}


sub tile_palette{
	my $self = shift;
	my $tile = shift;
	my %palette=();

	#get the top left pixel of the pixel data
	my $tile_x = ($tile 
		% ($self->pixel_width / TILE_WIDTH)) 
		* TILE_WIDTH;
	my $tile_y = (int($tile 
		/ ($self->pixel_width / TILE_WIDTH)))
		* TILE_HEIGHT;
	#for each pixel row in this tile	
	for my $row ($tile_y..($tile_y + (TILE_HEIGHT - 1))) {
		#for each pixel in that row
		for my $column ($tile_x..($tile_x + TILE_WIDTH)-1) {
			#get the hex color
			my $color = $self->pixels->[$row][$column];
			
			#pop the color in the hash if not background
			if (hex($color) != hex($self->background_color)) {
				$palette{$color}=(1);
			}
		}
	}
	return (\%palette);
}


sub confirm_sprite{
	my $self = shift;
	if ($self->pixel_width % TILE_WIDTH){
		die qq(nonstandard tile width);
	}
	if ($self->pixel_height % TILE_HEIGHT){
		die qq(nonstandard tile height);
	}
	for my $row (@{$self->pixels}){
		if (scalar(@{$row}) != $self->pixel_width){
			die qq(fatal error, tile row found of differing pixels);
		}
	}
}


sub resolve_tile_layout{
	my $self = shift;
	my $best_x_offset = 0;
	my $best_y_offset = 0;
	my $best_valid_tiles = $self->measure_valid_tiles;
	my $best_valid_palettes = scalar(@{$self->measure_valid_palettes});
	for my $i (1..TILE_WIDTH) {
		#move sprite
		$self->move_sprite(-1,0);
		#count valid tiles
		my $valid_tiles = $self->measure_valid_tiles;
		my $palette_count = scalar(
			@{$self->measure_valid_palettes});
		#if this configuration gives more valid tiles or
		if ($valid_tiles > $best_valid_tiles ||
		($valid_tiles == $best_valid_tiles &&
		$palette_count < $best_valid_palettes)) {
			$best_x_offset = $i * -1;
			$best_valid_tiles = $valid_tiles;
			$best_valid_palettes = $palette_count;
		}
	}
	#move back to center
	$self->move_sprite(TILE_WIDTH, 0);
	#move sprite to the best offset
	$self->move_sprite($best_x_offset, 0);
	
	for my $i (1..TILE_HEIGHT) {
		$self->move_sprite(0,-1);
		my $valid_tiles = $self->measure_valid_tiles;
		my $palette_count = scalar(
			@{$self->measure_valid_palettes});
		if ($valid_tiles > $best_valid_tiles ||
		($valid_tiles == $best_valid_tiles &&
		$palette_count < $best_valid_palettes)) {
			$best_y_offset = $i * -1;
			$best_valid_tiles = $valid_tiles;
			$best_valid_palettes = $palette_count;
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

	# collection of best tile count by row and column
	my @best_offsets_row = ();
	my @best_offsets_column = ();

	# the best for each algorithm
	my $best_count_row;
	my $best_count_column;

	# palette count won't be permitted to grow
	my $best_palettes = scalar(@{$self->measure_valid_palettes});
	
	# brute force the the best row configuration by tile
	for my $tile_row (0..$self->tile_height - 1){
		# get the tile count in original position
		my $tiles_used = $self->measure_tiles_used;

		# by default, this is the best configuration... so far
		my $best_count_row = $tiles_used;
		my $best_offset = 0;
		
		# move the tile row to the right one pixel at a time
		for my $i (1..TILE_WIDTH) {
			$self->move_tile_row_horizontal($tile_row, 1);

			# count the tiles used in new configuration
			$tiles_used = $self->measure_tiles_used;

			# if this uses less tiles
			if (($tiles_used < $best_count_row) 

				# and hasn't broken the bitdepth rule
				&& ($self->is_valid_layout) 

				# and hasn't picked up more palettes
				&& (scalar(@{$self->measure_valid_palettes})
					<= $best_palettes)) {

				# this is the new best config, congrats!
				$best_count_row = $tiles_used;
				$best_offset = $i;
			}
		}
		push(@best_offsets_row, $best_offset);

		#move the the best configuration
		$self->move_tile_row_horizontal($tile_row, 
			-TILE_WIDTH + $best_offset);
	}

	# this is the best this configuration can do
	$self->lowest_tiles_row($self->measure_tiles_used);
	$self->best_offsets_row(\@best_offsets_row);

	#move the rows back to their original configurations
	for my $tile_row (0..$self->tile_height - 1){
		$self->move_tile_row_horizontal($tile_row,
			$best_offsets_row[$tile_row] * -1);
	}

	# brute force the best column configuration
	for my $tile_column (0..$self->tile_width-1) {
		
		# get the baseline measurement
		my $tiles_used = $self->measure_tiles_used;

		# this is by default the best configuration
		my $best_count_column = $tiles_used;
		my $best_offset = 0;

		# move the columns down one pixel at a time
		for my $movement (1..TILE_HEIGHT) {
			$self->move_tile_column_vertical($tile_column, 1);

			# count the tiles used in this configuration
			$tiles_used = $self->measure_tiles_used;

			# if this uses less tiles...
			if (($tiles_used < $best_count_column) 
				
				# and doesn't break the ristrictions
				&& ($self->is_valid_layout) 
				
				# and doesn't use more palettes
				&& (scalar(@{$self->measure_valid_palettes})
					<= $best_palettes)) {

				# this is the new best one! congrats!
				$best_count_column = $tiles_used;
				$best_offset = $movement;
			}
		}
		
		# save this configuration for later
		push(@best_offsets_column, $best_offset);
		
		# move to the optimal position
		$self->move_tile_column_vertical($tile_column, 
			-TILE_HEIGHT + $best_offset);
	}
	
	# this is the best this configuration can do
	$self->lowest_tiles_column($self->measure_tiles_used);
	$self->best_offsets_column(\@best_offsets_column);
	
	
	# move the columns back to their original configurations
	for my $tile_column (0..$self->tile_width - 1){
		$self->move_tile_column_vertical($tile_column,
			$best_offsets_column[$tile_column] * -1);
	}
}


sub move_tiles_to_optimal_positions{
	my $self = shift;

	# row wins in a tie but TODO ad tiebreaker switch
	if ($self->lowest_tiles_row <= $self->lowest_tiles_column) {
		# move each row to its optimal place
		for my $tile_row (0.. $self->tile_height - 1) {
			$self->move_tile_row_horizontal($tile_row,
				$self->best_offsets_row->[$tile_row]);
		}
	}
	if ($self->lowest_tiles_column < $self->lowest_tiles_row) {
		
		# move each column to its optimal place
		for my $tile_column (0..$self->tile_width - 1) {
			$self->move_tile_column_vertical($tile_column, 
				$self->best_offsets_column->[$tile_column]);
		}
	}
}


sub is_valid_layout {
	my $self = shift;
	for my $tile (0..$self->tile_count-1) {
		if (!$self->is_tile_valid($tile)) {
			return 0;
		}
	}
	return 1;
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


sub measure_valid_palettes{
	my $self = shift;
	my @palettes;
	# get all the palettes
	for my $tile (0..$self->tile_count-1) {
		my $palette = $self->tile_palette($tile);
		if(scalar %{$palette} < BIT_DEPTH) {
			push(@palettes, $palette);
		}
	}
	#pull of each palette one by one
	for my $i (0..$#palettes) {
		my $test_palette = shift(@palettes);
		my $duplicate = 0;
		#compare to the rest of the palettes
		for my $palette (@palettes) {
			my @matches = ();
			for my $color (keys %{$test_palette}) {
				if (exists $palette->{$color}) {
				push(@matches, $color);
				}	
			}
			if (scalar %{$test_palette} == scalar @matches) {
				$duplicate = 1;
				last;
			}
		}
		if (!$duplicate) {
			push(@palettes, $test_palette);
		}
	}
	return \@palettes;
}


sub is_tile_valid{
	my $self = shift;
	my $tile = shift;
	# get palette
	my $palette = $self->tile_palette($tile);
	# if within bit depth (not including background)
	if ((scalar %{$palette}) < BIT_DEPTH){
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
	
	# if 1 or more color (excluding background)
	if (scalar %{$palette}) {
		return 1;
	}
	return 0;
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
}


sub move_tile_column_vertical {
	my $self = shift;
	my $tile_column = shift;
	my $y_movements = shift;
	my @replacement_pixel_buffer = ();
	my $pixel_column_start = $tile_column * TILE_WIDTH;
	my $pixel_column_end = $pixel_column_start + (TILE_WIDTH - 1);

	#replace the segment of the row with the one above or below
	for my $pixel_row (0..$#{$self->pixels}) {
		my $next_row = ($pixel_row - $y_movements)
			% (scalar @{$self->pixels});
		my $replacement_row = $self->pixels->[$next_row];
		my @replacement_pixels = @$replacement_row
			[$pixel_column_start..$pixel_column_end];
		push (@replacement_pixel_buffer, \@replacement_pixels);
	}
	for my $pixel_row (0..$#{$self->pixels}) {
		splice(@{$self->pixels->[$pixel_row]}, 
			$pixel_column_start, TILE_WIDTH, 
			@{$replacement_pixel_buffer[$pixel_row]});
	}
}


sub write_header {
	my $self = shift;

	printf "Subsprites\t%2d\n", $self->measure_tiles_used;
	printf "Palettes\t%2d\n", scalar(@{$self->measure_valid_palettes});
	printf "Background\t%02X\n", hex($self->background_color);
}


sub write_palettes {
	my $self = shift;
	
	for my $i (0..$#{$self->palettes}) {
		printf "Palette%02X:\t", $i;
		for my $color (sort keys %{$self->palettes->[$i]}) {
			printf "%02X ", hex($color);
		}
		print "\n";
	}
}

sub write_all_tiles {
	my $self = shift;
	my $tiles_written = 0;

	for my $tile (0..$self->tile_count-1) {
		if ($self->is_tile_used($tile)) {
			
			# print the number and coordinate
			printf "Sprite%02X\t", $tiles_written;
			$self->write_tile_coordinates($tile, 
				$tiles_written++);
			# print the binary tile
			$self->write_tile_pixels($tile);
		}
	}
}


sub write_tile_pixels {
	my $self = shift;
	my $tile = shift;
	my $tile_palette = $self->tile_palette($tile);
	my @final_palette;
	my $palette_number;
	
	my $matches = 1;
	for my $i (0..$#{$self->palettes}) {
		for my $color (keys %{$tile_palette}) {
			if (exists $self->palettes->[$i]->{$color}) {
				$matches = 1;
			} else {
				$matches = 0;
				last;
			}
		}
		if ($matches) { 
			@final_palette = sort keys %{$self->palettes->[$i]};
			unshift (@final_palette, $self->background_color);
			$palette_number = $i;
		}
	}

	print "Palette\t\t", $palette_number, "\n";
	#get the top left pixel of the pixel data
	my $tile_x = ($tile % $self->tile_width) * TILE_WIDTH;
	my $tile_y = int($tile / $self->tile_width) * TILE_HEIGHT;
	my $line = 0;
	#for each pixel row in this tile	
	for my $row ($tile_y..($tile_y + (TILE_HEIGHT - 1))) {
		printf ".\t\t";
		#for each pixel in that row
		for my $column ($tile_x..($tile_x + TILE_WIDTH)-1) {
			for my $i (0..$#final_palette){
				if (hex($self->pixels->[$row][$column]) 
					== hex($final_palette[$i])) {
					print $i & 0b1;
				}
			}
		}
		print "\t";
		for my $column ($tile_x..($tile_x + TILE_WIDTH)-1) {
			for my $i (0..$#final_palette){
				if (hex($self->pixels->[$row][$column]) 
					== hex($final_palette[$i])) {
					print (($i & 0b10)>>1);
				}
			}
		}
		print "\n";
	}
}


sub write_tile_coordinates {
	my $self = shift;
	my $tile = shift;
	my $optimizations;
	my $optimization_offset;


	# get the base coordinates, the top left
	my $tile_x = ($tile % ($self->pixel_width / TILE_WIDTH)) 
		* TILE_WIDTH;
	my $tile_y = (int($tile / ($self->pixel_width / TILE_WIDTH)))
		* TILE_HEIGHT;
	
	# adjust the coordinates based on the actual center of the sprite
	$tile_x = $tile_x - $self->center_x;
	$tile_y = $tile_y - $self->center_y;
	
	# if it was compressed by column, 
	if ($self->lowest_tiles_row <= $self->lowest_tiles_column) {
		
		# find the optimization for this tile
		$optimization_offset = int(
			$tile / $self->tile_width);
		$optimizations = $self->best_offsets_row;

		# account for the optimization
		$tile_x = $tile_x - $optimizations->[$optimization_offset];
	}
	# if it was compressed by row
	if ($self->lowest_tiles_column < $self->lowest_tiles_row) {
		
		# find the optimization for this tile
		$optimization_offset = $tile % $self->tile_width;
		$optimizations = $self->best_offsets_column;

		# account for the optimization
		$tile_y = $tile_y - $optimizations->[$optimization_offset];
	}
	
	# write the coordinates
	printf "%4d,%4d\n", $tile_x,$tile_y;
}


sub write_pixels {
	my $self = shift;

	for my $pixel_row (@{$self->pixels}) {
		print @{$pixel_row};
		print "\n";
	}
}


sub write_optimization_information {
	my $self = shift;

	if ($self->lowest_tiles_row <= $self->lowest_tiles_row) {
		printf "row won with\t%2d\n", $self->lowest_tiles_row;
		printf "columns had\t%2d\n", $self->lowest_tiles_column;
		print @{$self->best_offsets_row},"\n";
	}
	if ($self->lowest_tiles_column < $self->lowest_tiles_column) {
		printf "column won with\t%2d\n", $self->lowest_tiles_column;
		printf "rows had\t%2d\n", $self->lowest_tiles_row;
		print @{$self->best_offsets_column},"\n";
	}
}


sub write_resolved_coordinates {
	my $self = shift;

	# goot test data
	print "resolved at: \tx: ";
	print $self->center_x - ($self->pixel_width / 2);
	print "\ty: ";
	print $self->center_y - ($self->pixel_height / 2);
	print "\n";
}



1;
