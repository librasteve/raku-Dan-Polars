class Build {
    method build($dist-path) {
        #[ CARGO BUILD IN RESOURCES
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

        #[ THEN REPOSITION LIBDAN.SO
        chdir '../..';
        mkdir 'resources/libraries';
        move 'resources/dan/target/debug/libdan.so', 'resources/libraries/libdan.so';
        warn qqx`cd resources/libraries && ls -al`;
        #]

        #[ INSPECT THE CU FILESYSTEM AT dan
        chdir 'resources';
        warn qqx`tree`;
        my $cu = CompUnit::Repository::FileSystem.new(prefix => $*CWD.add("dan"));
        warn (dd $cu);
        warn $cu.distribution.meta<resources>;
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

        #`[ CARGO BUILD IN RESOURCES
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
