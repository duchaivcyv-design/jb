//! ClaudeMini core. Plain C ABI (see src/cmcore.h in the app); no dependencies.
//!
//! - office_docx_text / office_pptx_text / office_zip_text: text out of Word, PowerPoint and source ZIP files
//! - cm_docx_build: plain text in, .docx bytes out
//! - cm_js_string_literal: text in, JavaScript string literal out (every piece of a streaming reply)
//! - cm_prompt_select: which parts of a very long instruction text fit the character budget
//! - cm_sse_complete_len / cm_sse_for_each_payload: SSE framing for the Claude and Gemini streams
//!
//! Every function that returns memory returns it from malloc(), so the caller releases it with free().

mod docx_build;
mod inflate;
mod jsstr;
mod office_text;
mod prompt;
mod sse;

use std::os::raw::{c_char, c_int, c_void};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

extern "C" {
    fn malloc(size: usize) -> *mut c_void;
    #[cfg(test)]
    fn free(p: *mut c_void);
}

/// Copies `bytes` into a malloc'd, NUL-terminated buffer. Null when out of memory.
unsafe fn to_c_string(bytes: &[u8]) -> *mut c_char {
    let p = malloc(bytes.len() + 1) as *mut u8;
    if p.is_null() {
        return ptr::null_mut();
    }
    ptr::copy_nonoverlapping(bytes.as_ptr(), p, bytes.len());
    *p.add(bytes.len()) = 0;
    p as *mut c_char
}

unsafe fn run_office(
    zip: *const u8,
    zip_len: usize,
    err: *mut c_int,
    f: fn(&[u8]) -> Result<Vec<u8>, i32>,
) -> *mut c_char {
    let mut dummy: c_int = 0;
    let errp: *mut c_int = if err.is_null() { &mut dummy } else { err };
    *errp = office_text::OK;
    if zip.is_null() {
        *errp = office_text::ERR_NOT_ZIP;
        return ptr::null_mut();
    }
    let z: &[u8] = std::slice::from_raw_parts(zip, zip_len);
    match catch_unwind(AssertUnwindSafe(|| f(z))) {
        Ok(Ok(text)) => {
            let p = to_c_string(&text);
            if p.is_null() {
                *errp = office_text::ERR_NO_MEMORY;
            }
            p
        }
        Ok(Err(code)) => {
            *errp = code;
            ptr::null_mut()
        }
        Err(_) => {
            *errp = office_text::ERR_NOT_ZIP;
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn office_docx_text(zip: *const u8, zip_len: usize, err: *mut c_int) -> *mut c_char {
    run_office(zip, zip_len, err, office_text::docx_text)
}

#[no_mangle]
pub unsafe extern "C" fn office_pptx_text(zip: *const u8, zip_len: usize, err: *mut c_int) -> *mut c_char {
    run_office(zip, zip_len, err, office_text::pptx_text)
}

#[no_mangle]
pub unsafe extern "C" fn office_zip_text(zip: *const u8, zip_len: usize, err: *mut c_int) -> *mut c_char {
    run_office(zip, zip_len, err, office_text::zip_text)
}

/// Builds a .docx from UTF-8 text. Returns a malloc'd buffer and its size in *out_len, or null on failure.
#[no_mangle]
pub unsafe extern "C" fn cm_docx_build(text: *const u8, len: usize, out_len: *mut usize) -> *mut u8 {
    if out_len.is_null() {
        return ptr::null_mut();
    }
    *out_len = 0;
    let bytes: &[u8] = if text.is_null() || len == 0 { &[] } else { std::slice::from_raw_parts(text, len) };
    match catch_unwind(AssertUnwindSafe(|| docx_build::build(bytes))) {
        Ok(Some(data)) if !data.is_empty() => {
            let p = malloc(data.len()) as *mut u8;
            if p.is_null() {
                return ptr::null_mut();
            }
            ptr::copy_nonoverlapping(data.as_ptr(), p, data.len());
            *out_len = data.len();
            p
        }
        _ => ptr::null_mut(),
    }
}

/// JavaScript string literal for `text` (quotes included). Malloc'd, NUL-terminated; size (without the NUL) in *out_len.
/// Null when the input is not valid UTF-8.
#[no_mangle]
pub unsafe extern "C" fn cm_js_string_literal(text: *const u8, len: usize, out_len: *mut usize) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let bytes: &[u8] = if text.is_null() || len == 0 { &[] } else { std::slice::from_raw_parts(text, len) };
        std::str::from_utf8(bytes).ok().map(jsstr::js_literal)
    }));
    match result {
        Ok(Some(literal)) => {
            if !out_len.is_null() {
                *out_len = literal.len();
            }
            to_c_string(literal.as_bytes())
        }
        _ => ptr::null_mut(),
    }
}

