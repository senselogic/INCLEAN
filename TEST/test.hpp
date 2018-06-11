#ifndef __TEST_HPP__
    #define __TEST_HPP__

    // -- IMPORTS

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
