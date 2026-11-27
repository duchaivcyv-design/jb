#ifndef CLAUDEMINI_CORE_H
#define CLAUDEMINI_CORE_H
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// All functions take UTF-8 bytes. A returned buffer must be released with cm_free(ptr, length).
// NULL means "could not do it": the caller falls back to its own implementation.

uint32_t cm_core_abi_version(void);

// JavaScript string literal for the text, quotes included.
uint8_t *cm_js_string_literal(const uint8_t *text, size_t text_len, size_t *out_len);

// The part of a long instruction text that fits `budget` UTF-16 units, chosen for `query`.
uint8_t *cm_prompt_select(const uint8_t *prompt, size_t prompt_len,
                          const uint8_t *query, size_t query_len,
                          size_t budget, size_t *out_len);

void cm_free(uint8_t *ptr, size_t len);

#ifdef __cplusplus
}
#endif
#endif
