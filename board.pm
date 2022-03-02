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
      cash::C('_F','-[').
      cash::C('_9','~').
      cash::C('_F',']'),

      cash::C('_F','-[').
      cash::C('_A','x').
      cash::C('_F',']'),

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
  { my $header=(

      cash::pex_col('_4').
      $CHARS{-HED}->[0].
      $CHARS{-HED}->[1].

      cash::pex_col('_2').
      $title.

      $CHARS{-HED}->[2]

    );

    # calc escapes length
    my $pad=length($header)-cash::L($header);

    # format and colorize
    $s.=cash::C('8_',

      sprintf("\%-".($sc_x+$pad)."s",$header),1

    )."\r\n\r\n";

  };

# ---   *   ---   *   ---

  my $len=@{ $CACHE{-CARD}->{'tasks'} };
  my $i=0;for my $ref(@{ $CACHE{-CARD}->{'tasks'} }) {
    my %h=%{ $ref };

    my $selected=$i==($CACHE{-PTR_Y}%$len);
    $i++;

    # fetch task data
    my $done=@{ $CHARS{-DONE} }[$h{'done'}];

    my $todo=$h{'todo'};
    my $t=$done.cash::C('_7',' ');

    my $pad=cash::L($done)+1;
    my $space=$sc_x-$pad-3;

# ---   *   ---   *   ---

    # wrap task description
    my $cnt=0;
    my $sub=1;while($sub) {
      ($sub,$todo)=cash::wrap_word(
        $todo,$space

      );if($sub) {
        $cnt++;$t.="\e[2K$sub\r\n".(' 'x$pad);

      };

# ---   *   ---   *   ---

    # join strings
    };$t=($cnt | $last_l)
      ? "\r\n$t$todo"
      : "$t$todo"

      ;

    $t="\e[2K".$t;

    $pad=length($t)-cash::L($t);
    $s.=($selected)

      ? cash::C('5_',
          sprintf(
            "\%-".($sc_x+$pad)."s",
            $t

          ),1
        )

      : $t
      ;

    $s.="\r\n";
    $last_l=$cnt!=0

  };

  return $s;

};

# ---   *   ---   *   ---

sub run {

  # initialize console
  lycon::keynt(genks::pl_keymap(\%K,\@K));

  my $clk_i=8;
  my $clk_v=''.
    "\x{01A9}\x{01AA}\x{01AB}\x{01AC}".
    "\x{01AD}\x{01AE}\x{01AF}\x{01B0}"

  ;lycon::clknt(0x6000,$clk_v,$clk_i);

  my @cl=('0','1','2','3');
  print "\e[?25l\e[1J\e[1;1H".( draw() );

  # main loop
  while(1) {

    # get env data
    my ($sz_x,$sz_y)=cash::tty_sz();

    my $busy=lycon::gtevcnt();
    if(1) {
      print "\e[1;1H".( draw() );

    };lycon::tick($busy);
    print sprintf("\e[%i;1H%lc",$sz_y,lycon::clkdr());

    lycon::keyrd();

    if(lycon::keyrel($K{-ESC})) {last;};
lycon::keychk();

    if(lycon::keyrel($K{-AUP})) {
      $CACHE{-PTR_Y}--;

    };if(lycon::keytap($K{-ADWN})) {
      $CACHE{-PTR_Y}++;

    };

  };print "\e[0m\e[1J\e[1;1H\e[?25h";
};

# ---   *   ---   *   ---
1; # ret
