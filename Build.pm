class Build {
    method build($dist-path) {
        warn 'yo';
        say 'no', $dist-path;
        #say indir( 'dan', {run <cargo build>} );
        #run 'echo', 'Raku is Great!';
        #[
        chdir: 'dan';
        #my $proc = run 'echo', 'Raku is Great!', :out, :err;
        my $proc = run <cargo build>, :out, :err;
        warn $proc.out.slurp(:close); # OUTPUT: «Raku is Great!␤» 
        warn $proc.err.slurp(:close); # OUTPUT: «␤»
        #]
        # do build stuff to your module
        # which is located at $dist-path
    }
}
