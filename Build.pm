class Build {
    method build($dist-path) {
        warn ' Running rust cargo build against Cargo.toml (may take a few mins).';
        chdir 'dan';
          
        my $proc = Proc::Async.new: run <cargo build>;
        $proc.bind-stdout($*ERR);
        $proc.start;
    }
}
