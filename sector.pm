#!/usr/bin/perl
# ---   *   ---   *   ---
# SECTOR
# A (sub)-rect to draw to
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package sector;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/help/';

  use vec4;
  use cash;
  use lycon;

  binmode(STDOUT, ":utf8");

# ---   *   ---   *   ---
# wchars used for drawing
# adjusted for lycon font

my %CHARS=(

  -WAIT=>["\x{01BD}","\x{01BD}"],

  -BOX=>{

    -MID_H=>"\x{01CA}",
    -MID_V=>"\x{01CF}",

    -COR_UL=>"\x{01CD}",
    -COR_UR=>"\x{01CB}",

    -COR_DL=>"\x{01CE}",
    -COR_DR=>"\x{01CC}",

  },

);

# ---   *   ---   *   ---
# getters

sub co {return (shift)->{-CO};};
sub sz {return (shift)->{-SZ};};
sub color {return (shift)->{-COLOR};};

sub rows {

  my $self=shift;

  return [

    $self->co->y..
    ($self->co->y+$self->sz->y-1)

  ];
};

sub is_text {return defined ((shift)->{-TEXT});};

# ---   *   ---   *   ---

sub top_row {
  my $self=shift;
  return $self->co->y

};

sub bottom_row {
  my $self=shift;
  return $self->co->y+$self->sz->y-1

};

# ---   *   ---   *   ---
# setters

# in: text for printing
# wraps formatted text in a tidy fashion

sub colwrap {

  my $self=shift;
  my $s=shift;

  $s=cash::pelines($s);
  unshift @$s,[cash::pex_col($self->color),''];
  push @$s,[cash::pex_col('__'),''];

  $self->{-DRAW}=$s;

};

# ---   *   ---   *   ---
# constructor

sub nit {

  my $co=shift;
  my $sz=shift;
  my $color=shift;

  if(!defined $color) {
    $color='07';

  };

  my $sec=bless {

    -CO=>$co,
    -SZ=>$sz,

    -COLOR=>$color,
    -DRAW=>[],

    -TEXT=>undef,

  },'sector';

  return $sec;

};

# ---   *   ---   *   ---
# fits a string to the given rect

sub fill {

  my $self=shift;
  my $text=shift;

  my $co=$self->co;
  my $sz=$self->sz;

  my $s='';
  my @lines=();

  my $space=$self->sz->x-$self->co->x;
  my @rows=@{$self->rows()};

# ---   *   ---   *   ---
# fill rect with char

  if((length $text)<=1) {
    for my $y(0..@rows-1) {
      push @lines,($text)x$space;

    };

# ---   *   ---   *   ---
# split text into lines

  } else {

    $self->{-TEXT}=$text;
    my ($rem,$sub)=(1,$text);

    # wrap text at whitespaces
    while($rem) {
      ($rem,$sub)=cash::wrap_word(
        $sub,$space

      );if($rem) {push @lines,$rem;};

    # append left-overs
    };push @lines,$sub;

    # fill with blank lines if need
    while(@lines<@rows) {
      push @lines,'';

    };

  };

# ---   *   ---   *   ---
# build line strings

  for my $y(@rows) {
    $s.=sprintf
      "\e[%u;%uH%-${space}s",
      $y+1,$co->x,(shift @lines);

  };$self->colwrap($s);
  return join ' ',@lines;

};

# ---   *   ---   *   ---

sub inner {

  my $self=shift;
  my $edge=shift;
  my $color=shift;

  if(!defined $edge) {$edge=1;};
  if(!defined $color) {$color=$self->color;};

  my $sz=vec4::nit(
    ($self->sz->x+1)-($edge),
    $self->sz->y-($edge*2)

  );

  my $co=vec4::nit(
    $self->co->x+1+($edge),
    $self->co->y+($edge)

  );

  return nit($co,$sz,$color);

};

# ---   *   ---   *   ---
# wrap sector in box-drawing chars

sub box {

  my $self=shift;
  my $text=shift;

  my $co=$self->co;
  my $sz=$self->sz;

  my $pad=$self->sz->x-2;
  my $s='';

# ---   *   ---   *   ---
# shortening names

  my $mid_h=$CHARS{-BOX}->{-MID_H}x$pad;
  my $mid_v=$CHARS{-BOX}->{-MID_V};

  my $cor_ul=$CHARS{-BOX}->{-COR_UL};
  my $cor_ur=$CHARS{-BOX}->{-COR_UR};

  my $cor_dl=$CHARS{-BOX}->{-COR_DL};
  my $cor_dr=$CHARS{-BOX}->{-COR_DR};

# ---   *   ---   *   ---
# make a line string for each row

  for my $y(@{$self->rows()}) {

    $s.=sprintf "\e[%u;%uH",$y+1,$co->x;

    if($y == $self->top_row) {
      $s.=$cor_ul.$mid_h.$cor_ur;

    } elsif($y == $self->bottom_row) {
      $s.=$cor_dl.$mid_h.$cor_dr;

    } else {
      $s.=$mid_v.(' 'x$pad).$mid_v;

    };

  };$self->colwrap($s);

};

# ---   *   ---   *   ---

sub draw {

  my $self=shift;
  my $s=$self->{-DRAW};

  for my $ref(@$s) {
    printf "$ref->[0]$ref->[1]";

  };

};

# ---   *   ---   *   ---
# ^same, typewritter effect

sub slowdraw {

  my $self=shift;
  my $s=$self->{-DRAW};

  # how long each pause lasts
  my $stops={

    '*'=>0,
    "'"=>0,
    ','=>0,

    '-'=>0,
    ';'=>1,
    ':'=>1,
    '.'=>1,

    '!'=>2,
    '?'=>2,

  };

# ---   *   ---   *   ---
# handle punctuation

  my $proc=[

    sub {;},
    sub {

      my $c=shift;

      STDOUT->flush();
      lycon::tick(!$self->is_text);

      if(exists $stops->{$c}) {
        for my $x(0..$stops->{$c}) {
          lycon::tick(0);

        };
      };

    },

  ];

# ---   *   ---   *   ---
# draw the text

  for my $ref(@$s) {
    printf "$ref->[0]";

    if($ref->[1]=~ m/^\s+$/) {
      printf "$ref->[1]";next;

    };

    my @text=split '',"$ref->[1]";

    for my $c(@text) {

      printf "$c";
      $proc->[$c ne ' ']->($c);

    };
  };

};

# ---   *   ---   *   ---
1; # ret
