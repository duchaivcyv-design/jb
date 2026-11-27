//! ClaudeMini core: the CPU-heavy pieces that do not touch UIKit, behind a small C ABI.
//! Every function takes UTF-8 bytes and returns a heap buffer that the caller releases with `cm_free`. A null return means
//! "could not do it" (invalid input or an internal error): the Objective-C caller then uses its own implementation.

mod jsstr;
mod prompt;
pub mod office_text;
#[doc(hidden)]
pub fn __js_literal_for_tests(s: &str) -> String {
    jsstr::js_literal(s)
}

#[doc(hidden)]
pub fn __prompt_select_for_tests(p: &str, q: &str, b: usize) -> String {
    prompt::select(p, q, b)
}

use std::panic::catch_unwind;
use std::slice;

fn to_raw(text: String, out_len: *mut usize) -> *mut u8 {
    let boxed: Box<[u8]> = text.into_bytes().into_boxed_slice();
    let len = boxed.len();
    unsafe {
        if !out_len.is_null() {
            *out_len = len;
        }
    }
    Box::into_raw(boxed) as *mut u8
}

unsafe fn text_arg<'a>(ptr: *const u8, len: usize) -> Option<&'a str> {
    if len == 0 {
        return Some("");
    }
    if ptr.is_null() {
        return None;
    }
    std::str::from_utf8(slice::from_raw_parts(ptr, len)).ok()
}

/// JavaScript string literal for `text` (quotes included), ready to be placed in a script.
#[no_mangle]
pub unsafe extern "C" fn cm_js_string_literal(ptr: *const u8, len: usize, out_len: *mut usize) -> *mut u8 {
    let result = catch_unwind(|| {
        let text = text_arg(ptr, len)?;
        Some(jsstr::js_literal(text))
    });
    match result {
        Ok(Some(literal)) => to_raw(literal, out_len),
        _ => std::ptr::null_mut(),
    }
}

/// The part of a long instruction text that fits `budget` UTF-16 units, chosen for `query`.
#[no_mangle]
pub unsafe extern "C" fn cm_prompt_select(
    prompt_ptr: *const u8,
    prompt_len: usize,
    query_ptr: *const u8,
    query_len: usize,
    budget: usize,
    out_len: *mut usize,
) -> *mut u8 {
    let result = catch_unwind(|| {
        let prompt_text = text_arg(prompt_ptr, prompt_len)?;
        let query_text = text_arg(query_ptr, query_len)?;
        Some(prompt::select(prompt_text, query_text, budget))
    });
    match result {
        Ok(Some(selected)) => to_raw(selected, out_len),
        _ => std::ptr::null_mut(),
    }
}

/// Releases a buffer returned by one of the functions above.
#[no_mangle]
pub unsafe extern "C" fn cm_free(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    drop(Box::from_raw(std::ptr::slice_from_raw_parts_mut(ptr, len)));
}

/// Version of the C interface (the Objective-C side checks it matches what it was written for).
#[no_mangle]
pub extern "C" fn cm_core_abi_version() -> u32 {
    1
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn js_literal_round_trip_through_the_c_interface() {
        let text = "a\"b\n\u{2028}";
        let mut n = 0usize;
        unsafe {
            let p = cm_js_string_literal(text.as_ptr(), text.len(), &mut n);
            assert!(!p.is_null());
            let got = std::str::from_utf8(slice::from_raw_parts(p, n)).unwrap().to_string();
            cm_free(p, n);
            assert_eq!(got, "\"a\\\"b\\n\\u2028\"");
        }
    }

    #[test]
    fn invalid_utf8_returns_null() {
        let bad = [0xffu8, 0xfe, 0x41];
        let mut n = 0usize;
        unsafe {
            assert!(cm_js_string_literal(bad.as_ptr(), bad.len(), &mut n).is_null());
        }
    }

    #[test]
    fn empty_input_is_an_empty_literal() {
        let mut n = 7usize;
        unsafe {
            let p = cm_js_string_literal(std::ptr::null(), 0, &mut n);
            assert!(!p.is_null());
            assert_eq!(slice::from_raw_parts(p, n), b"\"\"");
            cm_free(p, n);
        }
    }

    #[test]
    fn prompt_select_through_the_c_interface() {
        let prompt = "first\n".to_string() + &"filler text here\n".repeat(600) + "needle in a haystack\n" + &"more filler\n".repeat(600);
        let query = "needle";
        let mut n = 0usize;
        unsafe {
            let p = cm_prompt_select(prompt.as_ptr(), prompt.len(), query.as_ptr(), query.len(), 13000, &mut n);
            assert!(!p.is_null());
            let got = std::str::from_utf8(slice::from_raw_parts(p, n)).unwrap().to_string();
            cm_free(p, n);
            assert!(got.starts_with("first"));
            assert!(got.contains("needle in a haystack"));
        }
    }
}
