#!/usr/bin/perl
# ---   *   ---   *   ---
# BOARD
# Visualize what you do
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package board;
  use strict;
  use warnings;

  use Cwd qw(abs_path);

  use lib $ENV{'ARPATH'}.'/lib/';

  use cash;
  use sector;
  use vec4;
  use lycon;


# ---   *   ---   *   ---
# info

  use constant {
    VERSION =>  '0.2b',
    AUTHOR  =>  'IBN-3DILA',

  };

# ---   *   ---   *   ---
# global state

my %CACHE=(

  -CARD  => {},

  -PTR_X => 0,
  -PTR_Y => 0,
  -UPDATE=> 0,

);

# ugh. put this on cache later
my @DATA=();

# ---   *   ---   *   ---

;;sub on_exit {

  save_card();
  lycon::loop::set_quit(sub {return 1;});

};sub on_accept {
  do_task($CACHE{-CARD}->{'sel_task'});
  $CACHE{-UPDATE}=1;

# ---   *   ---   *   ---

};sub sel_change {

  $CACHE{-CARD}->{'sel_task'}=(

    $CACHE{-PTR_Y}%(@{
      $CACHE{-CARD}->{'tasks'}

    })

  );$CACHE{-UPDATE}=1;

# ---   *   ---   *   ---
# give lycon some data about this module

};lycon::ctl::REGISTER(

  -EXIT,[0,0,\&on_exit],
  -ACCEPT,[\&on_accept,0,0],
  -MOV_A,[

    sub {$CACHE{-PTR_Y}--;sel_change;},0,0,
    sub {$CACHE{-PTR_Y}++;sel_change;},0,0,

  ],

);sub QUEUE {
  return lycon::ctl::get_module_queue;

};

# ---   *   ---   *   ---
# drawing macros

my %CHARS=(

  -DONE => [

    cash::C('_F','  [',0).
    cash::C('_1','~',0).
    cash::C('_F','] ',0),

    cash::C('_F','  [',0).
    cash::C('_2','x',0).
    cash::C('_F','] ',0),

    cash::C('_F','  [',0).
    cash::C('_3','^',0).
    cash::C('_F','] ',0),

  ],

# ---   *   ---   *   ---

  -HED => [

    '['.chr(0x01D6),

    ': ',
    ' ',

    ' ]',

  ],

);

# ---   *   ---   *   ---
# card managing

# in:name
sub new_card {

  $CACHE{-CARD}={

    'id' => shift,
    'filepath'=>shift,

    'tasks' => [],
    'sel_task' => 0,
    'progress' => 0.0,

  };

};

# ---   *   ---   *   ---
# read task list from file

sub load_card {

  my $path=abs_path(shift);

  if(!-e $path) {
    lycon::FATAL("$path: no such file\r\n");

  };

  my @lines=split ";\n",`cat $path`;

  my $id=shift @lines;
  new_card($id,$path);

  for my $line(@lines) {
    $line=cash::trim($line);

    if(length $line) {
      my ($trash,$done,$todo)
        =split m/^(x|~)\s*/,$line;

      add_task($todo,$done eq 'x');

    };
  };


# ---   *   ---   *   ---
# write task list to file

};sub save_card {

  my $card=$CACHE{-CARD};
  my $s=$card->{'id'}.";\n\n";

  for my $task(@{$card->{'tasks'}}) {
    $s.=('~','x')[$task->{'done'}].' ';
    $s.=$task->{'todo'}.";\n";

  };

  open FH,'>',$card->{'filepath'} or die $!;
  print FH $s;
  close FH;

};

# ---   *   ---   *   ---
# task managing

# in:todo
# adds a new task to the board
sub add_task {

  my $name=shift;
  my $done=shift;

  if(!defined $done) {$done=0;};

  push @{ $CACHE{-CARD}->{'tasks'} },{

    'todo'  => $name,

    'prio'  => 0,
    'done'  => $done,

  };calc_progress();

};

# ---   *   ---   *   ---
# in:idex
# toggle task done/not done

sub do_task {

  my $idex=shift;

  $CACHE{-CARD}->{'tasks'}->[$idex]->{'done'}^=1;
  calc_progress($DATA[2]->sz->x-4);

};

# ---   *   ---   *   ---
# makes the progress bar string

