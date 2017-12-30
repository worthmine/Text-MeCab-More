package Text::MeCab::More;
$VERSION = 0.03;

use strict;
use warnings;

use Carp;
use Encode;
use utf8;

use base qw(Text::MeCab);

my %活用形 = (
    'だろ'    => '未然形',
    'だっ'    => '連用形',
    'で'     => '連用形',
    'に'     => '連用形',
    'だ'     => '終止形',
    'な'     => '連体形',
    'なら'    => '仮定形',
);

=encoding utf-8

=head1 NAME

Text::MeCab::More - a parser for Japanese texts more strict

=head1 SYNOPSIS

 my $tmm = Text::MeCab::More;

=head1 DESCRIPTION

=head1 Constructor and initialization

=head2 new()

No arguments are required.

=head1 Methods and Subroutines

=head2 parse( $text )

This is the core method of this module.
I know I have to write the description for this method. but not yet.

=cut

sub parse {
    my $self = shift;
    my $text = shift;
    my @parsed = ();
    for ( my $node = $self->SUPER::parse($text); $node; $node = $node->next ){
        next if $node->stat =~ /[23]/; # skip MECAB_(BOS|EOS)_NODE
        my @features = split ',', decode_utf8($node->feature);
        next if $features[0] =~ /^(:?記号|補助記号|フィラー)$/;
        push @parsed, {
            surface => decode_utf8($node->surface),
            feature => \@features,
            pos     => $features[0],
            prev    => $node->prev,
            node    => $node,
            cost    => $node->cost,
        };
    }
    foreach my $node (@parsed) { # 一旦パースしきらないと定義できない。
        $node->{next} = $node->{node}->next;
    }

    my $i = 0;
    foreach my $node (@parsed) {
        $i++;
        next unless $node->{feature}[0] =~ /^(:?名詞|接頭詞|動詞|形容詞|助動詞)$/;
        my $next = $node->{next};
        my @next_feature = split ',', decode_utf8($next->feature);
        if( $node->{feature}[0] eq '接頭詞' and $next_feature[0] eq '名詞' ) {
            $node = $self->_join_prefix( $node, \@parsed, $i );
        }elsif( $node->{feature}[0] eq '名詞' ) {
            if( $node->{feature}[1] eq '形容動詞語幹' and decode_utf8($next->surface) =~ /^(だろ|だっ|で|に|だ|な|なら)$/ ) {
                $node = $self->_make_adjectival_noun( $node, \@parsed, $i );
            }elsif( $node->{feature}[1] eq '副詞可能' ) {
                carp "副詞可能名詞の検出: $next_feature[0] at $i";

=cut
                #なんとかならんか検討中
                $node->{pos} = '副詞';
                $node->{feature} = [ '副詞', '副詞可能名詞', '*', '*', '*', '*',
                $node->{feature}[6],
                $node->{feature}[7],
                $node->{feature}[8],
                ];
                $node->{cost} += $next->cost;
=cut
                
            }elsif( $node->{feature}[1] =~ /^サ変/ ) {
                if( $next_feature[0] eq '動詞' and $next_feature[4] =~ /^サ変/ ) {
                    $node = $self->_make_doing( $node, \@parsed, $i );
                }
            }elsif( $next_feature[0] eq '名詞' and $next_feature[1] eq '接尾' ){
                $node = $self->_join_noun( $node, \@parsed, $i );
            }elsif( $next_feature[0] eq '名詞' and $next_feature[2] =~ /^(:?サ変|形容動詞語幹)/ ) {
                $node = $self->_join_noun( $node, \@parsed, $i );
            }
        }elsif( $node->{feature}[0] eq '動詞' ) {
            if( $node->{feature}[5] =~ /^連用/ and $next_feature[0] eq '動詞' ) {
                $node = $self->_join_verb( $node, \@parsed, $i );
            }
        }elsif( $node->{feature}[0] eq '助動詞' ) {
            if( $node->{feature}[5] =~ /^連用/ and $next_feature[0] eq '動詞' ) {
                $node = $self->_join_verb( $node, \@parsed, $i );
            }
        }elsif( $node->{feature}[0] eq '形容詞' ) {
            if( $node->{feature}[5] =~ /^連用/ and $next_feature[0] =~ /^(:?助動詞|動詞)$/ ) {
                $node = $self->_join_verb( $node, \@parsed, $i );
            }elsif( $node->{feature}[5] eq 'ガル接続' and $next_feature[0] eq '動詞' ) {
                $node = $self->_join_verb( $node, \@parsed, $i );
            }elsif( $node->{feature}[5] eq 'ガル接続' and $next_feature[6] eq 'さ' ) {
                $node = $self->_join_verb( $node, \@parsed, $i );
            }
        }
    }

    foreach my $node (@parsed) { # 一旦連結しないと定義できない。
        $node->{pos}      ||= $node->{feature}[0];
        $node->{baseform} ||= $node->{feature}[6];
        $node->{reading}  ||= $node->{feature}[7];
    }

    return wantarray? @parsed: \@parsed;
}

