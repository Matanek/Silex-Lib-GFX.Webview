#include <stdint.h>

int32_t InterlockedIncrement(volatile int32_t *value) {
    return __atomic_add_fetch(value, 1, __ATOMIC_SEQ_CST);
}

int32_t InterlockedDecrement(volatile int32_t *value) {
    return __atomic_sub_fetch(value, 1, __ATOMIC_SEQ_CST);
}
