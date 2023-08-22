class Build {
    method build($dist-path) {
        mkdir 'resources';
        mkdir 'resources/dan';
        mkdir 'resources/dan/src';
        move 'dan/Cargo.toml', 'resources/dan/Cargo.toml';
        move 'dan/src/lib.rs', 'resources/dan/src/lib.rs';
        move 'dan/src/apply-template.rs', 'resources/dan/src/apply-template.rs';
        
        warn 'Build successful';
        
        exit 0
    }
}
