#!/usr/bin/perl
# ---   *   ---   *   ---
# CASH
# rich string utilities
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package cash;

  use strict;
  use warnings;
  use Time::Piece;

  use lib $ENV{'ARPATH'}.'/lib/';
  use lycon;

# ---   *   ---   *   ---
# program info

  use constant {

    VERSION=>'1.0',
    AUTHOR=>'IBN-3DILA',

  };

# ---   *   ---   *   ---
# settings

  use constant {
    PAD    =>  2,
    DEBUG  =>  0,

  };

# ---   *   ---   *   ---
# dirty stuff, don't touch

  use constant {

    # escape delimiters
    PE_BEG   =>  '#:'         ,
    PE_END   =>  ';>'         ,
    PE_NIHIL =>  "#:NIHIL;>\n",

  };

# ---   *   ---   *   ---
# standard and user defined color schemes

# default palette for $:col;>
  my @DEFPAL=(
    0x000020,   # black
    0x7F0000,   # red
    0x208020,   # green
    0xD09820,   # yellow

    0x0060B0,   # blue
    0x400040,   # magenta
    0x008080,   # cyan
    0x8080C0,   # white

    0x000080,   # black
    0xA01020,   # red
    0x40AE40,   # green
    0xB0B000,   # yellow

    0x0040B0,   # blue
    0x8000A0,   # magenta
    0x00A0A0,   # cyan
    0xB0A060,   # white

  );

# hash for the standard and user-defined palettes
  my %PALETTES=(
    "def" => \@DEFPAL,
    "emp" => []      ,

  );

# ---   *   ---   *   ---
# internal global storage

  my %CACHE = (
    -FILE     => ""         ,
    -LINE     => ""         ,

    -SC_SZX   =>          68,
    -SC_SZY   =>          30,

    -SPACE    =>          68,

    -PE_PALID => "def"      ,

    -CALLTAB  => undef      ,

  );

# ---   *   ---   *   ---
# peso function table

my %PESO=(

  # on/off
  "peso_beg"  ,      \&pe_beg         ,
  "peso_end"  ,      \&pe_end         ,

  # formatting
  "pad"       ,      \&pex_pad        ,
  "nl"        ,      \&pex_newline    ,
  "center_beg",      \&pex_center_beg ,
  "center_end",      \&pex_center_end ,

  # coloring
  "col"       ,      \&pex_col        ,
  "pal"       ,      \&pex_pal        ,
  "pal_beg"   ,      \&pex_pal_beg    ,
  "pal_def"   ,      \&pex_pal_def    ,
  "pal_end"   ,      \&pex_pal_end    ,

);

# ---   *   ---   *   ---
# peso commands for cash

# to turn the interpreter on and off
sub pe_beg {

  $CACHE{-PE_RUN}=1;
  return pe_strip(shift);

};sub pe_end {$CACHE{-PE_RUN}=0;return PE_NIHIL;};

# ---   *   ---   *   ---
# formatting functions

# n=0..SC_M
# insert n spaces
sub pex_pad {
  my $n=shift;
  return " "x$n;

};

# insert n newlines
sub pex_newline {
  my $n=shift;
  return "\n"x$n;
  #return sprintf "\e[%iB\r",$n;

};

# ---   *   ---   *   ---

# body=text in any
# centers body according to screen width
sub pex_center_beg {

  my @body=split "\n",shift;
  my $result="";

  while(@body) {
    my $line=shift @body;
    if((index $line,PE_BEG)>-1) {
      $result=$result.pe_strip($line);
      next;

    };

    my $space=
      ($CACHE{-SC_SZX}
      -length $line)/2;

    $space--;

    $space=sprintf "\e[%iG",$space;
    $result=$result.$space.$line."\e[1B";

  };return $result;

};

# dummy
# terminate centering body
sub pex_center_end {return PE_NIHIL;};

# ---   *   ---   *   ---
# coloring functions

# palid=name
# set palette to use
sub pex_pal {
  my $palid=shift;
  $CACHE{-PE_PALID}=$palid;

  return PE_NIHIL;

};

# id=00..FF;==((bg<<4)|fg)
# set color to use
sub pex_col {

  my $s=shift;
  my ($bg,$fg)=split '',$s;

  $fg=($fg ne '_') ? (hex $fg)&0x0F : undef;
  $bg=($bg ne '_') ? (hex $bg)&0x0F : undef;

# ---   *   ---   *   ---

  if(!$fg && !$bg) {

    return "\e[0m";

  };

# ---   *   ---   *   ---

  $s='';if(defined $fg) {
    $s.=( (1,22)[$fg<=7] ).';';
    $s.=( 30+($fg&0x7) );

  };if(defined $bg) {
    $s.=(';','')[!(defined $fg)].
      ( (5,25)[$bg<=7] ).';';

    $s.=40+($bg&0x7);

  };

  return "\e[$s"."m";
};

# ---   *   ---   *   ---

# wrap text in color
# in:00..FF,text
sub C {

  my $col=shift;
  my $text=shift;
  my $reset=shift;
  $reset=(defined $reset) ? $reset : 0;

  return(

    pex_col($col).$text.((
      ('',pex_col('__'))

    )[$reset])

  );

};

# ---   *   ---   *   ---
# break text at cursor move escapes (\e[y;xH)

sub pelines {

  my $text=shift;

  my @lines=();

  my $es="\x1B\[[0-9]+;[0-9]+H";
  my $cut='#:CUT;>';

  while($text=~ s/(${es})/${cut}/) {

    my $key=$1;
    push @lines,[$key,''];

  };

  my $i=0;
  for my $value(split m/${cut}/,$text) {
    if(!length $value) {next;};
    $lines[$i]->[1]=$value;$i++;

  };return \@lines;

};

