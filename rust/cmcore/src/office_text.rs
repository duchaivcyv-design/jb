//! Text extraction for Word (.docx), PowerPoint (.pptx) and general text/source ZIP archives.
//! A direct port of the former OfficeText.c: same limits, same output, same error codes.
//! Both Office formats are ZIP archives of XML, so the archive is read in memory (central directory first).

use crate::inflate;

pub const OK: i32 = 0;
pub const ERR_NOT_ZIP: i32 = 1;
pub const ERR_MISSING_PART: i32 = 2;
pub const ERR_UNSUPPORTED: i32 = 3;
pub const ERR_TOO_LARGE: i32 = 4;
#[allow(dead_code)]
pub const ERR_NO_MEMORY: i32 = 5;

const MAX_PART_BYTES: u32 = 40 * 1024 * 1024; // largest uncompressed XML part we will inflate
const MAX_TEXT_BYTES: usize = 4 * 1024 * 1024; // largest amount of extracted text we keep (Word / PowerPoint)
// Source/text ZIP files: a big archive of code is read in full (up to this much text, in line with the 50 million characters
// the app stores for one text attachment) and each file may be large; archives with up to 60000 entries are accepted.
const MAX_ZIP_TEXT_BYTES: usize = 48 * 1024 * 1024;
const MAX_ZIP_ENTRY_BYTES: usize = 16 * 1024 * 1024;
const MAX_ZIP_ENTRIES: u32 = 60000;
const MAX_SLIDES: usize = 1000;
const MAX_RELS: usize = 4096;

fn rd16(p: &[u8], i: usize) -> u16 {
    (p[i] as u16) | ((p[i + 1] as u16) << 8)
}

fn rd32(p: &[u8], i: usize) -> u32 {
    (p[i] as u32) | ((p[i + 1] as u32) << 8) | ((p[i + 2] as u32) << 16) | ((p[i + 3] as u32) << 24)
}

fn eq(a: &[u8], b: &str) -> bool {
    a == b.as_bytes()
}

fn contains(hay: &[u8], needle: &[u8]) -> bool {
    if needle.is_empty() || needle.len() > hay.len() {
        return false;
    }
    hay.windows(needle.len()).any(|w| w == needle)
}

// ------------------------------------------------------------------------------------------------
// Minimal ZIP reader
// ------------------------------------------------------------------------------------------------

#[derive(Clone, Copy)]
struct ZipEntry {
    method: u16,
    csize: u32,
    size: u32,
    lho: u32, // local header offset
}

/// The end-of-central-directory record sits at the very end, optionally followed by a comment (<= 65535 bytes).
fn find_eocd(z: &[u8]) -> Option<usize> {
    let n = z.len();
    if n < 22 {
        return None;
    }
    let min_pos = if n - 22 > 65535 { n - 22 - 65535 } else { 0 };
    let mut i = n - 22;
    loop {
        if rd32(z, i) == 0x0605_4b50 {
            return Some(i);
        }
        if i == min_pos {
            return None;
        }
        i -= 1;
    }
}

fn find_entry(z: &[u8], name: &[u8]) -> Result<ZipEntry, i32> {
    let n = z.len();
    if n < 22 {
        return Err(ERR_NOT_ZIP);
    }
    let eocd = find_eocd(z).ok_or(ERR_NOT_ZIP)?;
    let total = rd16(z, eocd + 10) as u32;
    let cd_size = rd32(z, eocd + 12);
    let cd_off = rd32(z, eocd + 16);
    if total == 0xFFFF || cd_size == 0xFFFF_FFFF || cd_off == 0xFFFF_FFFF {
        return Err(ERR_UNSUPPORTED); // ZIP64
    }
    if cd_off as u64 + cd_size as u64 > n as u64 {
        return Err(ERR_NOT_ZIP);
    }
    let mut p = cd_off as usize;
    let end = p + cd_size as usize;
    for _ in 0..total {
        if end - p < 46 || rd32(z, p) != 0x0201_4b50 {
            return Err(ERR_NOT_ZIP);
        }
        let flags = rd16(z, p + 8);
        let method = rd16(z, p + 10);
        let csize = rd32(z, p + 20);
        let size = rd32(z, p + 24);
        let nl = rd16(z, p + 28) as usize;
        let el = rd16(z, p + 30) as usize;
        let cl = rd16(z, p + 32) as usize;
        let lho = rd32(z, p + 42);
        if end - p < 46 + nl + el + cl {
            return Err(ERR_NOT_ZIP);
        }
        if nl == name.len() && &z[p + 46..p + 46 + nl] == name {
            if flags & 1 != 0 {
                return Err(ERR_UNSUPPORTED); // encrypted
            }
            if csize == 0xFFFF_FFFF || size == 0xFFFF_FFFF || lho == 0xFFFF_FFFF {
                return Err(ERR_UNSUPPORTED);
            }
            return Ok(ZipEntry { method, csize, size, lho });
        }
        p += 46 + nl + el + cl;
    }
    Err(ERR_MISSING_PART)
}

