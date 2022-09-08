class Build {
    method build($dist-path) {
        
        chdir 'dan';        
        warn ' Building Rust Polars library (may take a few minutes).';
        my $proc = Proc::Async.new: run <cargo build>;
        $proc.bind-stdout($*ERR);
        $proc.start;
        
        chdir '..';
        mkdir 'resources';
        mkdir 'resources/library';
        move 'dan/target/debug/libdan.so', '../resources/library';
        
        warn 'Build successful';
        
        exit 0
    }
}
