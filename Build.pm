class Build {
    method build($dist-path) {
        warn ' Building Rust Polars library (may take a few minutes).';
        chdir 'dan';
          
        my $proc = Proc::Async.new: run <cargo build>;
        $proc.bind-stdout($*ERR);
        $proc.start;
        
        move 'target/debug/libdan.so', '../resources/library';
        
        warn 'Build successful';
        
        exit 0
    }
}