fn read_entry(z: &[u8], e: &ZipEntry) -> Result<Vec<u8>, i32> {
    if e.size > MAX_PART_BYTES {
        return Err(ERR_TOO_LARGE);
    }
    let n = z.len();
    let lho = e.lho as usize;
    if lho as u64 + 30 > n as u64 || rd32(z, lho) != 0x0403_4b50 {
        return Err(ERR_NOT_ZIP);
    }
    let nl = rd16(z, lho + 26) as u64;
    let el = rd16(z, lho + 28) as u64;
    let data_start = lho as u64 + 30 + nl + el;
    if data_start + e.csize as u64 > n as u64 {
        return Err(ERR_NOT_ZIP);
    }
    let ds = data_start as usize;
    let src = &z[ds..ds + e.csize as usize];
    if e.size == 0 {
        return Ok(Vec::new());
    }
    match e.method {
        0 => {
            if e.csize != e.size {
                return Err(ERR_NOT_ZIP);
            }
            Ok(src.to_vec())
        }
        8 => inflate::inflate_raw(src, e.size as usize).ok_or(ERR_NOT_ZIP),
        _ => Err(ERR_UNSUPPORTED),
    }
}

fn load_part(z: &[u8], name: &str) -> Result<Vec<u8>, i32> {
    let e = find_entry(z, name.as_bytes())?;
    read_entry(z, &e)
}

// ------------------------------------------------------------------------------------------------
// Growing text buffer with a hard size limit
// ------------------------------------------------------------------------------------------------

struct Sb {
    buf: Vec<u8>,
    overflow: bool, // hit MAX_TEXT_BYTES: further text is dropped
    limit: usize,
}

impl Sb {
    fn new() -> Sb {
        Sb { buf: Vec::new(), overflow: false, limit: MAX_TEXT_BYTES }
    }

    fn with_limit(limit: usize) -> Sb {
        Sb { buf: Vec::new(), overflow: false, limit }
    }

    fn put(&mut self, s: &[u8]) {
        if self.overflow || s.is_empty() {
            return;
        }
        if self.buf.len() + s.len() > self.limit {
            self.overflow = true;
            return;
        }
        self.buf.extend_from_slice(s);
    }

    fn putc(&mut self, c: u8) {
        self.put(&[c]);
    }

    /// Removes `suffix` from the end of the buffer if it is there.
    fn trim_suffix(&mut self, suffix: &[u8]) {
        if self.buf.len() >= suffix.len() && &self.buf[self.buf.len() - suffix.len()..] == suffix {
            let new_len = self.buf.len() - suffix.len();
            self.buf.truncate(new_len);
        }
    }
}

fn utf8_encode(cp: u32) -> ([u8; 4], usize) {
    let mut out = [0u8; 4];
    if cp == 0 || (0xD800..=0xDFFF).contains(&cp) || cp > 0x10FFFF {
        return (out, 0);
    }
    if cp < 0x20 && cp != 9 && cp != 10 && cp != 13 {
        return (out, 0);
    }
    if cp < 0x80 {
        out[0] = cp as u8;
        return (out, 1);
    }
    if cp < 0x800 {
        out[0] = 0xC0 | (cp >> 6) as u8;
        out[1] = 0x80 | (cp & 0x3F) as u8;
        return (out, 2);
    }
    if cp < 0x10000 {
        out[0] = 0xE0 | (cp >> 12) as u8;
        out[1] = 0x80 | ((cp >> 6) & 0x3F) as u8;
        out[2] = 0x80 | (cp & 0x3F) as u8;
        return (out, 3);
    }
    out[0] = 0xF0 | (cp >> 18) as u8;
    out[1] = 0x80 | ((cp >> 12) & 0x3F) as u8;
    out[2] = 0x80 | ((cp >> 6) & 0x3F) as u8;
    out[3] = 0x80 | (cp & 0x3F) as u8;
    (out, 4)
}

