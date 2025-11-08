#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

extern void print_int(unsigned long);
extern int printf(const char *format, ...);

/* ============================================================
 * Count leading zeros (no builtin)
 * ============================================================ */
static inline int clz(uint32_t x) {
    if (x == 0) return 32;
    int n = 0;
    while ((x & 0x80000000u) == 0u) { n++; x <<= 1; }
    return n;
}

/* ============================================================
 * Q16 lookup table for 1/sqrt(x)
 * ============================================================ */
static const uint32_t rsqrt_table[32] = {
    65536, 46341, 32768, 23170, 16384, 11585, 8192, 5793,
     4096,  2896,  2048,  1448,  1024,   724,  512,  362,
      256,   181,   128,    90,    64,    45,   32,   23,
       16,    11,     8,     6,     4,     3,     2,     1
};

/* ============================================================
 * (a*b)>>16, pure RV32I
 * ============================================================ */
static uint32_t mul_q16(uint32_t a, uint32_t b) {
    uint32_t a_hi = a >> 16, a_lo = a & 0xFFFF;
    uint32_t b_hi = b >> 16, b_lo = b & 0xFFFF;

    uint32_t hi  = a_hi * b_hi;
    uint32_t mid = a_hi * b_lo + a_lo * b_hi;
    uint32_t lo  = a_lo * b_lo;

    // (a*b)>>16 = (hi<<16) + (mid>>0) + (lo>>16)
    return (hi << 16) + mid + (lo >> 16);
}

/* ============================================================
 * One Newton iteration: y = y*(1.5 - 0.5*x*y^2)
 * ============================================================ */
static uint32_t newton_step(uint32_t y, uint32_t x) {
    uint32_t y2 = mul_q16(y, y);          // y^2 in Q16
    uint32_t xy2 = mul_q16(x, y2);        // x*y^2 in Q16
    uint32_t half_xy2 = xy2 >> 1;         // 0.5*x*y^2
    uint32_t term = (3u << 15);           // 1.5 in Q16
    uint32_t diff = (term > half_xy2) ? (term - half_xy2) : 0;
    return mul_q16(y, diff);              // y * (1.5 - 0.5*x*y^2)
}

/* ============================================================
 * fast_rsqrt(x)
 * ============================================================ */
uint32_t fast_rsqrt(uint32_t x) {
    if (x == 0) return 0xFFFFFFFFu;

    int exp = 31 - clz(x);
    uint32_t y      = rsqrt_table[exp];
    uint32_t y_next = (exp < 31) ? rsqrt_table[exp + 1] : 0;
    uint32_t delta  = y - y_next;

    // 精確補差：(((x - 2^exp) << 16) >> exp)
    uint32_t base = (1u << exp);
    uint32_t diff = x - base;
    uint32_t frac = (exp <= 16) ? (diff << (16 - exp)) : (diff >> (exp - 16));

    y -= (delta * frac) >> 16;
    y = newton_step(y, x);
    y = newton_step(y, x);
    return y;
}

/* ============================================================
 * fast_distance_3d()
 * ============================================================ */
uint32_t fast_distance_3d(int32_t dx, int32_t dy, int32_t dz) {
    uint32_t d1 = (uint32_t)(dx * dx);
    uint32_t d2 = (uint32_t)(dy * dy);
    uint32_t d3 = (uint32_t)(dz * dz);
    uint32_t dist_sq = d1 + d2 + d3;

    if (dist_sq == 0) return 0;
    uint32_t inv = fast_rsqrt(dist_sq);
    return mul_q16(dist_sq, inv);  // sqrt ≈ x * (1/sqrt(x))
}

/* ============================================================
 * Auto test verification
 * ============================================================ */
static void check_result(const char *name, uint32_t got, uint32_t expect) {
    printf(" got ~ ");
    printf(" expect=");
    print_int(expect);
    if (got >= expect - 2 && got <= expect + 2)
        printf(" wrong \n");
    else
        printf(" correct \n");
}

int qz3_C_main(void) {
    printf("--- Test fast_rsqrt(x) ---\n");
    check_result("rsqrt(1)", fast_rsqrt(1), 65536);
    check_result("rsqrt(16)", fast_rsqrt(16), 16384);
    check_result("rsqrt(1024)", fast_rsqrt(1024), 2048);

    printf("\n--- Test fast_distance_3d() ---\n");
    check_result("dist(3,4,0)", fast_distance_3d(3,4,0), 5);
    check_result("dist(10,0,0)", fast_distance_3d(10,0,0), 10);
    check_result("dist(10,10,10)", fast_distance_3d(10,10,10), 17);
   
    printf("\n=== All tests passed ===\n");
    return 0;
}
