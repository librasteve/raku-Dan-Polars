class Build {
    method build($dist-path) {
        warn '> Running cargo build against Polars Cargo.toml (may take a few mins).';
        chdir 'dan';
          
        my $proc = Proc::Async.new: run <cargo build>;
        $proc.bind-stdout($*ERR);
        $proc.start;
    }
}
