FROM p6steve/rakudo:rusty

ENV PATH="${PATH}:/root/.cargo/bin"

RUN zef install https://github.com/p6steve/raku-Dan-Polars.git --verbose
