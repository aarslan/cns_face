// Response function for an "sdNDP" cell.

#PART start

    float inCount = (float)(fCount * rfCount * rfCount);

    res = 0.0f;

    float sumv  = 0.0f;
    float sumv2 = 0.0f;

    float norm;

#PART input

    res   += w * v;
    sumv  += v;
    sumv2 += v * v;

#PART end

    if (ZERO) {
        norm = sqrtf(sumv2 - sumv * sumv / inCount);
    } else {
        norm = sqrtf(sumv2);
    }

    norm = fmaxf(norm, THRES * sqrtf(inCount));

    if (norm == 0.0f) {
        res = 0.0f;
    } else if (ABS) {
        res = fabsf(res / norm);
    } else {
        res = fmaxf(res / norm, 0.0f);
    }
