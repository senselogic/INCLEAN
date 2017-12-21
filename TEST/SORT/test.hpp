#ifndef __TEST_HPP
    #define __TEST_HPP__
    
    // == LOCAL
    
    // -- IMPORTS

    #include "string_8.hpp"
    #include "vector.hpp"
    #include "void.hpp"
    #include "real_32.hpp"
    #include "integer_32.hpp"
    #include "vector_of_.hpp"
    #include "natural_32.hpp"
    #include "real_32.hpp"
    
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
        VECTOR
            XVector,
            YVector,
            ZVector;
        VECTOR_OF_<REAL_32>
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
            const VECTOR_OF_<REAL_32> & real_vector
            );
    };
#endif