sub _join_verb {    # 連用形の動詞をくっつける
    my $self = shift;
    my $node = shift;
    my $parsed = shift;
    my $i = shift;
    my $next = $node->{next};
    my @next_feature = split ',', decode_utf8($next->feature);
    return $node unless $next_feature[0] =~ /^(:?動詞|助動詞|名詞)$/;
    return $node if $next_feature[0] eq'名詞' and decode_utf8($next->surface) ne 'さ';
    return $node if decode_utf8($next->surface) eq 'ない';
    if( $next_feature[0] !~ /^(:?名詞)$/ or $next_feature[1] eq '接尾' or $next_feature[6] =~/(:?すぎる|過ぎる)/ ){
        $node->{pos} = '動詞';
        $node->{feature} = [ '動詞', '自立', '連用接続',
            @next_feature[ 3..5 ],
            $node->{surface}    . $next_feature[6],
            $node->{feature}[7] . $next_feature[7],
            $node->{feature}[8] . $next_feature[8],
        ];
        $node->{surface} .= decode_utf8($next->surface);
        $node->{cost} += $next->cost;
        splice @$parsed, $i, 1;
        $node->{next} = $next->next;
    }
    my @next_next = split ',', decode_utf8($node->{next}->feature);
    if( $node->{feature}[5] =~ /^連用/ and $next_next[0] =~ /^(:?動詞|助動詞)$/  ) {
        $node = $self->_join_verb( $node, $parsed, $i );
    }elsif( $node->{feature}[6] eq 'なさ' and $next_next[0] =~ /^(:?動詞|助動詞)$/  ) {
        $node = $self->_join_verb( $node, $parsed, $i );
    }
    return $node;
}

sub _make_doing { # サ変動詞を作る
    my $self = shift;
    my $node = shift;
    my $parsed = shift;
    my $i = shift;
    my $next = $node->{next};
    my @next_feature = split ',', decode_utf8($next->feature);
    return $node if $next_feature[4] ne 'サ変・スル';

    $node->{pos} = '動詞';
    $node->{feature} = [ '動詞', 'サ変動詞', '*', '*', '*',
        $next_feature[5],
        $node->{feature}[6] . $next_feature[6],
        $node->{feature}[7] . $next_feature[7],
        $node->{feature}[8] . $next_feature[8],
    ];
    $node->{cost} += $next->cost;
    $node->{surface} .= decode_utf8($next->surface);
    splice @$parsed, $i, 1;
    $node->{next} = $next->next;
    return $node;
}

