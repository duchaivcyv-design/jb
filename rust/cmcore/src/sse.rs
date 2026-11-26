//! Server-sent-event framing for the Claude and Gemini streams.
//! The network delivers arbitrary byte chunks; complete lines are cut out here and only the JSON payload of
//! "data:" lines is handed back, so the app never builds a string per line.

/// Bytes that form complete lines at the start of `buf` (everything up to and including the last '\n'),
/// or all of it when the stream has ended.
pub fn complete_len(buf: &[u8], is_final: bool) -> usize {
    if buf.is_empty() {
        return 0;
    }
    if is_final {
        return buf.len();
    }
    match buf.iter().rposition(|&c| c == b'\n') {
        Some(p) => p + 1,
        None => 0,
    }
}

fn is_blank(c: u8) -> bool {
    c == b' ' || c == b'\t' || c == b'\r'
}

/// The payload of one line: Some(bytes after "data:", trimmed) for a data line with content, None otherwise.
pub fn payload(line: &[u8]) -> Option<&[u8]> {
    let mut start = 0;
    let mut end = line.len();
    while start < end && line[start] == b'\r' {
        start += 1;
    }
    while end > start && line[end - 1] == b'\r' {
        end -= 1;
    }
    let l = &line[start..end];
    if !l.starts_with(b"data:") {
        return None;
    }
    let mut s = 5;
    let mut e = l.len();
    while s < e && is_blank(l[s]) {
        s += 1;
    }
    while e > s && is_blank(l[e - 1]) {
        e -= 1;
    }
    if s == e {
        None
    } else {
        Some(&l[s..e])
    }
}

/// Calls `f` with the payload of every data line in `buf` (a trailing segment without '\n' counts as a line).
pub fn for_each_payload<F: FnMut(&[u8])>(buf: &[u8], skip_done: bool, mut f: F) {
    for line in buf.split(|&c| c == b'\n') {
        if let Some(p) = payload(line) {
            if skip_done && p == b"[DONE]" {
                continue;
            }
            f(p);
        }
    }
}
