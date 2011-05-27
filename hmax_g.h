// Compute kernel for a "g" cell.  Note the specific pooling function is left to subtypes.

#BLOCKSIZE 16 16

// Which scales do we pool over?
int sPos = READ_FSPOS(THIS_F) - 1;
int s1 = max(sPos - STOL, 0          );
int s2 = min(sPos + STOL, NUM_PZS - 1);

// Figure out the RF center and radius in common coordinates.
float ySize = YCOUNT * LAYER_Y_SPACE(PZS(0));
float xSize = XCOUNT * LAYER_X_SPACE(PZS(0));
float yCenter = THIS_Y_CENTER + (READ_FYPOS(THIS_F) - 0.5f) * ySize;
float xCenter = THIS_X_CENTER + (READ_FXPOS(THIS_F) - 0.5f) * xSize;
float yRad = YXTOL * ySize;
float xRad = YXTOL * xSize;

float res;

#INCLUDEPART start

for (int s = s1; s <= s2; s++) {

    LAYER_PTR z = PZS(s);

    // Find all cells within the RF radius of the center at this scale.
    int y1, y2, x1, x2;
    FIND_LAYER_Y_WITHIN_AT(z, yCenter, yRad, y1, y2);
    FIND_LAYER_X_WITHIN_AT(z, xCenter, xRad, x1, x2);

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
