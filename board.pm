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

  use lib $ENV{'ARPATH'}.'/help/';
  use cash;


# ---   *   ---   *   ---
# info

  use constant {
    VERSION =>  '0.1b',
    AUTHOR  =>  'IBN-3DILA',

  };

# ---   *   ---   *   ---
# global state

  my %CACHE=(

    -CARD    => {},

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
      '%. { ',
      ' }',

    ],

  );

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

sub list {

  my $s='';my $last_l=0;

  # get screen dimentions and card name
  my ($sc_y,$sc_x)=cash::tty_sz;
  my $title=$CACHE{-CARD}->{'id'};

  # draw header
  { my $header=(
      @{ $CHARS{-HED} }[0].
      cash::pex_col('82').$title.cash::pex_col('8F').

      @{ $CHARS{-HED} }[1]

    );

    # calc escapes length
    my $pad=(length $header)-cash::L($header);

    # format and colorize
    $s.=cash::C(
      '8F',sprintf(
        "\e[2K\%-".( $sc_x+$pad-2 )."s\n\n",
        $header

      )
    );

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
        $cnt++;$t.="$sub\n".(' 'x$pad);

      };

# ---   *   ---   *   ---

    # join strings
    };$t=($cnt | $last_l)
      ? "\n$t$todo\n"
      : "$t$todo\n"

      ;$s.=$t;$last_l=$cnt!=0;

  };

  return $s;
};

# ---   *   ---   *   ---
1; # ret
