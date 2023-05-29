#!/usr/bin/env raku

#setup process when doing manual install on librasteve/rakudo:rusty for module dev
#run by hand from ~

my @lines = q:to/END/;
zef install Dan
git clone https://github.com/librasteve/raku-Dan-Polars.git
export PSIXSTEVE=1
export RAKULIB=./raku-Dan-Polars/lib
cd raku-Dan-Polars/dan/src
cargo build
git config --global user.name "librasteve"
git config --global user.email "librasteve@furnival.net"
END

for @lines { shell $_ }
