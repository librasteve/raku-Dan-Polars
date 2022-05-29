use NativeCall; 

constant $n-path = '../../dan/target/debug/dan';

sub str2rust(Str is encoded('utf8')) is native($n-path) {*};
str2rust("hey");

sub str2raku() returns Pointer[Str] is native($n-path) {*};
say str2raku.deref;

sub df_read_csv(Str is encoded('utf8')) is native($n-path) {*};
df_read_csv("../../dan/src/iris.csv");

#`[
sub df_ret_csv(Str is encoded('utf8')) returns Pointer is native($n-path) {*};
my $dfp = df_ret_csv("./dan/src/iris.csv");
dd $dfp;

sub df_head(Pointer) is native($n-path) {*};
df_head($dfp);
#]

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


sub add (int32, int32) returns int32 is native($n-path) { * };  
say add(1, 2); 

