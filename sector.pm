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

  use lib $ENV{'ARPATH'}.'/lib/';
  use avt;

  use lib $ENV{'ARPATH'}.'/help/';

  use vec4;
  use cash;
  use lycon;
  use queue;

  binmode(STDOUT, ":utf8");

# ---   *   ---   *   ---
# global state

my %CACHE=(

  -CONTINUE=>0,

);

# ---   *   ---   *   ---
# wchars used for drawing
# adjusted for lycon font

my %CHARS=(

  -WAIT=>[
    "\x{0114}","\x{0114}",
    "\x{005F}","\x{005F}",

  ],

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
# how many *frames* each pause lasts

my %STOPS=(

  '*'=>0,
  "'"=>0,
  ','=>0,

  '-'=>0,
  ';'=>1,
  ':'=>1,
  '.'=>1,

  '!'=>2,
  '?'=>2,

);{for my $value(values %STOPS) {

  my $code='';
  for my $x(0..$value) {
    $code.='lycon::tick(0);';

  };

  $value=eval("sub {$code};");

};}

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

# ---   *   ---   *   ---

sub text {

  my $self=shift;
  my $new=shift;

  if(defined $new) {

    $self->{-TEXT}=$new;

    my $rows=int(@{$self->rows()});

    $self->text_ptr(0);
    $self->text_fit();

  };

  return $self->{-TEXT};

};

# ---   *   ---   *   ---

sub text_ptr {
  my $self=shift;
  return avt::getset($self,-TEXT_PTR,shift);

};

sub text_lines {
  my $self=shift;
  return avt::getset($self,-TEXT_LINES,shift);

};

sub is_text {return defined ((shift)->text);};

# ---   *   ---   *   ---

sub text_fit {

  my $self=shift;

  my @lines=();

  my $space=$self->sz->x-$self->co->x;
  my @rows=@{$self->rows()};

  my ($rem,$sub)=(1,$self->text);

# ---   *   ---   *   ---
# wrap text at whitespaces

  while($rem) {
    ($rem,$sub)=cash::wrap_word(
      $sub,$space

    );

    if(defined $rem) {

      my $line_strip=$rem;
      $line_strip=~ s/^\s+$//sg;

      if(!length $line_strip) {next;};

      push @lines,$rem;

    }


# ---   *   ---   *   ---
# append left-overs

  };if(defined $rem.$sub) {
    my @left=split /\r?\n/,$rem.$sub;

    for my $line(@left) {

      my $line_strip=$line;
      $line_strip=~ s/^\s+$//sg;

      if(!length $line_strip) {next;};

      push @lines,$line;

    };

  };$self->text_lines(\@lines);

};

# ---   *   ---   *   ---

sub text_scroll {

  my $self=shift;
  my $dir=shift;

  my $rows=@{$self->rows()};
  my ($beg,$end)=($self->text_ptr,0);

# ---   *   ---   *   ---
# up

  if($dir) {
    $beg-=$rows;
    if($beg<0) {$beg=0;};

# ---   *   ---   *   ---
# down

  } else {

    $beg+=$rows;
    if($beg>=@{$self->text_lines()}) {
      $beg-=$rows;

    };

  };

# ---   *   ---   *   ---

  $end=$beg+$rows;
  $self->text_ptr($beg);

  return ($beg,$end-1);

};

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
# parent/child relations

;;sub setparent {

  my $self=shift;
  my $par=shift;

  push @{$par->{-CHILDREN}},$self;
  $self->{-PARENT}=$par;

};sub parent {return (shift)->{-PARENT};};
;;sub children {return (shift)->{-CHILDREN};};

# ---   *   ---   *   ---
# constructor

sub nit {

  my $co=shift;
  my $sz=shift;
  my $color=shift;

  if(!defined $color) {
    $color='07';

  };

# ---   *   ---   *   ---

  my $sec=bless {

    -CO=>$co,
    -SZ=>$sz,

    -COLOR=>$color,
    -DRAW=>[],

    -TEXT=>undef,
    -TEXT_PTR=>0,
    -TEXT_LINES=>[],

    -PARENT=>undef,
    -CHILDREN=>[],

  },'sector';

  return $sec;

};

# ---   *   ---   *   ---
# clears the rect

sub wipe {

  my $self=shift;
  my @rows=@{$self->rows()};

  my $space=$self->sz->x-$self->co->x;
  my $s='';

  for my $y(@rows) {
    $s.=sprintf
      "\e[%u;%uH%-${space}s",
      $y+1,$self->co->x,'';

  };$self->colwrap($s);
  $self->draw();

};

# ---   *   ---   *   ---
# fills rect with next page of text

sub fill {

  my $self=shift;
  my $dir=shift;

  my $selection=shift;
  my $scroll=int(0+(!defined $selection));

  my $co=$self->co;
  my $sz=$self->sz;

  my $s='';
  my @lines=();

  my $space=$self->sz->x-$self->co->x;
  my @rows=@{$self->rows()};

# ---   *   ---   *   ---
# we select lines from saved arr

  { my @all_lines=@{$self->text_lines()};

# ---   *   ---   *   ---
# handle highlighting

    if(defined $selection
    && $selection ne 'non'

    ) {

      my ($prev,$next)=split ':',$selection;

      # unscape prev
      $all_lines[$prev]=cash::uscpx(
        $all_lines[$prev]

      # invert next
      );$all_lines[$next]=
        "\e[7m".$all_lines[$next]."\e[27m";

      # scroll when going over end/top of rect
      if($next>$prev) {
        $scroll=int(($next%@rows)==0);

      } elsif($next<$prev) {
        $scroll=int(($next%@rows)==(@rows-1));;

      };

    };

# ---   *   ---   *   ---
# scroll up or down if need

    my $beg=$self->text_ptr;
    my $end=$beg+@rows-1;

    if($scroll) {
      ($beg,$end)=$self->text_scroll($dir);

    };

# ---   *   ---   *   ---
# get slice

    @lines=@all_lines[$beg..$end];

    # add padding
    for my $line(@lines) {
      if(!defined $line) {$line='';};

    };

  };

# ---   *   ---   *   ---
# build line strings

  my $i=0;
  for my $y(@rows) {

    $s.=sprintf
      "\e[%u;%uH%-${space}s",
      $y+1,$co->x,"$lines[$i]";

    $i++;

  };$self->colwrap($s);

};

# ---   *   ---   *   ---
# get a rect within a rect (yo dawg... )

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

  my $child=nit($co,$sz,$color);
  $child->setparent($self);

  return $child;

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

    $s.=sprintf "\e[%u;%uH",$y+1,$co->x+1;

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
# queues printing of rect

sub draw {

  my $self=shift;
  my $s=$self->{-DRAW};

  for my $ref(@$s) {
    lycon::loop::dwbuff(
      "$ref->[0]$ref->[1]"

    );
  };

};

# ---   *   ---   *   ---
# ^same, typewritter effect

sub slowdraw {

  my $self=shift;
  my $s=$self->{-DRAW};

# ---   *   ---   *   ---
# handle punctuation

  my $proc=sub {

    my $c=shift;
    if(exists $STOPS{$c}) {
      queue::add($STOPS{$c});

    };
  };

# ---   *   ---   *   ---
# draw the text

  my $blanks='';
  while(@$s) {

    my $ref=shift @$s;
    $blanks.="$ref->[0]";

    # skip blanks
    if($ref->[1]=~ m/^\s+$/) {
      $blanks.="$ref->[1]";next;

    };

# ---   *   ---   *   ---

    my $text=$ref->[1];
    $text=~ s/\s+$//sg;

    my @text=split '',$text;
    my $sub=$blanks;$blanks='';

    # print char by char
    for my $c(@text) {

      $sub.=$c;if($c ne ' ') {

        queue::add(sub {
          lycon::loop::dwbuff(shift);

        },$sub);$sub='';$proc->($c);

      };
    };

  };

};

# ---   *   ---   *   ---
# 'waiting' logic for multi-page print

sub rechk {

  my $self=shift;
  my $i=shift;

  my $rows=@{$self->rows()};

  if(($self->text_ptr+$rows)
  < @{$self->text_lines}) {

    my ($co,$sz)=(
      $self->parent->co,
      $self->parent->sz,

    );

    my $x=($co->x+$sz->x)-1;
    my $y=($co->y+$sz->y)-1;

# ---   *   ---   *   ---
# clear rect and go to next page

    if($CACHE{-CONTINUE}) {

      $CACHE{-CONTINUE}=0;
      $self->wipe();

      lycon::loop::dwbuff(cash::C(
        $self->parent->color,

        sprintf("\e[%u;%uH ",
        $y,$x

        ),1

      ));

      $self->text_scroll(0);
      $self->speech();

# ---   *   ---   *   ---
# draw 'waiting' charsprite

    } else {

      lycon::loop::dwbuff(cash::C(
        $self->parent->color,

        sprintf("\e[%u;%uH%ls",
        $y,$x,$CHARS{-WAIT}->[$i]

        ),1

# ---   *   ---   *   ---
# ^repeat

      ));$i++;$i&=3;
      queue::add(\&rechk,$self,$i);

    };
  };
};

# ---   *   ---   *   ---
# transfers main loop control to this module

sub ctl_take {

  my $self=shift;

  my $k_ret=lycon::kbd::SVDEF(-RET);
  my $k_space=lycon::kbd::SVDEF(-JMP);

  ;;lycon::kbd::REDEF(
    -RET,'ret',
    sub {$CACHE{-CONTINUE}=1;},
    sub {$CACHE{-CONTINUE}=1;},
    sub {$CACHE{-CONTINUE}=0;}

  );lycon::kbd::REDEF(
    -JMP,'space','','','',

  );lycon::kbd::ldkeys();

# ---   *   ---   *   ---

  lycon::ctl::switch(

    sub {
      if(queue::pending) {
        queue::ex;

      } else {

        lycon::ctl::ret;
        lycon::kbd::LDDEF(-RET,$k_ret);
        lycon::kbd::LDDEF(-JMP,$k_space);

      };

    },[],\&lycon::loop::ascii,

  );

};

# ---   *   ---   *   ---
# delivers a message in an old-school rpg way

sub speech {

  my $self=shift;

  # queue first page
  $self->fill(0,'non');
  $self->slowdraw();

  # message continues...
  queue::add(\&rechk,$self,0);

};

# ---   *   ---   *   ---
1; # ret
