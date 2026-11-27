#ifndef CMCORE_H
#define CMCORE_H

// C interface of the Rust core (rust/cmcore). Everything that returns memory returns it from malloc(): release it with free().

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Text out of Word / PowerPoint / source ZIP files (see OfficeText.h for the error codes).
char *office_docx_text(const unsigned char *zip, size_t zipLen, int *err);
char *office_pptx_text(const unsigned char *zip, size_t zipLen, int *err);
char *office_zip_text(const unsigned char *zip, size_t zipLen, int *err);

// UTF-8 text in, .docx bytes out (malloc'd, size in *outLen). NULL on failure.
uint8_t *cm_docx_build(const uint8_t *text, size_t len, size_t *outLen);

// JavaScript string literal for UTF-8 text, quotes included (malloc'd, NUL-terminated, size in *outLen). NULL: invalid UTF-8.
char *cm_js_string_literal(const uint8_t *text, size_t len, size_t *outLen);

// For a very long instruction text: the parts that fit `budget` UTF-16 units, chosen for `query` (malloc'd, NUL-terminated,
// size in *outLen). NULL: invalid UTF-8.
char *cm_prompt_select(const uint8_t *prompt, size_t promptLen, const uint8_t *query, size_t queryLen, size_t budget, size_t *outLen);

// Server-sent-event framing for the Claude and Gemini streams.
// cm_sse_complete_len: how many bytes at the start of buf are complete lines (everything when isFinal is non-zero).
// cm_sse_for_each_payload: calls cb once per "data:" line with its trimmed payload (valid only during the call);
//                          skipDone non-zero skips the "[DONE]" marker.
typedef void (*cm_payload_cb)(void *ctx, const uint8_t *data, size_t len);
size_t cm_sse_complete_len(const uint8_t *buf, size_t len, int isFinal);
void cm_sse_for_each_payload(const uint8_t *buf, size_t len, int skipDone, cm_payload_cb cb, void *ctx);

#ifdef __cplusplus
}
#endif

#endif
