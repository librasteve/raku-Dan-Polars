#!/usr/bin/env raku

#run by hand from ~

my @lines = q:to/END/;
zef install Dan
export PSIXSTEVE=1
git clone https://github.com/p6steve/raku-Dan-Polars.git
cd raku-Dan-Polars/dan/src
cargo build
git config --global user.name "p6steve"
git config --global user.email "p6steve@furnival.net"
END

for @lines { shell $_ }
