// Compute kernel for a "c" cell.  Note the specific pooling function is left to subtypes.

#BLOCKSIZE 16 16

// Figure out the RF radius in common coordinates.
float yRad = LAYER_Y_SPACE(PZS(0)) * 0.5f * YCOUNT;
float xRad = LAYER_X_SPACE(PZS(0)) * 0.5f * XCOUNT;

float res;

#INCLUDEPART start

for (int s = 0; s < NUM_PZS; s++) {

    LAYER_PTR z = PZS(s);

    // Find all cells within the RF radius at this scale.
    int y1, y2, x1, x2;
    FIND_LAYER_Y_WITHIN(z, yRad, y1, y2);
    FIND_LAYER_X_WITHIN(z, xRad, x1, x2);

    VAL_HANDLE h = GET_LAYER_VAL_HANDLE(z);

    for (int x = x1; x <= x2; x++) {
    for (int y = y1; y <= y2; y++) {

        float v = READ_VAL_HANDLE(h, THIS_F, y, x);

        #INCLUDEPART input

    }
    }

}

#INCLUDEPART end

WRITE_VAL(res);
