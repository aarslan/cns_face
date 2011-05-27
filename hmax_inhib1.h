// Compute kernel for an "inhib1" cell.

#BLOCKSIZE 16 16

VAL_HANDLE h = GET_LAYER_VAL_HANDLE(PZS(0));
int fCount = VAL_HANDLE_F_SIZE(h);

int   vCount = 0;
float vMin   = CNS_FLTMAX;
float vMax   = CNS_FLTMIN;

for (int f = 0; f < fCount; f++) {

    float v = READ_VAL_HANDLE(h, f, THIS_Y, THIS_X);

    if (v != CNS_FLTMIN) {
        vCount++;
        vMin = fminf(vMin, v);
        vMax = fmaxf(vMax, v);
    }

}

float res;
if (vCount < 2) {
    res = CNS_FLTMIN;
} else {
    res = vMin + INHIBIT * (vMax - vMin);
}

WRITE_VAL(res);
