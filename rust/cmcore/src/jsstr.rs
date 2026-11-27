//! Turns text into a JavaScript string literal ("...") that is safe to paste into `evaluateJavaScript`.
//! One pass over the text; this runs for every piece of a streaming reply.

pub fn js_literal(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + s.len() / 8 + 2);
    out.push('"');
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            '\u{08}' => out.push_str("\\b"),
            '\u{0c}' => out.push_str("\\f"),
            // U+2028 / U+2029 end a line in JavaScript source (before ES2019 they were illegal inside a string literal)
            '\u{2028}' => out.push_str("\\u2028"),
            '\u{2029}' => out.push_str("\\u2029"),
            c if (c as u32) < 0x20 => {
                out.push_str("\\u");
                out.push_str(&format!("{:04x}", c as u32));
            }
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plain_text_is_only_quoted() {
        assert_eq!(js_literal("hello"), "\"hello\"");
        assert_eq!(js_literal(""), "\"\"");
    }

    #[test]
    fn escapes_quotes_backslashes_and_controls() {
        assert_eq!(js_literal("a\"b\\c\nd\re\tf"), "\"a\\\"b\\\\c\\nd\\re\\tf\"");
        assert_eq!(js_literal("\u{01}\u{1f}"), "\"\\u0001\\u001f\"");
        assert_eq!(js_literal("\u{08}\u{0c}"), "\"\\b\\f\"");
    }

    #[test]
    fn escapes_line_separators_and_keeps_unicode() {
        assert_eq!(js_literal("a\u{2028}b\u{2029}c"), "\"a\\u2028b\\u2029c\"");
        assert_eq!(js_literal("Tiếng Việt 😀"), "\"Tiếng Việt 😀\"");
    }
}
