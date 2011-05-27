// Normalization function for an "nLen" cell.

#PART start

    float sumv  = 0.0f;
    float sumv2 = 0.0f;

    float norm;

#PART input

    sumv  += v;
    sumv2 += v * v;

#PART end

    if (ZERO) {
        res -= sumv / inCount;
        norm = sqrtf(sumv2 - sumv * sumv / inCount);
    } else {
        norm = sqrtf(sumv2);
    }

    norm = fmaxf(norm, THRES * sqrtf(inCount));

    if (norm == 0.0f) {
        res = 0.0f;
    } else {
        res /= norm;
    }
