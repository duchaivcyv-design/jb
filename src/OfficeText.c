#include "OfficeText.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <strings.h>
#include <zlib.h>

#define MAX_PART_BYTES (40u * 1024u * 1024u)   // largest uncompressed XML part we will inflate
#define MAX_TEXT_BYTES (4u * 1024u * 1024u)    // largest amount of extracted text we keep
#define MAX_SLIDES 1000
#define MAX_RELS 4096

/* ------------------------------------------------------------------------------------------------
 * Little-endian readers
 * ---------------------------------------------------------------------------------------------- */

static uint16_t rd16(const unsigned char *p) {
    return (uint16_t)(p[0] | (p[1] << 8));
}

static uint32_t rd32(const unsigned char *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

/* ------------------------------------------------------------------------------------------------
 * Minimal ZIP reader: looks entries up through the central directory (so data descriptors are fine)
 * ---------------------------------------------------------------------------------------------- */

typedef struct {
    uint16_t method;
    uint32_t csize;
    uint32_t usize;
    uint32_t lho;   // local header offset
} zip_entry;

static int find_entry(const unsigned char *z, size_t n, const char *name, zip_entry *out) {
    if (n < 22) return OFFICE_ERR_NOT_ZIP;
    size_t nameLen = strlen(name);

    // The end-of-central-directory record sits at the very end, optionally followed by a comment (<= 65535 bytes).
    long long minPos = (long long)n - 22 - 65535;
    if (minPos < 0) minPos = 0;
    long long eocd = -1;
    for (long long i = (long long)n - 22; i >= minPos; i--) {
        if (rd32(z + i) == 0x06054b50u) { eocd = i; break; }
    }
    if (eocd < 0) return OFFICE_ERR_NOT_ZIP;

    uint32_t total = rd16(z + eocd + 10);
    uint32_t cdSize = rd32(z + eocd + 12);
    uint32_t cdOff = rd32(z + eocd + 16);
    if (total == 0xFFFFu || cdSize == 0xFFFFFFFFu || cdOff == 0xFFFFFFFFu) return OFFICE_ERR_UNSUPPORTED;   // ZIP64
    if ((uint64_t)cdOff + cdSize > n) return OFFICE_ERR_NOT_ZIP;

    const unsigned char *p = z + cdOff;
    const unsigned char *end = z + cdOff + cdSize;
    for (uint32_t i = 0; i < total; i++) {
        if ((size_t)(end - p) < 46 || rd32(p) != 0x02014b50u) return OFFICE_ERR_NOT_ZIP;
        uint16_t flags = rd16(p + 8);
        uint16_t method = rd16(p + 10);
        uint32_t csize = rd32(p + 20);
        uint32_t usize = rd32(p + 24);
        uint16_t nl = rd16(p + 28);
        uint16_t el = rd16(p + 30);
        uint16_t cl = rd16(p + 32);
        uint32_t lho = rd32(p + 42);
        if ((size_t)(end - p) < (size_t)46 + nl + el + cl) return OFFICE_ERR_NOT_ZIP;

        if (nl == nameLen && memcmp(p + 46, name, nameLen) == 0) {
            if (flags & 1) return OFFICE_ERR_UNSUPPORTED;   // encrypted
            if (csize == 0xFFFFFFFFu || usize == 0xFFFFFFFFu || lho == 0xFFFFFFFFu) return OFFICE_ERR_UNSUPPORTED;
            out->method = method;
            out->csize = csize;
            out->usize = usize;
            out->lho = lho;
            return OFFICE_OK;
        }
        p += (size_t)46 + nl + el + cl;
    }
    return OFFICE_ERR_MISSING_PART;
}

static int read_entry(const unsigned char *z, size_t n, const zip_entry *e, unsigned char **out, size_t *outLen) {
    if (e->usize > MAX_PART_BYTES) return OFFICE_ERR_TOO_LARGE;
    if ((uint64_t)e->lho + 30 > n || rd32(z + e->lho) != 0x04034b50u) return OFFICE_ERR_NOT_ZIP;

    size_t nl = rd16(z + e->lho + 26);
    size_t el = rd16(z + e->lho + 28);
    uint64_t dataStart = (uint64_t)e->lho + 30 + nl + el;
    if (dataStart + e->csize > n) return OFFICE_ERR_NOT_ZIP;
    const unsigned char *src = z + dataStart;

    unsigned char *buf = (unsigned char *)malloc((size_t)e->usize + 1);
    if (!buf) return OFFICE_ERR_NO_MEMORY;

    if (e->usize == 0) {
        // nothing to inflate
    } else if (e->method == 0) {
        if (e->csize != e->usize) { free(buf); return OFFICE_ERR_NOT_ZIP; }
        memcpy(buf, src, e->usize);
    } else if (e->method == 8) {
        z_stream s;
        memset(&s, 0, sizeof s);
        if (inflateInit2(&s, -MAX_WBITS) != Z_OK) { free(buf); return OFFICE_ERR_NO_MEMORY; }
        s.next_in = (Bytef *)src;
        s.avail_in = e->csize;
        s.next_out = buf;
        s.avail_out = e->usize;      // output is capped at the declared size, so a lying header cannot overflow the buffer
        int rc = inflate(&s, Z_FINISH);
        size_t produced = s.total_out;
        inflateEnd(&s);
        if (rc != Z_STREAM_END || produced != e->usize) { free(buf); return OFFICE_ERR_NOT_ZIP; }
    } else {
        free(buf);
        return OFFICE_ERR_UNSUPPORTED;
    }
    buf[e->usize] = 0;
    *out = buf;
    *outLen = e->usize;
    return OFFICE_OK;
}

static int load_part(const unsigned char *z, size_t n, const char *name, unsigned char **out, size_t *outLen) {
    zip_entry e;
    int rc = find_entry(z, n, name, &e);
    if (rc != OFFICE_OK) return rc;
    return read_entry(z, n, &e, out, outLen);
}

/* ------------------------------------------------------------------------------------------------
 * Growing text buffer with a hard size limit
 * ---------------------------------------------------------------------------------------------- */

typedef struct {
    char *p;
    size_t len;
    size_t cap;
    int overflow;   // hit MAX_TEXT_BYTES: further text is dropped
    int failed;     // out of memory
} sb_t;

static void sb_put(sb_t *b, const char *s, size_t n) {
    if (b->overflow || b->failed || n == 0) return;
    if (b->len + n > MAX_TEXT_BYTES) { b->overflow = 1; return; }
    if (b->len + n + 1 > b->cap) {
        size_t nc = b->cap ? b->cap : 4096;
        while (nc < b->len + n + 1) nc *= 2;
        char *np = (char *)realloc(b->p, nc);
        if (!np) { b->failed = 1; return; }
        b->p = np;
        b->cap = nc;
    }
    memcpy(b->p + b->len, s, n);
    b->len += n;
    b->p[b->len] = 0;
}

static void sb_putc(sb_t *b, char c) {
    sb_put(b, &c, 1);
}

/* Removes `suffix` from the end of the buffer if it is there. */
static void sb_trim_suffix(sb_t *b, const char *suffix) {
    size_t sl = strlen(suffix);
    if (b->p && b->len >= sl && memcmp(b->p + b->len - sl, suffix, sl) == 0) {
        b->len -= sl;
        b->p[b->len] = 0;
    }
}

static size_t utf8_encode(uint32_t cp, char *out) {
    if (cp == 0 || (cp >= 0xD800 && cp <= 0xDFFF) || cp > 0x10FFFF) return 0;
    if (cp < 0x20 && cp != '\t' && cp != '\n' && cp != '\r') return 0;
    if (cp < 0x80) { out[0] = (char)cp; return 1; }
    if (cp < 0x800) {
        out[0] = (char)(0xC0 | (cp >> 6));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp < 0x10000) {
        out[0] = (char)(0xE0 | (cp >> 12));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }
    out[0] = (char)(0xF0 | (cp >> 18));
    out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
}

/* Appends XML character data, decoding the five named entities and numeric references. */
static void put_decoded(sb_t *b, const char *s, size_t n) {
    size_t i = 0;
    while (i < n) {
        if (s[i] != '&') {
            size_t j = i;
            while (j < n && s[j] != '&') j++;
            sb_put(b, s + i, j - i);
            i = j;
            continue;
        }
        // entity: look for ';' within a short distance
        size_t j = i + 1;
        while (j < n && j - i <= 10 && s[j] != ';') j++;
        if (j >= n || s[j] != ';') { sb_putc(b, '&'); i++; continue; }

        size_t elen = j - i - 1;
        const char *e = s + i + 1;
        char tmp[4];
        if (elen == 3 && memcmp(e, "amp", 3) == 0) sb_putc(b, '&');
        else if (elen == 2 && memcmp(e, "lt", 2) == 0) sb_putc(b, '<');
        else if (elen == 2 && memcmp(e, "gt", 2) == 0) sb_putc(b, '>');
        else if (elen == 4 && memcmp(e, "quot", 4) == 0) sb_putc(b, '"');
        else if (elen == 4 && memcmp(e, "apos", 4) == 0) sb_putc(b, '\'');
        else if (elen >= 2 && e[0] == '#') {
            uint32_t cp = 0;
            int ok = 1;
            if (e[1] == 'x' || e[1] == 'X') {
                if (elen < 3) ok = 0;
                for (size_t k = 2; k < elen && ok; k++) {
                    char c = e[k];
                    uint32_t d;
                    if (c >= '0' && c <= '9') d = (uint32_t)(c - '0');
                    else if (c >= 'a' && c <= 'f') d = (uint32_t)(c - 'a' + 10);
                    else if (c >= 'A' && c <= 'F') d = (uint32_t)(c - 'A' + 10);
                    else { ok = 0; break; }
                    cp = cp * 16 + d;
                    if (cp > 0x10FFFF) ok = 0;
                }
            } else {
                for (size_t k = 1; k < elen && ok; k++) {
                    char c = e[k];
                    if (c < '0' || c > '9') { ok = 0; break; }
                    cp = cp * 10 + (uint32_t)(c - '0');
                    if (cp > 0x10FFFF) ok = 0;
                }
            }
            size_t m = ok ? utf8_encode(cp, tmp) : 0;
            if (m) sb_put(b, tmp, m);
        } else {
            // unknown entity: keep it readable
            sb_put(b, s + i, j - i + 1);
        }
        i = j + 1;
    }
}

/* ------------------------------------------------------------------------------------------------
 * Tiny XML helpers (the Office XML we read is machine-generated and well formed)
 * ---------------------------------------------------------------------------------------------- */

static int name_eq(const char *s, size_t n, const char *lit) {
    size_t l = strlen(lit);
    return n == l && memcmp(s, lit, l) == 0;
}

/* Index of the next '>' at or after `from`, or len if none. */
static size_t tag_end(const char *x, size_t len, size_t from) {
    const char *p = (const char *)memchr(x + from, '>', len - from);
    return p ? (size_t)(p - x) : len;
}

/* Index of the next occurrence of closeTag (e.g. "</w:t>") at or after `from`, or len if none. */
static size_t find_close(const char *x, size_t len, size_t from, const char *closeTag) {
    size_t cl = strlen(closeTag);
    while (from < len) {
        const char *p = (const char *)memchr(x + from, '<', len - from);
        if (!p) return len;
        size_t at = (size_t)(p - x);
        if (len - at >= cl && memcmp(p, closeTag, cl) == 0) return at;
        from = at + 1;
    }
    return len;
}

/* Value of attribute `attr` inside the tag text [tag, tag+tagLen), or NULL. */
static const char *attr_value(const char *tag, size_t tagLen, const char *attr, size_t *valueLen) {
    size_t al = strlen(attr);
    for (size_t i = 1; i + al + 2 < tagLen; i++) {
        unsigned char before = (unsigned char)tag[i - 1];
        if (before != ' ' && before != '\t' && before != '\n' && before != '\r') continue;
        if (memcmp(tag + i, attr, al) != 0 || tag[i + al] != '=') continue;
        char quote = tag[i + al + 1];
        if (quote != '"' && quote != '\'') continue;
        const char *v = tag + i + al + 2;
        const char *q = (const char *)memchr(v, quote, tagLen - (i + al + 2));
        if (!q) return NULL;
        *valueLen = (size_t)(q - v);
        return v;
    }
    return NULL;
}

/* Reads a tag starting at x[i] == '<'. Fills name range, closing/self-closing flags and the index of its '>'. */
static int read_tag(const char *x, size_t len, size_t i, size_t *nameStart, size_t *nameLen,
                    int *closing, int *selfClosing, size_t *endIdx) {
    size_t j = i + 1;
    if (j >= len) return 0;
    *closing = 0;
    if (x[j] == '/') { *closing = 1; j++; }
    size_t s = j;
    while (j < len && x[j] != '>' && x[j] != '/' && x[j] != ' ' && x[j] != '\t' && x[j] != '\n' && x[j] != '\r') j++;
    *nameStart = s;
    *nameLen = j - s;
    size_t k = tag_end(x, len, j);
    if (k >= len) return 0;
    *endIdx = k;
    *selfClosing = (k > 0 && x[k - 1] == '/');
    return 1;
}

/* Collapses runs of 3+ newlines to 2, strips trailing spaces on lines and trims both ends. */
static void tidy(sb_t *b) {
    if (!b->p) return;
    char *w = b->p;
    int newlines = 0;
    size_t i = 0;
    while (i < b->len) {
        char c = b->p[i];
        if (c == '\r') { i++; continue; }
        if (c == '\n') {
            while (w > b->p && (w[-1] == ' ' || w[-1] == '\t')) w--;
            if (++newlines <= 2) *w++ = '\n';
            i++;
            continue;
        }
        newlines = 0;
        *w++ = c;
        i++;
    }
    while (w > b->p && (w[-1] == '\n' || w[-1] == ' ' || w[-1] == '\t')) w--;
    *w = 0;
    size_t start = 0;
    while (b->p[start] == '\n' || b->p[start] == ' ' || b->p[start] == '\t') start++;
    if (start > 0) memmove(b->p, b->p + start, (size_t)(w - b->p) - start + 1);
    b->len = strlen(b->p);
}

/* ------------------------------------------------------------------------------------------------
 * Word: text lives in <w:t>; <w:p> ends a paragraph, <w:tab/>, <w:br/> and table cells add separators
 * ---------------------------------------------------------------------------------------------- */

static void extract_docx_xml(const char *x, size_t len, sb_t *out) {
    size_t i = 0;
    int cellDepth = 0;   // > 0 while inside a table cell: a table row must stay on one line
    while (i < len) {
        const char *lt = (const char *)memchr(x + i, '<', len - i);
        if (!lt) break;
        i = (size_t)(lt - x);

        size_t ns, nl, end;
        int closing, selfClosing;
        if (!read_tag(x, len, i, &ns, &nl, &closing, &selfClosing, &end)) break;
        const char *name = x + ns;

        if (!closing) {
            if (name_eq(name, nl, "w:t") && !selfClosing) {
                size_t close = find_close(x, len, end + 1, "</w:t>");
                put_decoded(out, x + end + 1, close - (end + 1));
                i = close < len ? close + 6 : len;
                continue;
            } else if (name_eq(name, nl, "w:tab")) {
                sb_putc(out, '\t');
            } else if (name_eq(name, nl, "w:br") || name_eq(name, nl, "w:cr")) {
                sb_putc(out, cellDepth > 0 ? ' ' : '\n');
            } else if (name_eq(name, nl, "w:tc") && !selfClosing) {
                cellDepth++;
            }
        } else {
            if (name_eq(name, nl, "w:p")) {
                sb_putc(out, cellDepth > 0 ? ' ' : '\n');
            } else if (name_eq(name, nl, "w:tc")) {
                if (cellDepth > 0) cellDepth--;
                sb_trim_suffix(out, " ");   // the cell's last paragraph already added a space
                sb_put(out, " | ", 3);
            } else if (name_eq(name, nl, "w:tr")) {
                sb_trim_suffix(out, " | ");
                sb_putc(out, '\n');
            }
        }
        i = end + 1;
    }
}

/* ------------------------------------------------------------------------------------------------
 * PowerPoint: text lives in <a:t>; <a:p> ends a paragraph
 * ---------------------------------------------------------------------------------------------- */

static void extract_slide_xml(const char *x, size_t len, sb_t *out) {
    size_t i = 0;
    while (i < len) {
        const char *lt = (const char *)memchr(x + i, '<', len - i);
        if (!lt) break;
        i = (size_t)(lt - x);

        size_t ns, nl, end;
        int closing, selfClosing;
        if (!read_tag(x, len, i, &ns, &nl, &closing, &selfClosing, &end)) break;
        const char *name = x + ns;

        if (!closing) {
            if (name_eq(name, nl, "a:t") && !selfClosing) {
                size_t close = find_close(x, len, end + 1, "</a:t>");
                put_decoded(out, x + end + 1, close - (end + 1));
                i = close < len ? close + 6 : len;
                continue;
            } else if (name_eq(name, nl, "a:br")) {
                sb_putc(out, '\n');
            }
        } else if (name_eq(name, nl, "a:p")) {
            sb_putc(out, '\n');
        }
        i = end + 1;
    }
}

typedef struct {
    const char *id;
    size_t idLen;
    const char *target;
    size_t targetLen;
} rel_t;

/* Appends one slide ("--- Slide N ---" + its text). Returns 1 if the part existed. */
static int append_slide(const unsigned char *zip, size_t zipLen, const char *path, int number, sb_t *out) {
    unsigned char *xml = NULL;
    size_t xmlLen = 0;
    if (load_part(zip, zipLen, path, &xml, &xmlLen) != OFFICE_OK) return 0;
    char header[48];
    int hl = snprintf(header, sizeof header, "--- Slide %d ---\n", number);
    sb_put(out, header, (size_t)hl);
    extract_slide_xml((const char *)xml, xmlLen, out);
    sb_put(out, "\n\n", 2);
    free(xml);
    return 1;
}

/* Slides in the order they are presented: presentation.xml lists relationship ids, the .rels file maps ids to parts. */
static int append_slides_in_order(const unsigned char *zip, size_t zipLen, sb_t *out) {
    unsigned char *pres = NULL, *rels = NULL;
    size_t presLen = 0, relsLen = 0;
    int count = 0;
    rel_t *table = NULL;

    if (load_part(zip, zipLen, "ppt/presentation.xml", &pres, &presLen) != OFFICE_OK) goto done;
    if (load_part(zip, zipLen, "ppt/_rels/presentation.xml.rels", &rels, &relsLen) != OFFICE_OK) goto done;

    table = (rel_t *)malloc(sizeof(rel_t) * MAX_RELS);
    if (!table) goto done;
    int relCount = 0;
    {
        const char *x = (const char *)rels;
        size_t i = 0;
        while (i < relsLen && relCount < MAX_RELS) {
            const char *lt = (const char *)memchr(x + i, '<', relsLen - i);
            if (!lt) break;
            i = (size_t)(lt - x);
            size_t ns, nl, end;
            int closing, selfClosing;
            if (!read_tag(x, relsLen, i, &ns, &nl, &closing, &selfClosing, &end)) break;
            if (!closing && name_eq(x + ns, nl, "Relationship")) {
                size_t idl = 0, tgl = 0;
                const char *id = attr_value(x + i, end - i + 1, "Id", &idl);
                const char *tg = attr_value(x + i, end - i + 1, "Target", &tgl);
                if (id && tg) {
                    table[relCount].id = id;
                    table[relCount].idLen = idl;
                    table[relCount].target = tg;
                    table[relCount].targetLen = tgl;
                    relCount++;
                }
            }
            i = end + 1;
        }
    }
    {
        const char *x = (const char *)pres;
        size_t i = 0;
        while (i < presLen && count < MAX_SLIDES) {
            const char *lt = (const char *)memchr(x + i, '<', presLen - i);
            if (!lt) break;
            i = (size_t)(lt - x);
            size_t ns, nl, end;
            int closing, selfClosing;
            if (!read_tag(x, presLen, i, &ns, &nl, &closing, &selfClosing, &end)) break;
            if (!closing && name_eq(x + ns, nl, "p:sldId")) {
                size_t ridLen = 0;
                const char *rid = attr_value(x + i, end - i + 1, "r:id", &ridLen);
                for (int r = 0; rid && r < relCount; r++) {
                    if (table[r].idLen != ridLen || memcmp(table[r].id, rid, ridLen) != 0) continue;
                    char path[256];
                    const char *tg = table[r].target;
                    size_t tgl = table[r].targetLen;
                    int pl;
                    if (tgl > 0 && tg[0] == '/') pl = snprintf(path, sizeof path, "%.*s", (int)(tgl - 1), tg + 1);
                    else pl = snprintf(path, sizeof path, "ppt/%.*s", (int)tgl, tg);
                    if (pl > 0 && (size_t)pl < sizeof path && !strstr(path, "..")) {
                        if (append_slide(zip, zipLen, path, count + 1, out)) count++;
                    }
                    break;
                }
            }
            i = end + 1;
        }
    }

done:
    free(table);
    free(pres);
    free(rels);
    return count;
}

/* ------------------------------------------------------------------------------------------------
 * Public API
 * ---------------------------------------------------------------------------------------------- */

static char *finish(sb_t *sb, int *err) {
    if (sb->failed) {
        free(sb->p);
        *err = OFFICE_ERR_NO_MEMORY;
        return NULL;
    }
    if (!sb->p) {
        char *empty = (char *)malloc(1);
        if (!empty) { *err = OFFICE_ERR_NO_MEMORY; return NULL; }
        empty[0] = 0;
        return empty;
    }
    tidy(sb);
    return sb->p;
}


/* ------------------------------------------------------------------------------------------------
 * General source/text ZIP extraction. We never write archive paths to disk: selected text entries
 * are read directly from the in-memory archive. Limits defend against ZIP bombs and huge repos.
 * ------------------------------------------------------------------------------------------------ */

static int zip_name_contains(const unsigned char *name, size_t length, const char *needle) {
    size_t needleLen = strlen(needle);
    if (!needleLen || needleLen > length) return 0;
    for (size_t i = 0; i + needleLen <= length; i++) {
        if (memcmp(name + i, needle, needleLen) == 0) return 1;
    }
    return 0;
}

static int zip_name_is_text(const unsigned char *name, size_t length) {
    if (!name || length == 0) return 0;
    if (name[length - 1] == '/') return 0;
    /* Ignore hidden metadata / dependency trees that add noise and can dominate the archive. */
    if (zip_name_contains(name, length, "/.git/") || zip_name_contains(name, length, "/node_modules/") ||
        zip_name_contains(name, length, "/Pods/") || zip_name_contains(name, length, "/.svn/") ||
        (length >= 5 && memcmp(name, ".git/", 5) == 0) ||
        (length >= 13 && memcmp(name, "node_modules/", 13) == 0) ||
        (length >= 5 && memcmp(name, "Pods/", 5) == 0) ||
        (length >= 5 && memcmp(name, ".svn/", 5) == 0)) return 0;
    size_t base = 0;
    for (size_t i = 0; i < length; i++) if (name[i] == '/') base = i + 1;
    size_t dot = length;
    for (size_t i = base; i < length; i++) if (name[i] == '.') dot = i + 1;
    if (dot >= length) {
        char basename[32];
        size_t baseLen = length - base;
        if (baseLen == 0 || baseLen >= sizeof basename) return 0;
        for (size_t i = 0; i < baseLen; i++) {
            unsigned char c = name[base + i];
            basename[i] = (char)((c >= 'A' && c <= 'Z') ? c + ('a' - 'A') : c);
        }
        basename[baseLen] = 0;
        return strcmp(basename, "dockerfile") == 0 || strcmp(basename, "makefile") == 0 ||
               strcmp(basename, "license") == 0 || strcmp(basename, "readme") == 0 ||
               strcmp(basename, "notice") == 0 || strcmp(basename, "gemfile") == 0 ||
               strcmp(basename, "rakefile") == 0 || strcmp(basename, "procfile") == 0;
    }
    char ext[16];
    size_t extLen = length - dot;
    if (extLen == 0 || extLen >= sizeof ext) return 0;
    for (size_t i = 0; i < extLen; i++) {
        unsigned char c = name[dot + i];
        ext[i] = (char)((c >= 'A' && c <= 'Z') ? c + ('a' - 'A') : c);
    }
    ext[extLen] = 0;
    static const char *allowed[] = {
        "txt","md","markdown","rst","text","json","jsonl","csv","tsv","xml","html","htm",
        "css","scss","less","js","jsx","ts","tsx","mjs","cjs","m","h","mm","hpp","hh",
        "cc","cpp","cxx","swift","py","pyi","java","kt","kts","go","rs","rb","php",
        "sh","bash","zsh","fish","yml","yaml","toml","ini","cfg","conf","plist","sql",
        "log","gradle","properties","env","gitignore","dockerfile","makefile","cmake","vue","svelte",
        "dart","lua","r","ipynb","patch","diff","proto","graphql","gql","tf","hcl","bat","ps1",
        "cs","fs","vb","scala","sc","pl","pm","ex","exs","erl","hrl","clj","cljs","cljc","edn"
    };
    for (size_t i = 0; i < sizeof allowed / sizeof allowed[0]; i++) {
        if (strcmp(ext, allowed[i]) == 0) return 1;
    }
    return 0;
}

static int zip_bytes_are_text_utf8(const unsigned char *bytes, size_t length) {
    if (!bytes || length == 0) return 0;
    size_t i = 0;
    while (i < length) {
        unsigned char c = bytes[i++];
        if (c == 0 || (c < 0x09) || (c > 0x0D && c < 0x20)) return 0;
        if (c < 0x80) continue;
        unsigned need = (c >= 0xC2 && c <= 0xDF) ? 1 :
                        (c >= 0xE0 && c <= 0xEF) ? 2 :
                        (c >= 0xF0 && c <= 0xF4) ? 3 : 99;
        if (need == 99 || i + need > length) return 0;
        unsigned char first = bytes[i];
        if ((c == 0xE0 && first < 0xA0) || (c == 0xED && first >= 0xA0) ||
            (c == 0xF0 && first < 0x90) || (c == 0xF4 && first >= 0x90)) return 0;
        for (unsigned j = 0; j < need; j++) if ((bytes[i + j] & 0xC0) != 0x80) return 0;
        i += need;
    }
    return 1;
}

char *office_zip_text(const unsigned char *zip, size_t zipLen, int *err) {
    int dummy;
    if (!err) err = &dummy;
    *err = OFFICE_OK;
    if (!zip || zipLen < 22) { *err = OFFICE_ERR_NOT_ZIP; return NULL; }

    long long minPos = (long long)zipLen - 22 - 65535;
    if (minPos < 0) minPos = 0;
    long long eocd = -1;
    for (long long i = (long long)zipLen - 22; i >= minPos; i--) {
        if (rd32(zip + i) == 0x06054b50u) { eocd = i; break; }
    }
    if (eocd < 0) { *err = OFFICE_ERR_NOT_ZIP; return NULL; }

    uint32_t total = rd16(zip + eocd + 10);
    uint32_t cdSize = rd32(zip + eocd + 12);
    uint32_t cdOff = rd32(zip + eocd + 16);
    if (total == 0xFFFFu || cdSize == 0xFFFFFFFFu || cdOff == 0xFFFFFFFFu) {
        *err = OFFICE_ERR_UNSUPPORTED; return NULL;
    }
    if (total > 10000 || (uint64_t)cdOff + cdSize > zipLen) { *err = OFFICE_ERR_NOT_ZIP; return NULL; }

    sb_t output = {0};
    const unsigned char *cursor = zip + cdOff;
    const unsigned char *end = cursor + cdSize;
    int sawOversizedText = 0;
    for (uint32_t index = 0; index < total; index++) {
        if ((size_t)(end - cursor) < 46 || rd32(cursor) != 0x02014b50u) {
            free(output.p); *err = OFFICE_ERR_NOT_ZIP; return NULL;
        }
        uint16_t flags = rd16(cursor + 8);
        uint16_t nameLen = rd16(cursor + 28);
        uint16_t extraLen = rd16(cursor + 30);
        uint16_t commentLen = rd16(cursor + 32);
        if ((size_t)(end - cursor) < (size_t)46 + nameLen + extraLen + commentLen) {
            free(output.p); *err = OFFICE_ERR_NOT_ZIP; return NULL;
        }
        uint32_t usize = rd32(cursor + 24);
        uint32_t csize = rd32(cursor + 20);
        uint32_t lho = rd32(cursor + 42);
        const unsigned char *name = cursor + 46;
        int textName = zip_name_is_text(name, nameLen);
        if (textName && usize > MAX_TEXT_BYTES) sawOversizedText = 1;
        int selected = !(flags & 1) && usize > 0 && usize <= MAX_TEXT_BYTES &&
                       csize != 0xFFFFFFFFu && usize != 0xFFFFFFFFu && lho != 0xFFFFFFFFu && textName;
        if (selected && output.len < MAX_TEXT_BYTES) {
            zip_entry entry;
            entry.method = rd16(cursor + 10);
            entry.csize = csize;
            entry.usize = usize;
            entry.lho = lho;
            unsigned char *contents = NULL;
            size_t contentsLen = 0;
            int readResult = read_entry(zip, zipLen, &entry, &contents, &contentsLen);
            if (readResult == OFFICE_OK && zip_bytes_are_text_utf8(contents, contentsLen)) {
                sb_put(&output, "\n\n===== ", sizeof("\n\n===== ") - 1);
                sb_put(&output, (const char *)name, nameLen);
                sb_put(&output, " =====\n", sizeof(" =====\n") - 1);
                sb_put(&output, (const char *)contents, contentsLen);
            }
            free(contents);
        }
        cursor += (size_t)46 + nameLen + extraLen + commentLen;
        if (output.overflow) break;
    }
    if (output.len == 0) {
        free(output.p);
        *err = sawOversizedText ? OFFICE_ERR_TOO_LARGE : OFFICE_ERR_MISSING_PART;
        return NULL;
    }
    if (output.overflow) { output.overflow = 0; sb_put(&output, "\n[ZIP text truncated at the safe extraction limit.]\n", sizeof("\n[ZIP text truncated at the safe extraction limit.]\n") - 1); }
    return finish(&output, err);
}

char *office_docx_text(const unsigned char *zip, size_t zipLen, int *err) {
    int dummy;
    if (!err) err = &dummy;
    *err = OFFICE_OK;
    if (!zip) { *err = OFFICE_ERR_NOT_ZIP; return NULL; }

    unsigned char *xml = NULL;
    size_t xmlLen = 0;
    int rc = load_part(zip, zipLen, "word/document.xml", &xml, &xmlLen);
    if (rc != OFFICE_OK) { *err = rc; return NULL; }

    sb_t sb = {0};
    extract_docx_xml((const char *)xml, xmlLen, &sb);
    free(xml);
    return finish(&sb, err);
}

char *office_pptx_text(const unsigned char *zip, size_t zipLen, int *err) {
    int dummy;
    if (!err) err = &dummy;
    *err = OFFICE_OK;
    if (!zip) { *err = OFFICE_ERR_NOT_ZIP; return NULL; }

    sb_t sb = {0};
    int slides = append_slides_in_order(zip, zipLen, &sb);

    if (slides == 0) {
        // Fall back to file-name order (slide1.xml, slide2.xml, ...) if the presentation index could not be read.
        for (int n = 1; n <= MAX_SLIDES; n++) {
            char path[64];
            snprintf(path, sizeof path, "ppt/slides/slide%d.xml", n);
            if (!append_slide(zip, zipLen, path, n, &sb)) break;
            slides++;
        }
    }
    if (slides == 0) {
        free(sb.p);
        // Distinguish "not a zip at all" from "a zip without slides".
        zip_entry probe;
        int rc = find_entry(zip, zipLen, "[Content_Types].xml", &probe);
        *err = (rc == OFFICE_ERR_NOT_ZIP || rc == OFFICE_ERR_UNSUPPORTED) ? rc : OFFICE_ERR_MISSING_PART;
        return NULL;
    }
    return finish(&sb, err);
}