/// The part of a long instruction text that fits `budget` UTF-16 units, chosen for `query`.
/// Malloc'd, NUL-terminated; size (without the NUL) in *out_len. Null when an input is not valid UTF-8.
#[no_mangle]
pub unsafe extern "C" fn cm_prompt_select(
    prompt_ptr: *const u8,
    prompt_len: usize,
    query_ptr: *const u8,
    query_len: usize,
    budget: usize,
    out_len: *mut usize,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let p: &[u8] = if prompt_ptr.is_null() || prompt_len == 0 { &[] } else { std::slice::from_raw_parts(prompt_ptr, prompt_len) };
        let q: &[u8] = if query_ptr.is_null() || query_len == 0 { &[] } else { std::slice::from_raw_parts(query_ptr, query_len) };
        match (std::str::from_utf8(p), std::str::from_utf8(q)) {
            (Ok(prompt_text), Ok(query_text)) => Some(prompt::select(prompt_text, query_text, budget)),
            _ => None,
        }
    }));
    match result {
        Ok(Some(selected)) => {
            if !out_len.is_null() {
                *out_len = selected.len();
            }
            to_c_string(selected.as_bytes())
        }
        _ => ptr::null_mut(),
    }
}

#[doc(hidden)]
pub fn __js_literal_for_tests(s: &str) -> String {
    jsstr::js_literal(s)
}

#[doc(hidden)]
pub fn __prompt_select_for_tests(p: &str, q: &str, b: usize) -> String {
    prompt::select(p, q, b)
}

pub type CmPayloadCb = extern "C" fn(ctx: *mut c_void, data: *const u8, len: usize);

/// How many bytes at the start of `buf` are ready to be framed: all complete lines, or everything when `is_final`.
#[no_mangle]
pub unsafe extern "C" fn cm_sse_complete_len(buf: *const u8, len: usize, is_final: c_int) -> usize {
    if buf.is_null() || len == 0 {
        return 0;
    }
    sse::complete_len(std::slice::from_raw_parts(buf, len), is_final != 0)
}

/// Calls `cb` once per "data:" line in `buf` with its trimmed payload (valid only during the call).
/// With `skip_done` != 0 the "[DONE]" marker is skipped.
#[no_mangle]
pub unsafe extern "C" fn cm_sse_for_each_payload(
    buf: *const u8,
    len: usize,
    skip_done: c_int,
    cb: Option<CmPayloadCb>,
    ctx: *mut c_void,
) {
    let cb = match cb {
        Some(cb) => cb,
        None => return,
    };
    if buf.is_null() || len == 0 {
        return;
    }
    let bytes = std::slice::from_raw_parts(buf, len);
    sse::for_each_payload(bytes, skip_done != 0, |p| cb(ctx, p.as_ptr(), p.len()));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn inflate_hello() {
        // raw DEFLATE of "hello" (a zlib stream without its 2-byte header and Adler-32 trailer)
        let data = [0xcb, 0x48, 0xcd, 0xc9, 0xc9, 0x07, 0x00];
        assert_eq!(inflate::inflate_raw(&data, 5).unwrap(), b"hello");
        assert!(inflate::inflate_raw(&data, 4).is_none());
        assert!(inflate::inflate_raw(&data, 6).is_none());
    }

    #[test]
    fn docx_round_trip() {
        let text = "Xin chào\nline <2> & \"more\"\n\n\nend";
        let zip = docx_build::build(text.as_bytes()).unwrap();
        let back = office_text::docx_text(&zip).unwrap();
        assert_eq!(String::from_utf8(back).unwrap(), "Xin chào\nline <2> & \"more\"\n\nend");
    }

    #[test]
    fn not_a_zip() {
        assert_eq!(office_text::docx_text(b"hello world, this is not a zip file").unwrap_err(), office_text::ERR_NOT_ZIP);
        assert_eq!(office_text::pptx_text(b"short").unwrap_err(), office_text::ERR_NOT_ZIP);
    }

    #[test]
    fn zip_text_reads_stored_entries() {
        // the .docx we build holds three stored XML parts: all of them are text entries
        let zip = docx_build::build(b"abc").unwrap();
        let text = office_text::zip_text(&zip).unwrap();
        let s = String::from_utf8(text).unwrap();
        assert!(s.contains("===== word/document.xml ====="));
    }

    #[test]
    fn js_literal_through_the_c_interface() {
        let text = "a\"b\n\u{2028}";
        let mut n = 0usize;
        unsafe {
            let p = cm_js_string_literal(text.as_ptr(), text.len(), &mut n);
            assert!(!p.is_null());
            let got = std::slice::from_raw_parts(p as *const u8, n).to_vec();
            free(p as *mut c_void);
            assert_eq!(String::from_utf8(got).unwrap(), "\"a\\\"b\\n\\u2028\"");
            let bad = [0xffu8, 0x41];
            assert!(cm_js_string_literal(bad.as_ptr(), bad.len(), &mut n).is_null());
        }
    }

    #[test]
    fn sse_payloads() {
        let buf = b"event: x\r\ndata: {\"a\":1}\r\n\r\ndata:[DONE]\ndata:   \ndata: {\"b\":2}";
        assert_eq!(sse::complete_len(buf, false), buf.len() - "data: {\"b\":2}".len());
        assert_eq!(sse::complete_len(buf, true), buf.len());
        let mut got: Vec<Vec<u8>> = Vec::new();
        sse::for_each_payload(buf, true, |p| got.push(p.to_vec()));
        assert_eq!(got, vec![b"{\"a\":1}".to_vec(), b"{\"b\":2}".to_vec()]);
        let mut all = 0;
        sse::for_each_payload(buf, false, |_| all += 1);
        assert_eq!(all, 3);
    }
}