/// Appends XML character data, decoding the five named entities and numeric references.
fn put_decoded(b: &mut Sb, s: &[u8]) {
    let n = s.len();
    let mut i = 0;
    while i < n {
        if s[i] != b'&' {
            let mut j = i;
            while j < n && s[j] != b'&' {
                j += 1;
            }
            b.put(&s[i..j]);
            i = j;
            continue;
        }
        // entity: look for ';' within a short distance
        let mut j = i + 1;
        while j < n && j - i <= 10 && s[j] != b';' {
            j += 1;
        }
        if j >= n || s[j] != b';' {
            b.putc(b'&');
            i += 1;
            continue;
        }
        let elen = j - i - 1;
        let e = &s[i + 1..j];
        if eq(e, "amp") {
            b.putc(b'&');
        } else if eq(e, "lt") {
            b.putc(b'<');
        } else if eq(e, "gt") {
            b.putc(b'>');
        } else if eq(e, "quot") {
            b.putc(b'"');
        } else if eq(e, "apos") {
            b.putc(b'\'');
        } else if elen >= 2 && e[0] == b'#' {
            let mut cp: u32 = 0;
            let mut ok = true;
            if e[1] == b'x' || e[1] == b'X' {
                if elen < 3 {
                    ok = false;
                }
                for k in 2..elen {
                    if !ok {
                        break;
                    }
                    let c = e[k];
                    let d = match c {
                        b'0'..=b'9' => (c - b'0') as u32,
                        b'a'..=b'f' => (c - b'a') as u32 + 10,
                        b'A'..=b'F' => (c - b'A') as u32 + 10,
                        _ => {
                            ok = false;
                            break;
                        }
                    };
                    cp = cp * 16 + d;
                    if cp > 0x10FFFF {
                        ok = false;
                    }
                }
            } else {
                for k in 1..elen {
                    if !ok {
                        break;
                    }
                    let c = e[k];
                    if !c.is_ascii_digit() {
                        ok = false;
                        break;
                    }
                    cp = cp * 10 + (c - b'0') as u32;
                    if cp > 0x10FFFF {
                        ok = false;
                    }
                }
            }
            if ok {
                let (buf, m) = utf8_encode(cp);
                if m > 0 {
                    b.put(&buf[..m]);
                }
            }
        } else {
            // unknown entity: keep it readable
            b.put(&s[i..=j]);
        }
        i = j + 1;
    }
}

// ------------------------------------------------------------------------------------------------
// Tiny XML helpers (the Office XML we read is machine-generated and well formed)
// ------------------------------------------------------------------------------------------------

/// Index of the next '>' at or after `from`, or len if none.
fn tag_end(x: &[u8], from: usize) -> usize {
    match x[from..].iter().position(|&c| c == b'>') {
        Some(p) => from + p,
        None => x.len(),
    }
}

/// Index of the next occurrence of `close` (e.g. "</w:t>") at or after `from`, or len if none.
fn find_close(x: &[u8], from: usize, close: &[u8]) -> usize {
    let len = x.len();
    let mut from = from;
    while from < len {
        match x[from..].iter().position(|&c| c == b'<') {
            None => return len,
            Some(p) => {
                let at = from + p;
                if len - at >= close.len() && &x[at..at + close.len()] == close {
                    return at;
                }
                from = at + 1;
            }
        }
    }
    len
}

