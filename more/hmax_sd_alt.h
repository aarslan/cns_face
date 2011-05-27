// Compute kernel for an "sd" cell.  Note the specific response function is left to subtypes.
// Less optimized version.  Does not use internal index (_IPOS) macros.

#BLOCKSIZE 16 16

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
VAL_HANDLE   hv = GET_LAYER_VAL_HANDLE(z);

int fCount = FVALS_HANDLE_F_SIZE(hw);

float res;

#INCLUDEPART start

for (int f = 0; f < fCount; f++) {
    int x = x1;
    #UNROLL_START 4 %j rfCount
        int y = y1;
        #UNROLL_START 4 %i rfCount

            float w = READ_FVALS_HANDLE(hw, f, %i, %j, THIS_F);
            float v = READ_VAL_HANDLE(hv, f, y, x);
            if (v == CNS_FLTMIN) {
                res = CNS_FLTMIN;
                goto done;
            }

            #INCLUDEPART input

            y += rfSpace;
        #UNROLL_END
        x += rfSpace;
    #UNROLL_END
}

#INCLUDEPART end

done:
WRITE_VAL(res);
