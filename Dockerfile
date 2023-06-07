FROM librasteve/rakudo:rusty

ENV PATH="${PATH}:/root/.cargo/bin"

RUN zef install https://github.com/librasteve/raku-Dan-Polars.git --verbose

RUN cd /root
RUN git clone https://github.com/librasteve/raku-Dan-Polars.git
