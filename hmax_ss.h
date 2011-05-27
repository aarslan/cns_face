// Compute kernel for an "ss" cell.  Note the specific response function is left to subtypes.

#BLOCKSIZE 16 20

LAYER_PTR z = PZS(0);
int rfCount = READ_FSIZES(THIS_F);
int rfSpace = RFSPACE;
int rfWidth = 1 + (rfCount - 1) * rfSpace;

// Find nearest (rfWidth) input cells in y and x.  If this takes us off an edge, quit.
int y1, x1, dummy;
if (!FIND_LAYER_Y_NEAREST(z, rfWidth, y1, dummy) || !FIND_LAYER_X_NEAREST(z, rfWidth, x1, dummy)) {
    WRITE_VAL(CNS_FLTMIN);
    return;
}

FVALS_HANDLE hw = GET_FVALS_HANDLE;
FMAP2_HANDLE hm = GET_FMAP2_HANDLE;
VAL_HANDLE   hv = GET_LAYER_VAL_HANDLE(z);

int inCount = READ_FMAP2_HANDLE(hm, 0, THIS_F);

float res;

#INCLUDEPART start

for (int i = 0; i < inCount; i++) {

    float w = READ_FVALS_HANDLE(hw, i    , THIS_F);
    int   m = READ_FMAP2_HANDLE(hm, i + 1, THIS_F);

    int f =   m & 0x0000FFFF;
    int y = ((m & 0x00FF0000) >> 16) * rfSpace + y1;
    int x = ((m & 0xFF000000) >> 24) * rfSpace + x1;

    float v = READ_VAL_HANDLE(hv, f, y, x);
    if (v == CNS_FLTMIN) {
        res = CNS_FLTMIN;
        goto done;
    }

    #INCLUDEPART input

}

#INCLUDEPART end

done:
WRITE_VAL(res);
