requires 'Text::MeCab';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'inc::Module::Install';
};

on 'test' => sub {
    requires 'Encode';
    requires 'Test::More', '0.98';
};
