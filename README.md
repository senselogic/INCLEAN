![](https://github.com/senselogic/INCLEAN/blob/master/LOGO/inclean.png)

# Inclean

Inclusion directive cleaner.

## Features

* Adds and sorts the needed inclusions.
* Detects the unused inclusions.

## Samples

```c++
#ifndef __TEST_HPP__
    #define __TEST_HPP__
    
    // == LOCAL
    
    // -- IMPORTS

    #include "integer_32.hpp"
    #include "natural_32.hpp"
    #include "real_32.hpp"
    #include "string_8.hpp"
    #include "void.hpp"
    
    // == GLOBAL
    
    // -- TYPES
    
    class TEST
    {
        // == PUBLIC
        
        public :
        
        // -- ATTRIBUTES
        
        INTEGER_32
            Integer;
        NATURAL_32
            Natural;
        REAL_32
            Real;
        STRING_8
            Text;
        VECTOR_3
            XVector,
            YVector,
            ZVector;
        VECTOR_<REAL_32>
            RealVector;
            
        // -- CONTRUCTORS
            
        TEST(
            ) :
            Integer( 0 ),
            Natural( 0 ),
            Real( 0.0f ),
            Text(),
            XVector(),
            YVector(),
            ZVector(),
            RealVector()
        {
        }
        
        // -- DESTRUCTOR
        
        ~TEST(
            )
        {
        }
        
        // -- OPERATIONS
            
        VOID Set(
            const INTEGER_32 integer,
            const NATURAL_32 natural,
            const STRING_8 & text,
            const VECTOR_<REAL_32> & real_vector
            );
    };
#endif
```

```c++
#include "test.hpp"

// == LOCAL

// -- IMPORTS

#include "integer_32.hpp"
#include "natural_32.hpp"
#include "real_32.hpp"
#include "string_8.hpp"
#include "void.hpp"

// == PUBLIC

// -- OPERATIONS

VOID TEST::Set(
    const INTEGER_32 integer,
    const NATURAL_32 natural,
    const STRING_8 & text,
    const VECTOR_<REAL_32> & real_vector
    )
{
    Integer = integer;
    Natural = natural;
    Real = REAL_32_Pi;
    Text = text;
    XVector = VECTOR_3_XAxis;
    YVector = VECTOR_3_YAxis;
    ZVector = VECTOR_3_ZAxis;
    RealVector = real_vector;
}
```

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command line :

```bash
dmd -m64 inclean.d
```

## Command line

```bash
inclean [options] file_path_filter ...
```

### Options

```bash
--use_file_content : use the type names inside the file content
--use_file_name : use the file name as type name
--use_upper_case_file_name : use the upper case file name as type name
--or_file_name : use the file name as type name if no type was found inside the file content
--or_upper_case_file_name : use the upper case file name as type name if no type was found inside the file content
--include "INCLUDE_FOLDER/*.hpp" : include the matching files of this folder using their full path
--include "INCLUDE_FOLDER/!*.hpp" : include the matching files of this folder without their path
--include "INCLUDE_FOLDER//*.hpp" : include the matching files of this folder and its subfolders using their full path
--include "INCLUDE_FOLDER/!/*.hpp" : include the matching files of this folder and its subfolders using their relative path
--include "INCLUDE_FOLDER//!*.hpp" : include the matching files of this folder and its subfolders without their path
--exclude "INCLUDE_FOLDER/*.hpp" : exclude the matching files of this folder
--exclude "INCLUDE_FOLDER//*.hpp" : exclude the matching files of this folder and its subfolders
--comment "// -- IMPORTS" : include the missing header files after this comment
--partial : include the missing header files for partial matches
--missing : add the missing inclusions
--unused : list the unused inclusions
--sort : sort the inclusions
--verbose : show the processing messages
--debug : show the debugging messages
--print : print the processed file content
--preview : preview the changes without applying them
```

### Example

```bash
inclean --use_file_content --or_upper_case_file_name --include "*.hpp" --include "INCLUDE_FOLDER/!/*.hpp" 
        --comment "// -- IMPORTS" --partial --missing --unused --sort --verbose --print --preview "*.hpp" "*.cpp"
```

Includes the missing ".hpp" files of the current folder and the "INCLUDE_FOLDER" folder and its subfolders
after the "// -- IMPORTS" comment in the ".hpp" and ".cpp" files of the current folder.

```bash
inclean --sort --verbose ".//*.hpp" ".//*.cpp"        
```

Sorts the inclusions in the ".hpp" and ".cpp" files of the current folder and its subfolders.

## Limitations

* Only type dependencies are processed.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
