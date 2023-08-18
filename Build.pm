class Build {
    method build($dist-path) {
        #new partial
        mkdir 'resources';
        mkdir 'resources/dan';
        move 'dan/Cargo.toml', 'resources/dan/Cargo.toml';
        move 'dan/src/lib.rs', 'resources/dan/src/lib.rs';
        die 2;

        #`[ new
        chdir 'resources/dan/src';        
        warn ' Building Rust Polars library (may take a few minutes).';
        my $proc = Proc::Async.new: <cargo build>;
        $proc.bind-stdout($*ERR);
        my $promise = $proc.start;
        await $promise;
        #]

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

        #`[
        mkdir 'resources/apply';
        mkdir 'resources/apply/src';
        move 'dan/src/apply-template.rs', 'resources/apply/src/apply-template.rs';
        move 'dan/target/debug/deps/*',   'resources/apply/target/debug/deps/';
        #]
        
        warn 'Build successful';
        
        exit 0
    }
}
        
        #`[
        mkdir 'resources';
        mkdir 'resources/dan';
        move 'dan/src/*', 'resources/dan/src';
        
        chdir 'resources/dan/src';        
        warn ' Building Rust Polars library (may take a few minutes).';
        my $proc = Proc::Async.new: <cargo build>;
        $proc.bind-stdout($*ERR);
        my $promise = $proc.start;
        await $promise;
        #]
