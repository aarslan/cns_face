// Compute kernel for an "n" cell.  Note the specific normalization function is left to subtypes.

#BLOCKSIZE 16 16

LAYER_PTR z = PZS(0);
VAL_HANDLE h = GET_LAYER_VAL_HANDLE(z);

float res = READ_VAL_HANDLE(h, THIS_F, THIS_Y, THIS_X);
if (res == CNS_FLTMIN) {
    WRITE_VAL(CNS_FLTMIN);
    return;
}

int fSize = VAL_HANDLE_F_SIZE(h);

int y1, y2, x1, x2;
FIND_LAYER_Y_NEAREST(z, RFCOUNT, y1, y2);
FIND_LAYER_X_NEAREST(z, RFCOUNT, x1, x2);

float inCount = 0.0f;

#INCLUDEPART start

for (int f = 0 ; f <  fSize; f++) {
for (int x = x1; x <= x2   ; x++) {
for (int y = y1; y <= y2   ; y++) {

    float v = READ_VAL_HANDLE(h, f, y, x);

    if (v > CNS_FLTMIN) {
        inCount++;
        #INCLUDEPART input
    }

}
}
}

#INCLUDEPART end

WRITE_VAL(res);
