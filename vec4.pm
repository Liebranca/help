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
  use strict;
  use warnings;

# ---   *   ---   *   ---
# getters

sub x {return (shift)->{-X};};
sub y {return (shift)->{-Y};};
sub z {return (shift)->{-Z};};
sub w {return (shift)->{-W};};

# ---   *   ---   *   ---
# constructor

sub nit {

  my ($x,$y,$z,$w)=@_;

  for my $v($x,$y,$z,$w) {
    if(!defined $v) {
      $v=0;

    };
  };

  my $sec=bless {

    -X=>$x,
    -Y=>$y,
    -Z=>$z,
    -W=>$w,

  },'vec4';

};

# ---   *   ---   *   ---
1; # ret
