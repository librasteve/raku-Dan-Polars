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
        move 'dan/target/debug/libdan.so', 'resources/libraries/libdan.so';
        
        #`[
        mkdir 'resources/bin/test_data';
        my @test_files = 'bin/test_data/'.IO.dir;
        move "$_", "resources/$_" for @test_files;
        #]
        
        warn 'Build successful';
        
        exit 0
    }
}
