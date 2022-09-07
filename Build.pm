class Build {
    method build($dist-path) {
        warn 'yo';
        say 'no', $dist-path;
        #say indir( 'dan', {run <cargo build>} );
        #run 'echo', 'Raku is Great!';
        #[
        my $proc = run 'echo', 'Raku is Great!', :out, :err;
        say $proc.out.slurp(:close).say; # OUTPUT: «Raku is Great!␤» 
        say $proc.err.slurp(:close).say; # OUTPUT: «␤»
        #]
        # do build stuff to your module
        # which is located at $dist-path
    }
}
