class Build {
    method build($dist-path) {
        
        chdir 'dan';        
        warn ' Building Rust Polars library (may take a few minutes).';
        my $proc = Proc::Async.new: <cargo build>;
        $proc.bind-stdout($*ERR);
        my $promise = $proc.start;
        await $promise;
        
        chdir '..';
        mkdir 'resources';
        mkdir 'resources/libraries';
        mkdir 'resources/test_data';
        move 'bin/test_data/*', 'resources/test_data';
        move 'dan/target/debug/libdan.so', 'resources/libraries/libdan.so';
        
        warn 'Build successful';
        
        exit 0
    }
}