sub calc_progress {

  my $sz=shift;
  if(!defined $sz) {$sz=16;} else {

    $sz-=length(
      $CHARS{-HED}->[0].
      $CHARS{-HED}->[1].

      $CACHE{-CARD}->{'id'}.

      $CHARS{-HED}->[2].
      $CHARS{-HED}->[3]

    )+8;

  };

# ---   *   ---   *   ---
# calculate completion percentage

  my ($done,$total)=(0,0);
  for my $t(@{$CACHE{-CARD}->{'tasks'}}) {
    $total++;$done+=$t->{'done'};

  };my $val=($done/$total);
  my $bar="\x{01E3}"x(int($val*16));


# ---   *   ---   *   ---
# get some color escapes

  my $col1=cash::C('_C','');
  my $col2=cash::C('_F','');
  my $col3=cash::C('_3','');

  # shrink decimals as integer part increases
  my $fm=('%.3f','%.2f','%.1f')[

    ($val>=0.1)+($val>=1.0)

  ];

# ---   *   ---   *   ---
# make the progress bar string

  $CACHE{-CARD}->{'progress'}=sprintf(

    "\{$col1%-".($sz)."ls$col2\}".
    " $col3$fm$col2%%",$bar,($val*100)

  );

# ---   *   ---   *   ---
# add some adornments

  $CACHE{-CARD}->{'header'}=(

    $CHARS{-HED}->[0].
    $CHARS{-HED}->[1].

    $col3.
    $CACHE{-CARD}->{'id'}.

    $col2.
    $CHARS{-HED}->[2].

    $CACHE{-CARD}->{'progress'}.

    "\e[0m".
    $CHARS{-HED}->[3]

  );

};

# ---   *   ---   *   ---
# adds checkmark fields to the fitted text

sub add_ticks {

  my $inner=shift;

  my $add_tick=1;
  my $i=0;

  my $rm=$CHARS{-DONE};
  my $pad=' 'x(cash::L($rm->[0]));

# ---   *   ---   *   ---
# iter the fitted lines

  for my $line(@{$inner->text_lines()}) {

    my $task=$CACHE{-CARD}->{'tasks'}->[$i];
    my $selected=$i==$CACHE{-CARD}->{'sel_task'};

    my $color=($selected)
      ? '8'.(split '',$inner->color)[1]
      : $inner->color
      ;

    # append tick+line
    if($add_tick) {

      # remove previous tick
      my $r0=$rm->[0];
      my $r1=$rm->[1];
      $line=~ s/^\Q${r0}//;
      $line=~ s/^\Q${r1}//;

      $line=cash::uscpx($line);

      # add new one
      $line=(
        $rm->[$task->{'done'}].
        cash::C($color,$line,1)

      );$add_tick=0;

# ---   *   ---   *   ---

    # append line
    } else {
      $line=~ s/${pad}//;
      $line=cash::uscpx($line);

      $line=$pad.cash::C($color,$line,1);

    };

    # add tick after the tag
    if($line=~ m/#:pad;>/) {
      $add_tick=1;$i++;

    };
  };
};

# ---   *   ---   *   ---
# to be run on the lycon main loop

sub update {

  (\&lycon::nope,,sub {

    my $inner=$DATA[1];
    my $prog=$DATA[2];

    add_ticks($inner);
    $inner->fill(0,'non');
    #$inner->wipe();
    $inner->draw();

    $prog->{-TEXT_LINES}=[$CACHE{-CARD}->{'header'}];
    $prog->fill();
#    $prog->wipe();
    $prog->draw();

  })[$CACHE{-UPDATE}]->();

  $CACHE{-UPDATE}=0;
  END:QUEUE->add(\&update,0);

};

# ---   *   ---   *   ---

sub ctl_take {

  my @ttysz=(0,0);lycon::ttysz(\@ttysz);

  my $sec=sector::nit(

    vec4::nit(0,0),
    vec4::nit(@ttysz),

    '07',

  );

  $sec->box();
  $sec->draw();

# ---   *   ---   *   ---

  my $text='';

  for my $task(@{$CACHE{-CARD}->{'tasks'}}) {

    $text.=$task->{'todo'};
    $text.="\n#:pad;>\n";

  };

# ---   *   ---   *   ---
# nit the rect

  my $inner=$sec->inner(3,'07');
  $inner->co->{-Y}-=1;
  $inner->co->{-X}-=2;

  # apply/fit text to rect
  $inner->text($text);

  # add ticks
  add_ticks($inner);

# ---   *   ---   *   ---

  $inner->fill(0,'non');
  $inner->draw();

# ---   *   ---   *   ---

  my $prog=sector::nit(

    vec4::nit(4,0),
    vec4::nit($ttysz[0]-4,1),

    '07'

  );

# ---   *   ---   *   ---

  calc_progress($prog->sz->x-4);
  $prog->{-TEXT_LINES}=[$CACHE{-CARD}->{'header'}];
  $prog->fill();
  $prog->draw();

# ---   *   ---   *   ---

  push @DATA,($sec,$inner,$prog);

  QUEUE->add(\&update,0);
  lycon::ctl::transfer();

};

# ---   *   ---   *   ---
1; # ret
