// Response function for an "sdConv" cell.

#PART start

    res = 0.0f;

#PART input

    res += w * v;

#PART end

    if (ABS) {
        res = fabsf(res);
    } else {
        res = fmaxf(res, 0.0f);
    }
