#include "test.hpp"

// -- IMPORTS

#include "void.hpp"
#include "real_32.hpp"
#include "vector_of_.hpp"
#include "string_8.hpp"
#include "natural_32.hpp"
#include "vector.hpp"
#include "integer_32.hpp"
#include "string_8.hpp"

// == PUBLIC

// -- OPERATIONS

VOID TEST::Set(
    const INTEGER_32 integer,
    const NATURAL_32 natural,
    const STRING_8 & text,
    const VECTOR_OF_<REAL_32> & real_vector
    )
{
    Integer = integer;
    Natural = natural;
    Real = REAL_32_Pi;
    Text = text;
    XVector = VECTOR_X;
    YVector = VECTOR_Y;
    ZVector = VECTOR_Z;
    RealVector = real_vector;
}

