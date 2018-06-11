#ifndef __COLOR_HPP__
    #define __COLOR_HPP__

    // -- IMPORTS

    #include "natural_8.hpp"

    // -- TYPES

    namespace COLOR
    {
        typedef struct
        {
            // -- ATTRIBUTES

            NATURAL_8
                R,
                G,
                B;
        }
        COLOR_RGB_8;

        // ~~

        typedef struct
        {
            // -- ATTRIBUTES

            NATURAL_8
                R,
                G,
                B,
                A;
        }
        COLOR_RGBA_8;
    }
#endif
