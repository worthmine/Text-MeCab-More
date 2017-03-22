use strict;
use warnings;

use Encode;
use Test::More tests => 9;
use lib 'lib/';
BEGIN { use_ok 'Text::MeCab::More' }                #1

my $mecab = Text::MeCab::More->new();
is 'Text::MeCab::More', ref($mecab), 'new()';       #2

my @parsed = $mecab->parse('すもももももももものうち');
my @text =qw( すもも も もも も もも の うち );

my $i = 0;
foreach my $node (@parsed) {                        #3-9
    is encode_utf8($node->{surface}), $text[$i], encode_utf8( $node->{surface} . "\t: " . $node->{pos} );
    $i++;
}

done_testing;
