class Build {
    method build($dist-path) {
        #[ original - works
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
        #]
        
        warn 'Build successful';
        
        exit 0
    }
}

        #`[ original - works
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
        #]

        #`[ BUILD IN RESOURCES
        mkdir 'resources';
        mkdir 'resources/dan';
        mkdir 'resources/dan/src';
        mkdir 'resources/dan/target';
        mkdir 'resources/dan/target/debug';
        mkdir 'resources/dan/target/debug/deps';
        move 'dan/Cargo.toml', 'resources/dan/Cargo.toml';
        move 'dan/src/lib.rs', 'resources/dan/src/lib.rs';
        move 'dan/src/apply-template.rs', 'resources/dan/src/apply-template.rs';

        chdir 'resources/dan';        
        warn ' Building Rust Polars library (may take a few minutes).';
        my $proc = Proc::Async.new: <cargo build>;
        $proc.bind-stdout($*ERR);
        my $promise = $proc.start;
        await $promise;
        #]

        #`[ THEN REPOSITION LIBDAN.SO
        chdir '../..';
        mkdir 'resources/libraries';
        move 'resources/dan/target/debug/libdan.so', 'resources/libraries/libdan.so';
        warn qqx`cd resources/libraries && ls -al`;
        #warn qqx`tree`;
        #]
