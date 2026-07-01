// Example demonstrating virtual-register library usage

uint32_t x;
uint32_t y;
uint32_t z;

// initialize x with a 32-bit immediate
x = 0x00010203;

// small increment to use 8-bit and 32-bit arithmetic
y = 1;
z = x + y;   // should emit ?add32 when library enabled

// store z back to memory location (illustrative)
result = z;
return z;

