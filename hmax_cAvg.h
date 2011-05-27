// Pooling function for a "cAvg" cell.

#PART start

    res = 0.0f;

    int num = 0;

#PART input

    if (v > CNS_FLTMIN) {
        res += v;
        num++;
    }

#PART end

    if (num == 0) {
        res = CNS_FLTMIN;
    } else {
        res /= (float)num;
    }
