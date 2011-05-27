// Pooling function for a "gMax" cell.

#PART start

    res = CNS_FLTMIN;

#PART input

    res = fmaxf(res, v);

#PART end
