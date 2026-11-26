#ifndef OFFICE_TEXT_H
#define OFFICE_TEXT_H

#include <stddef.h>
#include "cmcore.h"

// Text extraction for Word (.docx), PowerPoint (.pptx) and source/text ZIP files. The code lives in the Rust core
// (rust/cmcore/src/office_text.rs); the functions are declared in cmcore.h:
//
//   char *office_docx_text(const unsigned char *zip, size_t zipLen, int *err);
//   char *office_pptx_text(const unsigned char *zip, size_t zipLen, int *err);
//   char *office_zip_text(const unsigned char *zip, size_t zipLen, int *err);
//
// They return a malloc'd, NUL-terminated UTF-8 string (caller frees), or NULL on failure with *err set:
enum {
    OFFICE_OK = 0,
    OFFICE_ERR_NOT_ZIP = 1,       // not a ZIP / corrupt archive
    OFFICE_ERR_MISSING_PART = 2,  // the archive does not contain the expected document part
    OFFICE_ERR_UNSUPPORTED = 3,   // encrypted, ZIP64, or an unsupported compression method
    OFFICE_ERR_TOO_LARGE = 4,     // would expand past the safety limit
    OFFICE_ERR_NO_MEMORY = 5
};

#endif