/// Value of attribute `attr` inside the tag text, or None.
fn attr_value<'a>(tag: &'a [u8], attr: &str) -> Option<&'a [u8]> {
    let attr = attr.as_bytes();
    let al = attr.len();
    let tl = tag.len();
    let mut i = 1;
    while i + al + 2 < tl {
        let before = tag[i - 1];
        if before == b' ' || before == b'\t' || before == b'\n' || before == b'\r' {
            if &tag[i..i + al] == attr && tag[i + al] == b'=' {
                let quote = tag[i + al + 1];
                if quote == b'"' || quote == b'\'' {
                    let vstart = i + al + 2;
                    return match tag[vstart..].iter().position(|&c| c == quote) {
                        Some(p) => Some(&tag[vstart..vstart + p]),
                        None => None,
                    };
                }
            }
        }
        i += 1;
    }
    None
}

struct Tag {
    name_start: usize,
    name_len: usize,
    closing: bool,
    self_closing: bool,
    end: usize, // index of its '>'
}

/// Reads a tag starting at x[i] == '<'.
fn read_tag(x: &[u8], i: usize) -> Option<Tag> {
    let len = x.len();
    let mut j = i + 1;
    if j >= len {
        return None;
    }
    let mut closing = false;
    if x[j] == b'/' {
        closing = true;
        j += 1;
    }
    let s = j;
    while j < len && !matches!(x[j], b'>' | b'/' | b' ' | b'\t' | b'\n' | b'\r') {
        j += 1;
    }
    let k = tag_end(x, j);
    if k >= len {
        return None;
    }
    Some(Tag { name_start: s, name_len: j - s, closing, self_closing: k > 0 && x[k - 1] == b'/', end: k })
}

/// Next '<' at or after `i`.
fn next_lt(x: &[u8], i: usize) -> Option<usize> {
    x[i..].iter().position(|&c| c == b'<').map(|p| i + p)
}

/// Collapses runs of 3+ newlines to 2, strips trailing spaces on lines and trims both ends.
fn tidy(src: &[u8]) -> Vec<u8> {
    let mut w: Vec<u8> = Vec::with_capacity(src.len());
    let mut newlines = 0;
    for &c in src {
        if c == b'\r' {
            continue;
        }
        if c == b'\n' {
            while matches!(w.last(), Some(&b' ') | Some(&b'\t')) {
                w.pop();
            }
            newlines += 1;
            if newlines <= 2 {
                w.push(b'\n');
            }
            continue;
        }
        newlines = 0;
        w.push(c);
    }
    while matches!(w.last(), Some(&b'\n') | Some(&b' ') | Some(&b'\t')) {
        w.pop();
    }
    let start = w.iter().position(|&c| !matches!(c, b'\n' | b' ' | b'\t')).unwrap_or(w.len());
    if start > 0 {
        w.drain(..start);   // in place: a second copy of a very large text would double the memory use
    }
    // The text goes back to C as a NUL-terminated string: stop at the first NUL like the old code did.
    if let Some(p) = w.iter().position(|&c| c == 0) {
        w.truncate(p);
    }
    w
}

// ------------------------------------------------------------------------------------------------
// Word: text lives in <w:t>; <w:p> ends a paragraph, <w:tab/>, <w:br/> and table cells add separators
// ------------------------------------------------------------------------------------------------

fn extract_docx_xml(x: &[u8], out: &mut Sb) {
    let len = x.len();
    let mut i = 0;
    let mut cell_depth = 0i32; // > 0 while inside a table cell: a table row must stay on one line
    while i < len {
        i = match next_lt(x, i) {
            Some(p) => p,
            None => break,
        };
        let t = match read_tag(x, i) {
            Some(t) => t,
            None => break,
        };
        let name = &x[t.name_start..t.name_start + t.name_len];
        if !t.closing {
            if eq(name, "w:t") && !t.self_closing {
                let close = find_close(x, t.end + 1, b"</w:t>");
                put_decoded(out, &x[t.end + 1..close]);
                i = if close < len { close + 6 } else { len };
                continue;
            } else if eq(name, "w:tab") {
                out.putc(b'\t');
            } else if eq(name, "w:br") || eq(name, "w:cr") {
                out.putc(if cell_depth > 0 { b' ' } else { b'\n' });
            } else if eq(name, "w:tc") && !t.self_closing {
                cell_depth += 1;
            }
        } else if eq(name, "w:p") {
            out.putc(if cell_depth > 0 { b' ' } else { b'\n' });
        } else if eq(name, "w:tc") {
            if cell_depth > 0 {
                cell_depth -= 1;
            }
            out.trim_suffix(b" "); // the cell's last paragraph already added a space
            out.put(b" | ");
        } else if eq(name, "w:tr") {
            out.trim_suffix(b" | ");
            out.putc(b'\n');
        }
        i = t.end + 1;
    }
}

