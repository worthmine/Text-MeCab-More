use strict;
use warnings;

use Encode;
use Test::More tests => 9;
use lib 'lib/';

use_ok 'Text::MeCab::More';                                             # 1

my $mecab = new_ok('Text::MeCab::More');                                # 2

my @parsed = $mecab->parse('わたしもたわしをわたしたわ');
my @text =qw( わたし も たわし を わたし た わ );

my $i = 0;
foreach my $node (@parsed) {                        #3-9
    is encode_utf8($node->{surface}), $text[$i], encode_utf8( $node->{surface} . "\t: " . $node->{pos} );
    $i++;
}

done_testing;