sub _make_adjectival_noun { # 形容動詞を作る
    my $self = shift;
    my $node = shift;
    my $parsed = shift;
    my $i = shift;
    my $next = $node->{next};
    return $node if decode_utf8($next->surface) !~ /^(だろ|だっ|で|に|だ|な|なら)$/;
    my @next_feature = split ',', decode_utf8($next->feature);
    $node->{pos} = '形容動詞';
    $node->{feature} = [ '形容動詞', '*', '*', '*', '*',
        $活用形{$&},
        $node->{feature}[6] . $next_feature[6],
        $node->{feature}[7] . $next_feature[7],
        $node->{feature}[8] . $next_feature[8],
    ];
    $node->{cost} += $next->cost;
    $node->{surface} .= decode_utf8($next->surface);
    splice @$parsed, $i, 1;
    $node->{next} = $next->next;
    return $node;
}

sub _join_noun { # 連続した名詞をくっつける
    my $self = shift;
    my $node = shift;
    my $parsed = shift;
    my $i = shift;
    my $next = $node->{next};
    my @next_feature = split ',', decode_utf8($next->feature);
    return $node if $next_feature[0] !~ /(:?名詞|動詞)/;
    return $node if $next_feature[1] =~ /^(:?代名詞|固有名詞)$/;
    if( $next_feature[0] eq '名詞' ){
        $node->{feature} = [ '名詞',
            $node->{feature}[1] eq '*'? $next_feature[1] : $node->{feature}[1],
            $node->{feature}[2] eq '*'? $next_feature[2] : $node->{feature}[2],
            $node->{feature}[3] eq '*'? $next_feature[3] : $node->{feature}[3],
            $node->{feature}[4] eq '*'? $next_feature[4] eq '*'? '熟語': '*' : $node->{feature}[4],
            $node->{feature}[5] eq '*'? $next_feature[5] : $node->{feature}[5],
            $node->{feature}[6] . $next_feature[6],
            $node->{feature}[7] . $next_feature[7],
            $node->{feature}[8] . $next_feature[8],
        ];
        $node->{surface} .= decode_utf8($next->surface);
        splice @$parsed, $i, 1;
        $node->{next} = $next->next;
    }

    my @next_next = split ',', decode_utf8($next->feature);
    if( $node->{feature}[2] eq '形容動詞語幹' ){
        $node = $self->_make_adjectival_noun( $node, $parsed, $i );
    }elsif( $next_next[0] eq '名詞' ) {
        $node = $self->_join_noun( $node, $parsed, $i );
    }elsif( $next_next[0] eq '動詞' and $node->{feature}[2] =~ /^サ変/ and $next_next[4] eq 'サ変・スル' ) {
        $node = $self->_make_doing( $node, $parsed, $i );
    }
    return $node;
}

sub _join_prefix {  # 接頭詞を後ろの名詞にくっつける
    my $self = shift;
    my $node = shift;
    my $parsed = shift;
    my $i = shift;
    my $next = $node->{next};
    my @next_feature = split ',', decode_utf8($next->feature);
    return $node if $next_feature[0] ne '名詞';
    return $node if $next_feature[1] =~ /^(:?代名詞|固有名詞)$/;
    $node->{pos} = '名詞';
    $node->{cost} = $next->cost;
    $node->{feature} = [
        @next_feature[0..5],
        $node->{feature}[6] . $next_feature[6],
        $node->{feature}[7] . $next_feature[7],
        $node->{feature}[8] . $next_feature[8],
    ];
    $node->{surface} .= decode_utf8($next->surface);
    splice @$parsed, $i, 1;
    $node->{next} = $next->next;
    my @next_next = split ',', decode_utf8($next->feature);
    if( $next_next[0] eq '名詞' and $next_next[1] !~ /^(:?代名詞|固有名詞)$/  ) {
        $node = $self->_join_noun( $node, $parsed, $i );
    }
    return $node;
}

1;

__END__

=head1 SEE ALSO

=over

=item L<GitHub|https://github.com/worthmine/Text-MeCab-More>

=back

=head1 LICENSE

Copyright (C) Yuki Yoshida(worthmine).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(worthmine) E<lt>worthmine!at!gmail.comE<gt>
