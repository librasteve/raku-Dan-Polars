use NativeCall; 

constant $n-path = '../../dan/target/debug/dan';

sub add (int32, int32) returns int32 is native($n-path) { * };  
say add(1, 2); 

sub str2rust(Str is encoded('utf8')) is native($n-path) {*};
str2rust("hey");

sub str2raku() returns Pointer[Str] is native($n-path) {*};
say str2raku.deref;

sub df_read_csv(Str is encoded('utf8')) is native($n-path) {*};
df_read_csv("../../dan/src/iris.csv");


## Rust FFI Omnibus: Integers
## http://jakegoulding.com/rust-ffi-omnibus/integers/

sub addition(int32, int32) returns int32 is native($n-path) { * }

say addition(1, 2);

## Rust FFI Omnibus: String Arguments
## http://jakegoulding.com/rust-ffi-omnibus/string-arguments/

sub how_many_characters(Str is encoded('utf8')) returns int32 is native($n-path) { * }

say how_many_characters("göes to élevên");

## Rust FFI Omnibus: String Return Values
## http://jakegoulding.com/rust-ffi-omnibus/string-return-values/

sub theme_song_generate(uint8) returns Pointer[Str] is encoded('utf8') is native($n-path) { * }
sub theme_song_free(Pointer[Str]) is native($n-path) { * }

my \song = theme_song_generate(5);
say song.deref;
theme_song_free(song);

## Rust FFI Omnibus: Slice Arguments
## http://jakegoulding.com/rust-ffi-omnibus/slice-arguments/

sub sum_of_even(CArray[uint32], size_t) returns uint32 is native($n-path) { * }

my @numbers := CArray[uint32].new;
@numbers[$++] = $_ for 1..6;

say sum_of_even( @numbers, @numbers.elems );

class ZipCodeDatabase is repr('CPointer') {
    sub zip_code_database_new() returns ZipCodeDatabase is native($n-path) { * }
    sub zip_code_database_free(ZipCodeDatabase)         is native($n-path) { * }
    sub zip_code_database_populate(ZipCodeDatabase)     is native($n-path) { * }
    sub zip_code_database_population_of(ZipCodeDatabase, Str is encoded('utf8')) 
                                         returns uint32 is native($n-path) { * }

    method new { 
        zip_code_database_new 
    }

    submethod DESTROY {        # Free data when the object is garbage collected.
        zip_code_database_free(self);
    }

    method populate { 
        zip_code_database_populate(self) 
    }

    method population_of( Str \zip ) {
        zip_code_database_population_of(self, zip);
    }
}

my \database = ZipCodeDatabase.new;
    database.populate;

my \pop1 = database.population_of('90210');
my \pop2 = database.population_of('20500');
say pop1 - pop2;