// ------------------------------------------------------------------------------------------------
// PowerPoint: text lives in <a:t>; <a:p> ends a paragraph
// ------------------------------------------------------------------------------------------------

fn extract_slide_xml(x: &[u8], out: &mut Sb) {
    let len = x.len();
    let mut i = 0;
    while i < len {
        i = match next_lt(x, i) {
            Some(p) => p,
            None => break,
        };
        let t = match read_tag(x, i) {
            Some(t) => t,
            None => break,
        };
        let name = &x[t.name_start..t.name_start + t.name_len];
        if !t.closing {
            if eq(name, "a:t") && !t.self_closing {
                let close = find_close(x, t.end + 1, b"</a:t>");
                put_decoded(out, &x[t.end + 1..close]);
                i = if close < len { close + 6 } else { len };
                continue;
            } else if eq(name, "a:br") {
                out.putc(b'\n');
            }
        } else if eq(name, "a:p") {
            out.putc(b'\n');
        }
        i = t.end + 1;
    }
}

/// Appends one slide ("--- Slide N ---" + its text). Returns true if the part existed.
fn append_slide(zip: &[u8], path: &str, number: usize, out: &mut Sb) -> bool {
    let xml = match load_part(zip, path) {
        Ok(x) => x,
        Err(_) => return false,
    };
    out.put(format!("--- Slide {} ---\n", number).as_bytes());
    extract_slide_xml(&xml, out);
    out.put(b"\n\n");
    true
}

/// Slides in the order they are presented: presentation.xml lists relationship ids, the .rels file maps ids to parts.
fn append_slides_in_order(zip: &[u8], out: &mut Sb) -> usize {
    let pres = match load_part(zip, "ppt/presentation.xml") {
        Ok(x) => x,
        Err(_) => return 0,
    };
    let rels = match load_part(zip, "ppt/_rels/presentation.xml.rels") {
        Ok(x) => x,
        Err(_) => return 0,
    };

    let mut table: Vec<(&[u8], &[u8])> = Vec::new();
    {
        let x: &[u8] = &rels;
        let mut i = 0;
        while i < x.len() && table.len() < MAX_RELS {
            i = match next_lt(x, i) {
                Some(p) => p,
                None => break,
            };
            let t = match read_tag(x, i) {
                Some(t) => t,
                None => break,
            };
            if !t.closing && eq(&x[t.name_start..t.name_start + t.name_len], "Relationship") {
                let tag = &x[i..=t.end];
                if let (Some(id), Some(target)) = (attr_value(tag, "Id"), attr_value(tag, "Target")) {
                    table.push((id, target));
                }
            }
            i = t.end + 1;
        }
    }

    let mut count = 0usize;
    let x: &[u8] = &pres;
    let mut i = 0;
    while i < x.len() && count < MAX_SLIDES {
        i = match next_lt(x, i) {
            Some(p) => p,
            None => break,
        };
        let t = match read_tag(x, i) {
            Some(t) => t,
            None => break,
        };
        if !t.closing && eq(&x[t.name_start..t.name_start + t.name_len], "p:sldId") {
            let tag = &x[i..=t.end];
            if let Some(rid) = attr_value(tag, "r:id") {
                for (id, target) in table.iter() {
                    if *id != rid {
                        continue;
                    }
                    let mut path: Vec<u8> = Vec::new();
                    if !target.is_empty() && target[0] == b'/' {
                        path.extend_from_slice(&target[1..]);
                    } else {
                        path.extend_from_slice(b"ppt/");
                        path.extend_from_slice(target);
                    }
                    if path.len() < 256 && !contains(&path, b"..") {
                        if let Ok(p) = std::str::from_utf8(&path) {
                            if append_slide(zip, p, count + 1, out) {
                                count += 1;
                            }
                        }
                    }
                    break;
                }
            }
        }
        i = t.end + 1;
    }
    count
}

