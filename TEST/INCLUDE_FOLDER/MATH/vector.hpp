#ifndef __VECTOR_HPP__
    #define __VECTOR_HPP__

    // -- IMPORTS

    #include "real_32.hpp"

    // -- TYPES

    namespace VECTOR
    {
        class VECTOR_2
        {
            // == PUBLIC

            public :

            // -- TYPES

            class VECTOR_2_X
            {
            }

            // -- ATTRIBUTES

            REAL_32
                X,
                Y;
        }

        // ~~

        struct VECTOR_3
        {
            // -- ATTRIBUTES

            REAL_32
                X,
                Y,
                Z;
        }

        // ~~

        union VECTOR_4
        {
            // -- ATTRIBUTES

            REAL_32
                X,
                Y,
                Z,
                W;
        }
    }
#endif