# ---   *   ---   *   ---

# get length of text discounting escapes
# in:text

sub uscpx {

  my $s=shift;
  $s=~ s/\x1B\[[;\d\?]*\w//sg;

  return $s;

};

sub L {

  my $s=shift;
  return length uscpx $s;

};

# ---   *   ---   *   ---

# palid=name
# start defining palette colors
sub pex_pal_beg {
  my $palid=shift;
  $CACHE{-PE_PALID}=$palid;

  if( !exists $PALETTES{$palid} ) {
    @PALETTES{$palid}=[
      0,0,0,0,
      0,0,0,0,
      0,0,0,0,
      0,0,0,0,

    ];

  };my $sublk=shift;
  $sublk=rtrim(ltrim(trim("$sublk")));
  pex_pal_def($sublk);

  return PE_NIHIL;

};

# n=0..F,col=#RRGGBB;
# sets palette[n] to col
sub pex_pal_def {

  my @ar=split ' ',$_[0];

  my $palid=$CACHE{-PE_PALID};
  my @pal=@{ $PALETTES{$palid} };

  while(@ar) {

    my $n=shift @ar;
    my $col=hex(shift @ar);

    $pal[$n]=$col;

  };@{ $PALETTES{$palid} }=@pal;
  return PE_NIHIL;

};

# dummy
# stop palette definition
sub pex_pal_end {return PE_NIHIL;};

# ---   *   ---   *   ---
# utils

# cleanse ws
sub ltrim {my $s=shift;$s=~s/^\s+//    ;return $s;};
sub rtrim {my $s=shift;$s=~s/\s+$//    ;return $s;};
sub  trim {my $s=shift;$s=~s/^\s|\s+$//;return $s;};

# get (r,g,b) from rrggbbhex
sub rrggbb_decode {
  my $lit=shift;

  my $b=($lit & 0x0000FF)>> 0;
  my $g=($lit & 0x00FF00)>> 8;
  my $r=($lit & 0xFF0000)>>16;

  return ($r,$g,$b);

};

# ---   *   ---   *   ---

# remove ws between string and substr
sub despace {
  my $s=ltrim shift;
  my $c=shift;
  if(!$c) {return ltrim $s;};

  $s=ltrim substr $s,length $c,length $s;
  return $c.$s;

};

# ---   *   ---   *   ---

# f=function, args=arg0,arg1,..argn
# wrap peso as f,arg..argn
sub pe_scpx {
  my $argc=$#_;
  if($argc<0) {return;};

  my $f=shift;

  my $s=PE_BEG."$f";
  while($argc>0) {
    $s=$s." ".shift;
    $argc--;

  };return $s.PE_END;

};

# ---   *   ---   *   ---
# formatting utils

# line=line to wrap
# space=avail chars
# yield (sub,line-sub) wrapped at word
sub wrap_word {

  my $line=shift;
  my $space=shift;

  my $len=length $line;

  # early exit
  if($len<=$space) {
    return ('',$line);

  };

# ---   *   ---   *   ---

  # there is a new line
  if($line=~ m/^([^\n]+)\n/) {

    my $s=$1;

    if($space>=length rtrim($s)) {
      my $ss="\Q$s";
      $line=~ s/^${ss}\n//;

      return (rtrim($s),$line);

    };
  };

# ---   *   ---   *   ---

  # else wrap
  my $sub=substr $line,0,$space;
  my $rem=substr $line,length $sub,$len;

  # sub endswith ws or rem startswith ws
  my $sub_w=($sub=~ m/((\s+)|(\n))$/);
  my $rem_w=($rem=~ m/^((\s+)|(\n))/);

# ---   *   ---   *   ---

  # fail: find earlier place to cut
  if(!$sub_w && !$rem_w) {

    $sub=~ s/(.*[\s+|\.|\,])//;$sub=$1;

    # failure to earlier cut? then just cut
    if(!$sub) {$sub=substr $line,0,$space;}
    $rem=substr $line,length $sub,$len;

  };return (rtrim($sub),ltrim($rem));


};

# ---   *   ---   *   ---
# arg handling utils

# makes a call table from (-n,--n), (\&call)
sub mcalltab {

  my @opts=@{ $_[0] };
  my @calls=@{ $_[1] };

  my %table;

  while(@opts) {

    # take names and discard description
    my @names=split ',',(shift @opts);
    shift @opts;

    # assign call to all related names
    my $call=shift @calls;
    while(@names) {

      # clear <tip> tags;
      # i.e. -f <path> clears <path> from string
      my $name=shift @names;
      $name=~ s/\s*\<[\w|\d]*\>//;

      $table{$name}=$call;

    };

  };

  return \%table;

};

# ---   *   ---   *   ---

# build optable
sub moptab {

  my @opts=();
  my @calls=();

  while(@_) {

    my $names=shift;
    my $desc=shift;
    push @opts,($names,$desc);

    my $call=shift;
    push @calls,$call;

  };$CACHE{-CALLTAB}=mcalltab(\@opts,\@calls);

  return \@opts;

};

# ---   *   ---   *   ---

# goes through argv
sub runtab {

  my $args=shift;
  my %tab=%{ $CACHE{-CALLTAB} };

  # no args provided
  if(!@$args && $tab{'--help'}) {
    $tab{'--help'}->();

  };

  # normal call
  while(@$args

  && grep m/@${ args[0] }/,
    keys %tab

  ) {

    my $opt=shift @$args;
    $tab{$opt}->();

  };

};

# ---   *   ---   *   ---
1; #ret
