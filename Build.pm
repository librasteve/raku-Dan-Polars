class Build {
    method build($dist-path) {
        warn 'yo';
        say 'no', $dist-path;
        #say indir( 'dan', {run <cargo build>} );
        chdir 'dan';
        #run 'echo', 'Raku is Great!';
        #`[
        #my $proc = run 'echo', 'Raku is Great!', :out, :err;
        my $proc = run <cargo build>, :out, :err;
        warn $proc.out.slurp; # OUTPUT: «Raku is Great!␤» 
        warn $proc.err.slurp; # OUTPUT: «␤»
        #]
        
        my $proc = Proc::Async.new: run <cargo build>;

        react {
            whenever $proc.stdout.lines { # split input on \r\n, \n, and \r 
                warn ‘line: ’, $_
            }
            whenever $proc.stderr { # chunks 
                warn ‘stderr: ’, $_
            }
            whenever $proc.ready {
                warn ‘PID: ’, $_ # Only in Rakudo 2018.04 and newer, otherwise Nil 
            }
            whenever $proc.start {
                warn ‘Proc finished: exitcode=’, .exitcode, ‘ signal=’, .signal;
                done # gracefully jump from the react block 
            }
            whenever $proc.print: “I\n♥\nCamelia\n” {
                $proc.close-stdin
            }
            whenever signal(SIGTERM).merge: signal(SIGINT) {
                once {
                    say ‘Signal received, asking the process to stop’;
                    $proc.kill; # sends SIGHUP, change appropriately 
                    whenever signal($_).zip: Promise.in(2).Supply {
                        say ‘Kill it!’;
                        $proc.kill: SIGKILL
                    }
                }
            }
        }

        say ‘Program finished’;
        #]
        # do build stuff to your module
        # which is located at $dist-path
    }
}
