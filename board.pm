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

  use utf8;

  use lib $ENV{'ARPATH'}.'/help/';

  use cash;
  use genks;

  use lycon;


# ---   *   ---   *   ---
# info

  use constant {
    VERSION =>  '0.1b',
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

  );my %K=my @K=(

    -ESC=>['escape',''],

    -LALT=>['LAlt',''],
    -RALT=>['RAlt',''],
    -LSHIFT=>['LShift',''],

    -AUP=>['up',''],
    -ADWN=>['down',''],
    -ARGT=>['right',''],
    -ALFT=>['left',''],

    -ERET=>['ret',''],

  );

# ---   *   ---   *   ---
# drawing macros

  my %CHARS=(

    -DONE => [
      cash::C('_F','  [').
      cash::C('_9','~').
      cash::C('_F',']',1),

      cash::C('_F','  [').
      cash::C('_A','x').
      cash::C('_F',']',1),

    ],

    -HED => [
      chr(0x01D6),

      cash::C('_3',' < '),
      cash::C('_3',' > ')

    ],

  );binmode(STDOUT, ":utf8");

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

sub load_cards {
  ;

};

# ---   *   ---   *   ---
# task managing

# in:todo
# adds a new task to the board
sub add_task {

  push @{ $CACHE{-CARD}->{'tasks'} },{

    'todo'  => shift,

    'prio'  => 0,
    'done'  => 0,

  };calc_progress();

};

# in:idex
# toggle task done/not done
sub do_task {

  my $idex=shift;

  $CACHE{-CARD}->{'tasks'}[$idex]{'done'}^=1;
  calc_progress();

};

sub calc_progress {

  my ($done,$total)=(0,0);
  for my $t(@{$CACHE{-CARD}->{'tasks'}}) {
    $total++;$done+=$t->{'done'};

  };my $val=($done/$total);
  my $bar="\x{01E3}"x(int($val*16));

  my $col1=cash::C('_4','');
  my $col2=cash::C('_F','');
  my $col3=cash::C('_3','');

  my $fm=('%.3f','%.2f','%.1f')[

    ($val>=0.1)+($val>=1.0)

  ];

  $CACHE{-CARD}->{'progress'}=sprintf(

    "\{$col1%-16ls$col2\}".
    " $col3$fm$col2%%",$bar,($val*100)

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

        $t.=("$alt_selch$sub\r\n","$sub\r\n")[!$cnt].
          (' 'x$pad);

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

  };return $s;

};

# ---   *   ---   *   ---

sub quit {
  print "\e[0m\e[1J\e[1;1H\e[?25h";
  exit;

};

sub run {

  # initialize console
  lycon::keynt(genks::pl_keymap(\%K,\@K));

  # set key callbacks
  my $k_up=lycon->ffi()->closure(

    sub {$CACHE{-PTR_Y}--;}

  );lycon::keycall($K{-AUP},0,$k_up);

  my $k_dwn=lycon->ffi()->closure(

    sub {$CACHE{-PTR_Y}++;}

  );lycon::keycall($K{-ADWN},0,$k_dwn);

  my $k_esc=lycon->ffi()->closure(

    \&quit

  );lycon::keycall($K{-AESC},2,$k_esc);

  my $k_ret=lycon->ffi()->closure(

    sub {

      do_task($CACHE{-CARD}->{'sel_task'});

    }

  );lycon::keycall($K{-ERET},2,$k_ret);

# ---   *   ---   *   ---

  my $clk_i=8;
  my $clk_v=''.
    "\x{01A9}\x{01AA}\x{01AB}\x{01AC}".
    "\x{01AD}\x{01AE}\x{01AF}\x{01B0}"

  ;lycon::clknt(0x6000,$clk_v,$clk_i);

# ---   *   ---   *   ---  

  print "\e[?25l\e[1J\e[1;1H".( draw() );

  # main loop
  while(1) {

    my $busy=lycon::gtevcnt();
    if(1) {
      print "\e[1;1H".( draw() );

    };lycon::tick($busy);
    print sprintf(
      "\e[%i;1H%lc",

      $CACHE{-SCR_Y},
      lycon::clkdr()

    );

    lycon::keyrd();lycon::keychk();

  };quit();
};

# ---   *   ---   *   ---
1; # ret