// ------------------------------------------------------------------------------------------------
// General source/text ZIP extraction. Archive paths are never written to disk: selected text entries are read
// directly from the in-memory archive. Limits defend against ZIP bombs and huge repositories.
// ------------------------------------------------------------------------------------------------

fn zip_name_is_text(name: &[u8]) -> bool {
    let length = name.len();
    if length == 0 {
        return false;
    }
    if name[length - 1] == b'/' {
        return false;
    }
    // Ignore hidden metadata / dependency trees that add noise and can dominate the archive.
    if contains(name, b"/.git/")
        || contains(name, b"/node_modules/")
        || contains(name, b"/Pods/")
        || contains(name, b"/.svn/")
        || name.starts_with(b".git/")
        || name.starts_with(b"node_modules/")
        || name.starts_with(b"Pods/")
        || name.starts_with(b".svn/")
    {
        return false;
    }
    let base = name.iter().rposition(|&c| c == b'/').map(|p| p + 1).unwrap_or(0);
    let mut dot = length;
    for i in base..length {
        if name[i] == b'.' {
            dot = i + 1;
        }
    }
    if dot >= length {
        let base_len = length - base;
        if base_len == 0 || base_len >= 32 {
            return false;
        }
        let lower: Vec<u8> = name[base..].iter().map(|c| c.to_ascii_lowercase()).collect();
        return matches!(
            &lower[..],
            b"dockerfile" | b"makefile" | b"license" | b"readme" | b"notice" | b"gemfile" | b"rakefile" | b"procfile"
        );
    }
    let ext_len = length - dot;
    if ext_len == 0 || ext_len >= 16 {
        return false;
    }
    let ext: Vec<u8> = name[dot..].iter().map(|c| c.to_ascii_lowercase()).collect();
    static ALLOWED: &[&str] = &[
        "txt", "md", "markdown", "rst", "text", "json", "jsonl", "csv", "tsv", "xml", "html", "htm", "css", "scss",
        "less", "js", "jsx", "ts", "tsx", "mjs", "cjs", "m", "h", "mm", "hpp", "hh", "cc", "cpp", "cxx", "swift",
        "py", "pyi", "java", "kt", "kts", "go", "rs", "rb", "php", "sh", "bash", "zsh", "fish", "yml", "yaml", "toml",
        "ini", "cfg", "conf", "plist", "sql", "log", "gradle", "properties", "env", "gitignore", "dockerfile",
        "makefile", "cmake", "vue", "svelte", "dart", "lua", "r", "ipynb", "patch", "diff", "proto", "graphql", "gql",
        "tf", "hcl", "bat", "ps1", "cs", "fs", "vb", "scala", "sc", "pl", "pm", "ex", "exs", "erl", "hrl", "clj",
        "cljs", "cljc", "edn",
    ];
    ALLOWED.iter().any(|a| a.as_bytes() == &ext[..])
}

fn zip_bytes_are_text_utf8(bytes: &[u8]) -> bool {
    let length = bytes.len();
    if length == 0 {
        return false;
    }
    let mut i = 0;
    while i < length {
        let c = bytes[i];
        i += 1;
        if c == 0 || c < 0x09 || (c > 0x0D && c < 0x20) {
            return false;
        }
        if c < 0x80 {
            continue;
        }
        let need: usize = if (0xC2..=0xDF).contains(&c) {
            1
        } else if (0xE0..=0xEF).contains(&c) {
            2
        } else if (0xF0..=0xF4).contains(&c) {
            3
        } else {
            99
        };
        if need == 99 || i + need > length {
            return false;
        }
        let first = bytes[i];
        if (c == 0xE0 && first < 0xA0) || (c == 0xED && first >= 0xA0) || (c == 0xF0 && first < 0x90) || (c == 0xF4 && first >= 0x90) {
            return false;
        }
        for j in 0..need {
            if bytes[i + j] & 0xC0 != 0x80 {
                return false;
            }
        }
        i += need;
    }
    true
}

// ------------------------------------------------------------------------------------------------
// Public (crate) API: each returns the UTF-8 text or an OFFICE_ERR_* code
// ------------------------------------------------------------------------------------------------

pub fn docx_text(zip: &[u8]) -> Result<Vec<u8>, i32> {
    let xml = load_part(zip, "word/document.xml")?;
    let mut sb = Sb::new();
    extract_docx_xml(&xml, &mut sb);
    Ok(tidy(&sb.buf))
}

