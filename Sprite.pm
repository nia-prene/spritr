#!/usr/bin/perl
package Sprite;
use strict;
use warnings;

use constant TILE_HEIGHT=> 16;
sub new{
	my $class = shift;
	my $pixels = shift;

	my $pixel_width = scalar @{$pixels->[0]};
	my $pixel_height = scalar @{$pixels};
	my $tile_width = $pixel_width / 8;
	my $tile_height = $pixel_height / TILE_HEIGHT;
	my $tile_count = $tile_width * $tile_height;
	my $background_color = $pixels->[0][0];
	my $self = {
		pixels => $pixels,
		pixel_width => $pixel_width,
		pixel_height => $pixel_height,
		tile_width => $tile_width,
		tile_height => $tile_height,
		tile_count => $tile_count,
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
	my $tile_y = (int(($tile) / ($self->pixel_width / 8)))* TILE_HEIGHT;
	#for each pixel row in this tile	
	for (my $row = $tile_y; $row < ($tile_y + TILE_HEIGHT); $row++){
		#for each pixel in that row
		for (my $column = $tile_x; $column < ($tile_x + 8); $column++){
			#get the hex color
			my $color = $self->pixels->[$row][$column];
			#pop the color in the hash
			$palette{$color}=(1);
		}
	}
	return (\%palette);
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


sub measure_valid_tiles{
	my $self = shift;
	my $valid_count = 0;
	for (my $tile = 0; $tile < $self->tile_count; $tile++) {
		if ($self->is_tile_valid($tile)) {
			$valid_count++;
		}
	}
	return $valid_count;
}

sub resolve_tile_layout{
	my $self = shift;
	my $best_x_offset = 0;
	my $best_y_offset = 0;
	my $best_valid_tiles = $self->measure_valid_tiles;
	for my $i (1..8) {
		$self->move_sprite(1,0);
		my $valid_tiles = $self->measure_valid_tiles;
		if ($valid_tiles > $best_valid_tiles) {
			$best_x_offset = $i;
			$best_valid_tiles = $valid_tiles;
		}
	}
	#move to the best x offset
	$self->move_sprite($best_x_offset - 8, 0);
	$best_valid_tiles = $self->measure_valid_tiles;
	for my $i (1..TILE_HEIGHT) {
		$self->move_sprite(0,1);
		my $valid_tiles = $self->measure_valid_tiles;
		if ($valid_tiles > $best_valid_tiles) {
			$best_y_offset = $i;
			$best_valid_tiles = $valid_tiles;
		}
	}
	#move to the best y offset
	$self->move_sprite(0, $best_y_offset - TILE_HEIGHT);
}

sub move_sprite{
	my $self = shift;
	my $x_movements = shift;
	my $y_movements = shift;
	
	$self->move_sprite_horizontally($x_movements);
	$self->move_sprite_vertically($y_movements);
}


sub move_sprite_horizontally{
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
				splice(@{$row},
					$x_movements * -1));
		}
	}
	return;
}


sub move_sprite_vertically{
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
	return;
}
1;
=pod


sub test_sprtdat{
	my ($sprtref, $pxwdth, $pxhght) = @_;
	if ($pxwdth % 8){
		die qq(nonstandard tile width, width must divide by 8);
	}
	if ($pxhght % TLMODE){
		die qq(nonstandard tile height, must divide by 8 for 8x8 mode, 16 for 8x16 mode);
	}
	for my $row (@{$sprtref}){
		if (@{$row} != $pxwdth){
			die qq(fatal error, tile row found of differing pixels);
		}
	}
}

sub test_row{
	my ($sprite, $pxwdth, $pxhght, $tlwdth, $tlhght, $tlcnt) = @_;
	for (my $tile=$row*$tlwdth; $tile<($row*$tlwdth)+$tlwdth; $tile++){
		if (!test_tl($sprt,$pxwdth,$pxhght,$tl,$tlcnt)){
			return;
		}
	}
	return 1;
}


sub resolve_sprt{

	my ($sprt,$pxwdth,$pxhght,$tlwdth,$tlhght,$tlcnt)=@_;
	my @bdclmns=();
	my @bdrws=();
	for (my $tile_row=0;$tile_row<$tlhght;$tile_row++){
	}

	for (my $clmn=0;$clmn<$tlwdth;$clmn++){
		for (my $tl=$clmn;$tl<$tlcnt;$tl+=$tlwdth){
			if (!test_tl($sprt,$pxwdth,$pxhght,$tl,$tlcnt)){
				push @bdclmns, $clmn;
			}
		}
	}
}
sub test_right_edge{
	
}
=cut


