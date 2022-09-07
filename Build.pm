class Build {
    method build($dist-path) {
        warn 'yo';
        die 'no', $dist-path;
        indir( 'dan', {run <cargo build>} );
        # do build stuff to your module
        # which is located at $dist-path
    }
}
