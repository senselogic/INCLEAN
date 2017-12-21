#include "test.hpp"

// == LOCAL

// -- IMPORTS

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
