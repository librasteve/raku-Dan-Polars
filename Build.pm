class Build {
    method build($dist-path) {
        warn 'yo';
        die 'no', $dist-path;
        # do build stuff to your module
        # which is located at $dist-path
    }
}
