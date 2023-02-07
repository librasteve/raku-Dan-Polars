#!/usr/bin/env raku

#setup process when doing manual install on p6steve/rakudo:rusty for module dev
#run by hand from ~

my @lines = q:to/END/;
cd ~
zef install Dan
git clone https://github.com/p6steve/raku-Dan-Polars.git
export PSIXSTEVE=1 && export RAKULIB=~/raku-Dan-Polars/lib
cd raku-Dan-Polars/dan/src
cargo build
git config --global user.name "p6steve"
git config --global user.email "p6steve@furnival.net"
END

for @lines { shell $_ }
