use NativeCall; 

constant $n-path = '../../dan/target/debug/dan';

class Series is repr('CPointer') {
    sub se_new() returns Series  is native($n-path) { * }
    sub se_free(Series)          is native($n-path) { * }
    sub se_say(Series)           is native($n-path) { * }

    method new { 
        se_new 
    }

    submethod DESTROY { #Free data when the object is garbage collected.
        se_free(self);
    }

    method say { 
        se_say(self) 
    }
}

dd my \se = Series.new;
se.say;


class DataFrame is repr('CPointer') {
    sub df_new() returns DataFrame  is native($n-path) { * }
    sub df_free(DataFrame)          is native($n-path) { * }
    sub df_read_csv(DataFrame, Str) is native($n-path) { * }
    sub df_head(DataFrame)          is native($n-path) { * }
    #sub df_columns(DataFrame) returns Series is native($n-path) { * }
#iamerejh - do do eg columns need to make empty Series and then pass in to df.columns as the "put it here ptr"

    method new { 
        df_new 
    }

    submethod DESTROY { #Free data when the object is garbage collected.
        df_free(self);
    }

    method read_csv( Str \path ) {
        df_read_csv(self, path);
    }

    method head { 
        df_head(self) 
    }
}

dd my \df = DataFrame.new;
df.read_csv("../../dan/src/iris.csv");
df.head;

#-----------------------------------------------------------------------------

## Rust FFI Omnibus: Integers
sub addition(int32, int32) returns int32 is native($n-path) { * }
say addition(1, 2);

## Rust FFI Omnibus: String Return Values
sub theme_song_generate(uint8) returns Pointer[Str] is encoded('utf8') is native($n-path) { * }
sub theme_song_free(Pointer[Str]) is native($n-path) { * }

my \song = theme_song_generate(5);
say song.deref;
theme_song_free(song);

## Rust FFI Omnibus: Slice Arguments
sub sum_of_even(CArray[uint32], size_t) returns uint32 is native($n-path) { * }

my @numbers := CArray[uint32].new;
@numbers[$++] = $_ for 1..6;

say sum_of_even( @numbers, @numbers.elems );

