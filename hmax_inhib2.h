// Compute kernel for an "inhib2" cell.

#BLOCKSIZE 16 16

float v      = READ_LAYER_VAL(PZS(0), THIS_F, THIS_Y, THIS_X);
float cutoff = READ_LAYER_VAL(PZS(1), 0     , THIS_Y, THIS_X);

float res = (v < cutoff) ? 0.0f : v;

WRITE_VAL(res);
