#!/usr/bin/perl
# ---   *   ---   *   ---
# VEC4
# Group of four numbers xyzw
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package vec4;

  use v5.36.0;
  use strict;
  use warnings;

# ---   *   ---   *   ---
# info

  our $VERSION=v0.1;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# getters

sub x($self) {return $self->{x}};
sub y($self) {return $self->{y}};
sub z($self) {return $self->{z}};
sub w($self) {return $self->{w}};

# ---   *   ---   *   ---
# constructor

sub nit($ref) {

  my ($x,$y,$z,$w)=@{$ref};
  for my $v($x,$y,$z,$w) {$v//=0};

  my $sec=bless {

    x=>$x,
    y=>$y,
    z=>$z,
    w=>$w,

  },'vec4';

};

# ---   *   ---   *   ---
1; # ret
