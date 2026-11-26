//! Builds a minimal .docx (a ZIP of three XML parts, stored without compression) from plain text.
//! A port of the former OfficeExport.m XMLSafe / MinimalDOCXData code, with the same output.

fn crc32(data: &[u8]) -> u32 {
    static TABLE: std::sync::OnceLock<[u32; 256]> = std::sync::OnceLock::new();
    let table = TABLE.get_or_init(|| {
        let mut t = [0u32; 256];
        for (i, slot) in t.iter_mut().enumerate() {
            let mut c = i as u32;
            for _ in 0..8 {
                c = if c & 1 != 0 { 0xEDB8_8320 ^ (c >> 1) } else { c >> 1 };
            }
            *slot = c;
        }
        t
    });
    let mut crc = 0xFFFF_FFFFu32;
    for &b in data {
        crc = table[((crc ^ b as u32) & 0xFF) as usize] ^ (crc >> 8);
    }
    crc ^ 0xFFFF_FFFF
}

/// Drops characters XML cannot carry and escapes the five special ones.
fn xml_safe(text: &str) -> String {
    let mut out = String::with_capacity(text.len() + 16);
    for c in text.chars() {
        let u = c as u32;
        if !(u == 0x9 || u == 0xA || u == 0xD || u >= 0x20) {
            continue;
        }
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&apos;"),
            _ => out.push(c),
        }
    }
    out
}

fn le16(v: &mut Vec<u8>, x: u16) {
    v.extend_from_slice(&x.to_le_bytes());
}

fn le32(v: &mut Vec<u8>, x: u32) {
    v.extend_from_slice(&x.to_le_bytes());
}

fn is_newline(c: char) -> bool {
    matches!(c, '\u{000A}'..='\u{000D}' | '\u{0085}' | '\u{2028}' | '\u{2029}')
}

/// Every newline character is its own separator ("a\r\nb" gives an empty line between), as the old code did.
fn document_xml(text: &str) -> String {
    let mut paragraphs = String::new();
    for line in text.split(is_newline) {
        paragraphs.push_str("<w:p><w:r><w:t xml:space=\"preserve\">");
        paragraphs.push_str(&xml_safe(line));
        paragraphs.push_str("</w:t></w:r></w:p>");
    }
    let mut doc = String::new();
    doc.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>");
    doc.push_str("<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">");
    doc.push_str("<w:body>");
    doc.push_str(&paragraphs);
    doc.push_str("<w:sectPr><w:pgSz w:w=\"11906\" w:h=\"16838\"/>");
    doc.push_str("<w:pgMar w:top=\"1440\" w:right=\"1440\" w:bottom=\"1440\" w:left=\"1440\" w:header=\"720\" w:footer=\"720\" w:gutter=\"0\"/>");
    doc.push_str("</w:sectPr></w:body></w:document>");
    doc
}

const CONTENT_TYPES: &str = concat!(
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
    "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">",
    "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>",
    "<Default Extension=\"xml\" ContentType=\"application/xml\"/>",
    "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>",
    "</Types>"
);

const RELATIONSHIPS: &str = concat!(
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
    "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
    "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>",
    "</Relationships>"
);

/// Returns the .docx bytes, or None if a part would not fit a classic (non-ZIP64) archive.
pub fn build(text: &[u8]) -> Option<Vec<u8>> {
    let text = String::from_utf8_lossy(text);
    let document = document_xml(&text);
    let entries: [(&str, &[u8]); 3] = [
        ("[Content_Types].xml", CONTENT_TYPES.as_bytes()),
        ("_rels/.rels", RELATIONSHIPS.as_bytes()),
        ("word/document.xml", document.as_bytes()),
    ];

    let mut archive: Vec<u8> = Vec::new();
    let mut central: Vec<u8> = Vec::new();
    for (name, payload) in entries.iter() {
        let name = name.as_bytes();
        if name.len() > u16::MAX as usize || payload.len() > u32::MAX as usize {
            return None;
        }
        let crc = crc32(payload);
        let offset = archive.len() as u32;

        le32(&mut archive, 0x0403_4b50);
        le16(&mut archive, 20);
        le16(&mut archive, 0x0800); // UTF-8 file name
        le16(&mut archive, 0); // stored, no compression
        le16(&mut archive, 0);
        le16(&mut archive, 0);
        le32(&mut archive, crc);
        le32(&mut archive, payload.len() as u32);
        le32(&mut archive, payload.len() as u32);
        le16(&mut archive, name.len() as u16);
        le16(&mut archive, 0);
        archive.extend_from_slice(name);
        archive.extend_from_slice(payload);

        le32(&mut central, 0x0201_4b50);
        le16(&mut central, 20);
        le16(&mut central, 20);
        le16(&mut central, 0x0800);
        le16(&mut central, 0);
        le16(&mut central, 0);
        le16(&mut central, 0);
        le32(&mut central, crc);
        le32(&mut central, payload.len() as u32);
        le32(&mut central, payload.len() as u32);
        le16(&mut central, name.len() as u16);
        le16(&mut central, 0);
        le16(&mut central, 0);
        le16(&mut central, 0);
        le16(&mut central, 0);
        le32(&mut central, 0);
        le32(&mut central, offset);
        central.extend_from_slice(name);
    }

    let central_offset = archive.len() as u32;
    archive.extend_from_slice(&central);
    le32(&mut archive, 0x0605_4b50);
    le16(&mut archive, 0);
    le16(&mut archive, 0);
    le16(&mut archive, entries.len() as u16);
    le16(&mut archive, entries.len() as u16);
    le32(&mut archive, central.len() as u32);
    le32(&mut archive, central_offset);
    le16(&mut archive, 0);
    Some(archive)
}
