class Build {
    method build($dist-path) {
        warn 'yo';
        warn 'no', $dist-path;
        #warn indir( 'dan', {run <cargo build>} );
        warn indir( 'dan', {shell 'cargo build'} );
        # do build stuff to your module
        # which is located at $dist-path
    }
}
