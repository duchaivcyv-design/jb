//! Chooses which parts of a very large instruction text go into a request when the whole text does not fit the
//! character budget. It follows the Objective-C version in AppSettings.m step by step:
//!   1. cut the text into chunks (at line breaks, at most 4096 UTF-16 units each; always the same cut for the same text),
//!   2. take the first chunk and, if it fits, the last one,
//!   3. add the chunks that mention the words of the question, best score first,
//!   4. fill what is left from the end of the text towards the start,
//!   5. join the chosen chunks in their original order.
//! Lengths are counted in UTF-16 units because that is what NSString.length (and so the budget) counts.

const MAX_CHUNK: usize = 4096;
const MAX_TERMS: usize = 32;
const STOP_WORDS: [&str; 20] = [
    "the", "and", "for", "with", "that", "this", "from", "you", "your", "cua", "cho", "voi", "mot", "nhung", "cac",
    "hay", "la", "va", "duoc", "giup",
];

fn len16(s: &str) -> usize {
    s.chars().map(|c| c.len_utf16()).sum()
}

// NSCharacterSet.newlineCharacterSet: U+000A..U+000D, U+0085, U+2028, U+2029
fn is_newline(c: char) -> bool {
    matches!(c, '\u{0a}'..='\u{0d}' | '\u{85}' | '\u{2028}' | '\u{2029}')
}

fn is_mark(c: char) -> bool {
    matches!(c as u32,
        0x0300..=0x036F | 0x1AB0..=0x1AFF | 0x1DC0..=0x1DFF | 0x20D0..=0x20FF | 0xFE00..=0xFE0F | 0xFE20..=0xFE2F)
}

// Characters that must stay attached to the character before them (accents, joiners, skin tones): never cut in front of one.
fn is_extend(c: char) -> bool {
    is_mark(c) || c == '\u{200d}' || matches!(c as u32, 0x1F3FB..=0x1F3FF | 0xE0100..=0xE01EF)
}

// NSCharacterSet.alphanumericCharacterSet is letters, marks and numbers.
fn is_word_char(c: char) -> bool {
    c.is_alphanumeric() || is_mark(c)
}

/// Byte index at which to cut `s` so that the part in front holds at most `max16` UTF-16 units and does not end in the
/// middle of an accented/joined character. Always makes progress (at least one character) when `s` is not empty.
fn safe_cut(s: &str, max16: usize) -> usize {
    let mut units = 0usize;
    let mut cut = 0usize;
    for (i, c) in s.char_indices() {
        let next = units + c.len_utf16();
        if next > max16 {
            break;
        }
        units = next;
        cut = i + c.len_utf8();
    }
    if cut == 0 {
        // not even one character fits: take one so the caller still moves forward
        return s.chars().next().map(|c| c.len_utf8()).unwrap_or(0);
    }
    let forced = cut;
    while cut < s.len() {
        let next = s[cut..].chars().next().unwrap();
        if !is_extend(next) {
            break;
        }
        // step back over the character in front of the extender
        match s[..cut].char_indices().next_back() {
            Some((i, _)) if i > 0 => cut = i,
            _ => return forced,
        }
    }
    cut
}

struct Chunk {
    text: String,
    lower: String,
    len: usize,
}

fn make_chunks(prompt: &str) -> Vec<Chunk> {
    let mut chunks: Vec<Chunk> = Vec::new();
    let mut current = String::new();
    let mut current16 = 0usize;

    fn push(chunks: &mut Vec<Chunk>, text: &str) {
        let len = len16(text);
        if len == 0 {
            return;
        }
        chunks.push(Chunk { text: text.to_string(), lower: text.to_lowercase(), len });
    }

    for line in prompt.split(is_newline) {
        let mut piece = line;
        let mut piece16 = len16(piece);
        if current16 > 0 && current16 + piece16 + 1 > MAX_CHUNK {
            push(&mut chunks, &current);
            current.clear();
            current16 = 0;
        }
        while piece16 > MAX_CHUNK {
            let cut = safe_cut(piece, MAX_CHUNK);
            push(&mut chunks, &piece[..cut]);
            piece = &piece[cut..];
            piece16 = len16(piece);
        }
        if piece16 > 0 {
            if current16 > 0 {
                current.push('\n');
                current16 += 1;
            }
            current.push_str(piece);
            current16 += piece16;
        }
    }
    push(&mut chunks, &current);
    chunks
}

fn query_terms(query: &str) -> Vec<String> {
    let lower = query.to_lowercase();
    let mut terms: Vec<String> = Vec::new();
    for term in lower.split(|c: char| !is_word_char(c)) {
        if len16(term) >= 3 && !STOP_WORDS.contains(&term) && !terms.iter().any(|t| t == term) {
            terms.push(term.to_string());
        }
        if terms.len() >= MAX_TERMS {
            break;
        }
    }
    terms
}

