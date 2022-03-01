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

  );my %K=(

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
      cash::C('0F','-[').
      cash::C('09','~').
      cash::C('0F',']'),

      cash::C('0F','-[').
      cash::C('0A','x').
      cash::C('0F',']'),

    ],

    -HED => [
      ''.chr(0x01D6).' < ',
      ' >'

    ],

  );binmode(STDOUT, ":utf8");

# ---   *   ---   *   ---
# card managing

# in:name
sub new_card {

  $CACHE{-CARD}={

    'id'    => shift,
    'tasks' => [],

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

  };

};

# in:idex
# marks task as done
sub do_task {
  my $idex=shift;
  $CACHE{-CARD}->{'tasks'}[$idex]{'done'}^=1;

};

# ---   *   ---   *   ---

sub draw {

  my $s="";my $last_l=0;

  # get screen dimentions and card name
  my ($sc_y,$sc_x)=cash::tty_sz();
  my $title=$CACHE{-CARD}->{'id'};

  # draw header
  {  my $col='00r';

     my $header=(

      cash::pex_col($col).

      $CHARS{-HED}->[0].
      $title.

      $CHARS{-HED}->[1]

    );

    # calc escapes length
    my $pad=$sc_x-cash::L($header);

    # format and colorize
    $s.=$header.cash::C(

      $col,sprintf("\%-".$pad."s",'')

    )."\r\n\r\n";

  };

# ---   *   ---   *   ---

  for my $ref(@{ $CACHE{-CARD}->{'tasks'} }) {
    my %h=%{ $ref };

    # fetch task data
    my $done=@{ $CHARS{-DONE} }[$h{'done'}];

    my $todo=$h{'todo'};
    my $t=$done.' ';

    my $pad=cash::L($done)+1;
    my $space=$sc_x-$pad-3;

# ---   *   ---   *   ---

    # wrap task description
    my $cnt=0;
    my $sub=1;while($sub) {
      ($sub,$todo)=cash::wrap_word(
        $todo,$space

      );if($sub) {
        $cnt++;$t.="$sub\r\n".(' 'x$pad);

      };

# ---   *   ---   *   ---

    # join strings
    };$t=($cnt | $last_l)
      ? "\r\n$t$todo\r\n"
      : "$t$todo\r\n"

      ;$s.=$t;$last_l=$cnt!=0;

  };

  return $s;

};

# ---   *   ---   *   ---

sub run {

  # initialize console
  lycon::keynt(genks::pl_keymap(\%K));
  lycon::clknt(0x6000,"\x01A9",1);

  my @cl=('0','1','2','3');
  print "\e[?25l\e[1J\e[1;1H".( draw() );

  # main loop
  my $i=0;while(1) {

    # get env data
    my ($sz_x,$sz_y)=cash::tty_sz();

    my $busy=lycon::gtevcnt();
    if($busy) {
      print "\e[1;1H".( draw() );

    };lycon::tick($busy);
    print "\e[20;1H".$cl[$i];$i++;$i&=3;

    lycon::keyrd();

    if(lycon::keyrel($K{-ESC})) {last;};

    lycon::keychk();

    if(lycon::keyhel($K{-AUP})) {
      $CACHE{-PTR_Y}-=$CACHE{-PTR_Y}>0;

    } elsif(lycon::keyhel($K{-ADOWN})) {
      $CACHE{-PTR_Y}+=$CACHE{-PTR_Y}<$sz_x;

    };

  };print "\e[0m\e[1J\e[1;1H\e[?25h";
};

# ---   *   ---   *   ---
1; # ret
