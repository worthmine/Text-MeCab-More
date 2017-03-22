use strict;
use warnings;

use Encode;
use Test::More tests => 3;
use lib 'lib/';
use Text::MeCab::More;
my $mecab = Text::MeCab::More->new();

subtest '形容動詞' => sub {                                                #1
    plan tests => 7;

    my @parsed = $mecab->parse('綺麗だろう 見事だった 静かで 穏便に 遺憾だ 不思議な 疑問ならば');
    my @text =qw( 綺麗だろ 見事だっ 静かで 穏便に 遺憾だ 不思議な 疑問なら );
    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '形容動詞';
        is encode_utf8($node->{surface}), $text[$i],
        encode_utf8($node->{surface} . "\t: " . $node->{pos});

        $i++;
    }
};

subtest 'サ変動詞' => sub {                                                #2
    plan tests => 3;

    my @parsed = $mecab->parse('失踪する 起動しない 納得せず');
    my @text =qw( 失踪する 起動し 納得せ );
    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '動詞';
        is encode_utf8($node->{surface}), $text[$i],
        encode_utf8($node->{surface} . "\t: " . $node->{pos});

        $i++;
    }
};

subtest '接頭辞/接尾辞' => sub {                                                #3
    plan tests => 5;

    my @parsed = $mecab->parse('フランス帰り 第二回 第一部 お中元 ご両親');
    my @text =qw( フランス帰り 第二回 第一部 お中元 ご両親 );
    my $i = 0;
    foreach my $node (@parsed) {
        next if encode_utf8($node->{pos}) ne '名詞';
        is encode_utf8($node->{surface}), $text[$i],
        encode_utf8($node->{surface} . "\t: " . $node->{pos});

        $i++;
    }
};

done_testing;
