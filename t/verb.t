use strict;
use warnings;

use Encode;
use Test::More tests => 4;
use lib 'lib/';
use Text::MeCab::More;
my $mecab = Text::MeCab::More->new();

subtest '動詞の連用接続' => sub {                                           #1
    plan tests => 3;

    my @parsed = $mecab->parse('混み合う。賄いきれない。振り切れる。');
    my @text =qw( 混み合う 賄いきれ 振り切れる );
    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '動詞';
        is encode_utf8($node->{surface}), $text[$i],
         encode_utf8($node->{surface} . "\t: " . $node->{pos});

        $i++;
    }
};

subtest '形容詞の連用接続' => sub {                                         #2
    plan tests => 3;

    my @parsed = $mecab->parse('眠くなる 眠くなくなる 眠くなくなくなっちゃわない');
    my @text =qw( 眠くなる 眠くなくなる 眠くなくなくなっちゃわ );

    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '動詞';
        is encode_utf8($node->{surface}), $text[$i],
        encode_utf8($node->{surface} . "\t: " . $node->{pos});
        $i++;
    }
};

subtest '形容詞のガル接続' => sub {                                         #3
    plan tests => 2;

    my @parsed = $mecab->parse('美しがる 羨ましがらない');
    my @text =qw( 美しがる 羨ましがら );

    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '動詞';
        is encode_utf8($node->{surface}), $text[$i],
         encode_utf8($node->{surface} . "\t: " . $node->{pos});
        $i++;
    }
};

subtest '〜過ぎる' => sub {                                               #4
    plan tests => 3;

    my @parsed = $mecab->parse('美し過ぎる 臭すぎる 自信がなさ過ぎる');
    my @text =qw( 美し過ぎる 臭すぎる なさ過ぎる );

    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '動詞';
        is encode_utf8($node->{surface}), $text[$i],
        encode_utf8($node->{surface} . "\t: " . $node->{pos});
        $i++;
    }
};

done_testing;
