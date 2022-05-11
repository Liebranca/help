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

  -SCR_X => 0,
  -SCR_Y => 0,

);

# ---   *   ---   *   ---

sub on_accept {
  do_task($CACHE{-CARD}->{'sel_task'});

};lycon::ctl::REGISTER(

  -ACCEPT,[\&on_accept,0,0],
  -MOV_A,[

    sub {$CACHE{-PTR_Y}--;},0,0,
    sub {$CACHE{-PTR_Y}++;},0,0,

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
    'tasks' => [],
    'sel_task' => 0,
    'progress' => 0.0,

  };

};

sub load_card {

  my $path=abs_path(shift);
  my @lines=split ";\n",`cat $path`;

  my $id=shift @lines;
  new_card($id);

  for my $line(@lines) {
    $line=cash::trim($line);

    if(length $line) {
      my ($trash,$done,$todo)
        =split m/^(x|~)\s*/,$line;

      add_task($todo,$done eq 'x');

    };
  };

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
  calc_progress();

};

# ---   *   ---   *   ---

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

  my ($done,$total)=(0,0);
  for my $t(@{$CACHE{-CARD}->{'tasks'}}) {
    $total++;$done+=$t->{'done'};

  };my $val=($done/$total);
  my $bar="\x{01E3}"x(int($val*16));

  my $col1=cash::C('_C','');
  my $col2=cash::C('_F','');
  my $col3=cash::C('_3','');

  my $fm=('%.3f','%.2f','%.1f')[

    ($val>=0.1)+($val>=1.0)

  ];

  $CACHE{-CARD}->{'progress'}=sprintf(

    "\{$col1%-".($sz)."ls$col2\}".
    " $col3$fm$col2%%",$bar,($val*100)

  );

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

sub draw {

  my $s="";my $last_l=0;

  $CACHE{-CARD}->{'sel_task'}=(

    $CACHE{-PTR_Y}%(@{
      $CACHE{-CARD}->{'tasks'}

    })

  );

# ---   *   ---   *   ---

  # get screen dimentions and card name
  my ($sc_x,$sc_y)=(0,0);
  my $title=$CACHE{-CARD}->{'id'};

  my @ttysz=(0,0);lycon::ttysz(\@ttysz);
  ($sc_x,$sc_y)=@ttysz;

  # clear on window or font resize
  if(

     $sc_x!=$CACHE{-SCR_X}
  || $sc_y!=$CACHE{-SCR_Y}

  ) {$s.="\e[2J";};

  # save current screen size
  $CACHE{-SCR_X}=$sc_x;
  $CACHE{-SCR_Y}=$sc_y;

# ---   *   ---   *   ---

  # draw header
  {

    # calc avail space
    my $space=$sc_x-(

      cash::L(
        $CHARS{-HED}->[0].
        $CHARS{-HED}->[1]

      )+cash::L(
        $CHARS{-HED}->[2].' '.
        $CACHE{-CARD}->{'progress'}

      )

    );

# ---   *   ---   *   ---

    if(length($title)>=$space) {
      my @ar=split '',$title;
      $title=(join '',@ar[0..$space-5]).'...';

    };

# ---   *   ---   *   ---

    my $header=(

      cash::pex_col('_4').
      $CHARS{-HED}->[0].
      $CHARS{-HED}->[1].

      cash::pex_col('_2').
      $title.

      $CHARS{-HED}->[2].
      ' '.$CACHE{-CARD}->{'progress'}

    );

# ---   *   ---   *   ---

    # calc escapes length
    my $pad=length($header)-cash::L($header);

    # format and colorize
    $s.=cash::C('5_',

      sprintf("\%-".($sc_x+$pad)."s",$header),1

    )."\r\n\r\n";

  };

# ---   *   ---   *   ---

  my $i=0;for my $ref(@{ $CACHE{-CARD}->{'tasks'} }) {
    my %h=%{ $ref };

    my $selected=$i==$CACHE{-CARD}->{'sel_task'};
    $i++;

    # fetch task data
    my $done=@{ $CHARS{-DONE} }[$h{'done'}];

    my $todo=$h{'todo'};

    my $selch=' ';if($selected) {
        $selch.=''.
          cash::C('_F',"\x{0195} ",1).
          cash::C('_C','')

    };my $alt_selch="\e[2K ";if($selected) {
        $alt_selch.=''.
          cash::C('_F',"\x{0199} ",1).
          cash::C('_C','')

    };my $t="\e[2K".$done.$selch;

    my $pad=cash::L($done);
    my $space=$sc_x-$pad-8;

# ---   *   ---   *   ---

    # wrap task description
    my $cnt=0;
    my $sub=1;while($sub) {

      ($sub,$todo)=cash::wrap_word(
        $todo,$space

      );if($sub) {

        my $spad=length($sub)-cash::L($sub);
        $sub=sprintf("\%-".$spad."s",$sub);

        $t.=(

          "$alt_selch$sub\r\n",
          "$sub\r\n"

        )[!$cnt].(' 'x$pad);

        $cnt++;

      };

# ---   *   ---   *   ---

    # this or previous is multi-line item
    };if($cnt | $last_l) {

      $pad=length($todo)-cash::L($todo);
      $todo=sprintf(

        "\e[2K$alt_selch\%-".
        $space."s",

        $todo

      );$t="\r\n".$t.$todo;

# ---   *   ---   *   ---

    # this and previous is single-line item
    } else {

      $t=$t.$todo;

      $pad=length($t)-cash::L($t);
      $t=sprintf("\%-".$space."s",$t);

    };

# ---   *   ---   *   ---

    # append and go next
    $s.=cash::C('__',$t,1)."\r\n";
    $last_l=$cnt!=0;

  };lycon::loop::dwbuff($s);
  QUEUE->add(\&draw,0);

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
    my $selected=0;
      #$i==$CACHE{-CARD}->{'sel_task'};

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

sub ctl_take {

#  lycon::dpy::beg;

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
# init the rect

  my $inner=$sec->inner(4,'07');
  $inner->co->{-Y}-=2;
  $inner->co->{-X}-=2;
  $inner->sz->{-X}-=4;

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

#  alt_draw();QUEUE->add(\&alt_draw,$inner);
#  lycon::ctl::transfer();

};

# ---   *   ---   *   ---
1; # ret