pub fn select(prompt: &str, query: &str, budget: usize) -> String {
    if prompt.is_empty() || budget == 0 {
        return String::new();
    }
    if len16(prompt) <= budget {
        return prompt.to_string();
    }
    let chunks = make_chunks(prompt);
    if chunks.is_empty() {
        return String::new();
    }
    let terms = query_terms(query);
    let count = chunks.len();
    let mut selected = vec![false; count];

    selected[0] = true;
    let mut used = chunks[0].len;
    if count > 1 {
        let last_len = chunks[count - 1].len;
        if last_len + used + 96 <= budget {
            selected[count - 1] = true;
            used += last_len + 2;
        }
    }

    let mut ranked: Vec<(usize, usize)> = Vec::new(); // (score, index)
    for i in 0..count {
        if selected[i] {
            continue;
        }
        let mut score = 0usize;
        for term in &terms {
            if chunks[i].lower.contains(term.as_str()) {
                score += if len16(term) >= 6 { 3 } else { 1 };
            }
        }
        if score > 0 {
            ranked.push((score, i));
        }
    }
    ranked.sort_by(|a, b| b.0.cmp(&a.0).then(a.1.cmp(&b.1)));
    for (_, index) in ranked {
        let length = chunks[index].len + 2;
        if used + length > budget {
            continue;
        }
        selected[index] = true;
        used += length;
    }
    if count >= 3 {
        for i in (1..=count - 2).rev() {
            if selected[i] {
                continue;
            }
            let length = chunks[i].len + 2;
            if used + length > budget {
                continue;
            }
            selected[i] = true;
            used += length;
        }
    }

    let mut result = String::new();
    let mut result16 = 0usize;
    for i in 0..count {
        if !selected[i] {
            continue;
        }
        if result16 + chunks[i].len + 2 > budget {
            continue;
        }
        result.push_str(&chunks[i].text);
        result.push_str("\n\n");
        result16 += chunks[i].len + 2;
    }
    if result16 > budget {
        // keeps whole characters, like rangeOfComposedCharacterSequencesForRange (may run a few units over)
        let mut cut = safe_cut(&result, budget);
        while cut < result.len() && is_extend(result[cut..].chars().next().unwrap()) {
            cut += result[cut..].chars().next().unwrap().len_utf8();
        }
        result.truncate(cut);
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn big_prompt() -> String {
        let mut lines = Vec::new();
        lines.push("RULES: always answer politely.".to_string());
        for n in 0..400 {
            lines.push(format!("filler line number {} with nothing interesting at all", n));
        }
        lines.push("The kubernetes cluster is deployed with helm charts.".to_string());
        for n in 400..800 {
            lines.push(format!("another filler line {} about weather and cooking", n));
        }
        lines.push("END: sign every answer.".to_string());
        lines.join("\n")
    }

    #[test]
    fn short_prompt_is_returned_unchanged() {
        assert_eq!(select("hello world", "anything", 100), "hello world");
        assert_eq!(select("hello", "x", 0), "");
        assert_eq!(select("", "x", 10), "");
    }

    #[test]
    fn chunks_are_at_most_4096_units_and_cover_the_text() {
        let prompt = big_prompt();
        let chunks = make_chunks(&prompt);
        assert!(chunks.len() > 5);
        assert!(chunks.iter().all(|c| c.len <= MAX_CHUNK));
        let rebuilt: usize = chunks.iter().map(|c| c.text.chars().filter(|&ch| ch != '\n').count()).sum();
        let original: usize = prompt.chars().filter(|&ch| ch != '\n').count();
        assert_eq!(rebuilt, original);
    }

    #[test]
    fn long_line_is_cut_without_splitting_accents() {
        let line: String = "e\u{0301}".repeat(5000); // 10000 units, every pair is one visible letter
        let chunks = make_chunks(&line);
        assert!(chunks.len() >= 3);
        for c in &chunks {
            assert!(c.len <= MAX_CHUNK);
            assert!(!is_extend(c.text.chars().next().unwrap()), "a chunk starts with an accent");
        }
        let total: usize = chunks.iter().map(|c| c.len).sum();
        assert_eq!(total, 10000);
    }

    #[test]
    fn keeps_first_chunk_and_the_chunk_that_matches_the_question() {
        let prompt = big_prompt();
        // chunks are up to 4096 units, so the first chunk, the last one and the matching one need about 12000
        let out = select(&prompt, "How do I deploy the kubernetes cluster with helm?", 13000);
        assert!(out.starts_with("RULES: always answer politely."));
        assert!(out.contains("The kubernetes cluster is deployed with helm charts."));
        assert!(len16(&out) <= 13000);
    }

    #[test]
    fn result_never_exceeds_budget_by_more_than_a_character() {
        let prompt = big_prompt();
        for budget in [4200usize, 5000, 9000, 20000] {
            let out = select(&prompt, "weather", budget);
            assert!(len16(&out) <= budget + 4, "budget {} got {}", budget, len16(&out));
            assert!(!out.is_empty());
        }
    }

    #[test]
    fn a_budget_smaller_than_the_first_chunk_gives_an_empty_result_like_the_objective_c_version() {
        let prompt = big_prompt();
        assert_eq!(select(&prompt, "weather", 3000), "");
    }

    #[test]
    fn same_input_gives_same_output() {
        let prompt = big_prompt();
        assert_eq!(select(&prompt, "cooking weather", 7000), select(&prompt, "cooking weather", 7000));
    }

    #[test]
    fn terms_skip_stop_words_short_words_and_duplicates() {
        let t = query_terms("The kubernetes and kubernetes of Helm, la cho ab");
        assert_eq!(t, vec!["kubernetes".to_string(), "helm".to_string()]);
    }

    #[test]
    fn vietnamese_text_is_measured_in_utf16_units() {
        assert_eq!(len16("Tiếng Việt"), 10);
        assert_eq!(len16("😀"), 2);
    }
}