pub fn pptx_text(zip: &[u8]) -> Result<Vec<u8>, i32> {
    let mut sb = Sb::new();
    let mut slides = append_slides_in_order(zip, &mut sb);
    if slides == 0 {
        // Fall back to file-name order (slide1.xml, slide2.xml, ...) if the presentation index could not be read.
        for n in 1..=MAX_SLIDES {
            let path = format!("ppt/slides/slide{}.xml", n);
            if !append_slide(zip, &path, n, &mut sb) {
                break;
            }
            slides += 1;
        }
    }
    if slides == 0 {
        // Distinguish "not a zip at all" from "a zip without slides".
        let code = match find_entry(zip, b"[Content_Types].xml") {
            Err(ERR_NOT_ZIP) => ERR_NOT_ZIP,
            Err(ERR_UNSUPPORTED) => ERR_UNSUPPORTED,
            _ => ERR_MISSING_PART,
        };
        return Err(code);
    }
    Ok(tidy(&sb.buf))
}

pub fn zip_text(zip: &[u8]) -> Result<Vec<u8>, i32> {
    let zip_len = zip.len();
    if zip_len < 22 {
        return Err(ERR_NOT_ZIP);
    }
    let eocd = find_eocd(zip).ok_or(ERR_NOT_ZIP)?;
    let total = rd16(zip, eocd + 10) as u32;
    let cd_size = rd32(zip, eocd + 12);
    let cd_off = rd32(zip, eocd + 16);
    if total == 0xFFFF || cd_size == 0xFFFF_FFFF || cd_off == 0xFFFF_FFFF {
        return Err(ERR_UNSUPPORTED);
    }
    if total > MAX_ZIP_ENTRIES || cd_off as u64 + cd_size as u64 > zip_len as u64 {
        return Err(ERR_NOT_ZIP);
    }

    let mut output = Sb::with_limit(MAX_ZIP_TEXT_BYTES);
    let mut cursor = cd_off as usize;
    let end = cursor + cd_size as usize;
    let mut saw_oversized_text = false;
    for _ in 0..total {
        if end - cursor < 46 || rd32(zip, cursor) != 0x0201_4b50 {
            return Err(ERR_NOT_ZIP);
        }
        let flags = rd16(zip, cursor + 8);
        let name_len = rd16(zip, cursor + 28) as usize;
        let extra_len = rd16(zip, cursor + 30) as usize;
        let comment_len = rd16(zip, cursor + 32) as usize;
        if end - cursor < 46 + name_len + extra_len + comment_len {
            return Err(ERR_NOT_ZIP);
        }
        let size = rd32(zip, cursor + 24);
        let csize = rd32(zip, cursor + 20);
        let lho = rd32(zip, cursor + 42);
        let name = &zip[cursor + 46..cursor + 46 + name_len];
        let text_name = zip_name_is_text(name);
        if text_name && (size as usize) > MAX_ZIP_ENTRY_BYTES {
            saw_oversized_text = true;
        }
        let selected = flags & 1 == 0
            && size > 0
            && (size as usize) <= MAX_ZIP_ENTRY_BYTES
            && csize != 0xFFFF_FFFF
            && size != 0xFFFF_FFFF
            && lho != 0xFFFF_FFFF
            && text_name;
        if selected && output.buf.len() < MAX_ZIP_TEXT_BYTES {
            let entry = ZipEntry { method: rd16(zip, cursor + 10), csize, size, lho };
            if let Ok(contents) = read_entry(zip, &entry) {
                if zip_bytes_are_text_utf8(&contents) {
                    output.put(b"\n\n===== ");
                    output.put(name);
                    output.put(b" =====\n");
                    output.put(&contents);
                }
            }
        }
        cursor += 46 + name_len + extra_len + comment_len;
        if output.overflow {
            break;
        }
    }
    if output.buf.is_empty() {
        return Err(if saw_oversized_text { ERR_TOO_LARGE } else { ERR_MISSING_PART });
    }
    if output.overflow {
        output.overflow = false;
        output.put(b"\n[ZIP text truncated at the safe extraction limit.]\n");
    }
    Ok(tidy(&output.buf))
}
