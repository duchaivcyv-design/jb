//! Raw DEFLATE decoder (RFC 1951). A port of the reference "puff" decoder that ships with zlib.
//!
//! The output size is fixed by the caller (the size declared in the ZIP header) and the decoder never writes past it,
//! so a lying header cannot overflow anything. Anything that does not decode to exactly that many bytes is rejected.

const MAXBITS: usize = 15;
const MAXLCODES: usize = 286;
const MAXDCODES: usize = 30;
const MAXCODES: usize = MAXLCODES + MAXDCODES;
const FIXLCODES: usize = 288;

static LENS: [u16; 29] = [
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258,
];
static LEXT: [u16; 29] = [
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0,
];
static DISTS: [u16; 30] = [
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
    8193, 12289, 16385, 24577,
];
static DEXT: [u16; 30] = [
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13,
];
static ORDER: [usize; 19] = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

struct Huffman {
    count: [u16; MAXBITS + 1],
    symbol: [u16; FIXLCODES],
}

impl Huffman {
    fn new() -> Huffman {
        Huffman { count: [0; MAXBITS + 1], symbol: [0; FIXLCODES] }
    }

    /// Builds the decoding tables from code lengths. Returns 0 for a complete code, > 0 for an incomplete one and
    /// < 0 for an over-subscribed one.
    fn construct(&mut self, length: &[u16]) -> i32 {
        let n = length.len();
        for c in self.count.iter_mut() {
            *c = 0;
        }
        for &l in length {
            self.count[l as usize] += 1;
        }
        if self.count[0] as usize == n {
            return 0;
        }
        let mut left: i32 = 1;
        for len in 1..=MAXBITS {
            left <<= 1;
            left -= self.count[len] as i32;
            if left < 0 {
                return left;
            }
        }
        let mut offs = [0u16; MAXBITS + 1];
        for len in 1..MAXBITS {
            offs[len + 1] = offs[len] + self.count[len];
        }
        for (sym, &l) in length.iter().enumerate() {
            if l != 0 {
                let o = offs[l as usize] as usize;
                self.symbol[o] = sym as u16;
                offs[l as usize] += 1;
            }
        }
        left
    }
}

struct Inflater<'a> {
    input: &'a [u8],
    incnt: usize,
    bitbuf: u32,
    bitcnt: u32,
    out: Vec<u8>,
    outcnt: usize,
}

impl<'a> Inflater<'a> {
    fn bits(&mut self, need: u32) -> Result<u32, ()> {
        let mut val = self.bitbuf;
        while self.bitcnt < need {
            if self.incnt >= self.input.len() {
                return Err(());
            }
            val |= (self.input[self.incnt] as u32) << self.bitcnt;
            self.incnt += 1;
            self.bitcnt += 8;
        }
        self.bitbuf = val >> need;
        self.bitcnt -= need;
        Ok(val & ((1u32 << need) - 1))
    }

    fn stored(&mut self) -> Result<(), ()> {
        self.bitbuf = 0;
        self.bitcnt = 0;
        if self.incnt + 4 > self.input.len() {
            return Err(());
        }
        let len = (self.input[self.incnt] as usize) | ((self.input[self.incnt + 1] as usize) << 8);
        let nlen = (self.input[self.incnt + 2] as usize) | ((self.input[self.incnt + 3] as usize) << 8);
        self.incnt += 4;
        if len != (!nlen & 0xFFFF) {
            return Err(());
        }
        if self.incnt + len > self.input.len() {
            return Err(());
        }
        if self.outcnt + len > self.out.len() {
            return Err(());
        }
        let (start, end) = (self.incnt, self.incnt + len);
        self.out[self.outcnt..self.outcnt + len].copy_from_slice(&self.input[start..end]);
        self.outcnt += len;
        self.incnt += len;
        Ok(())
    }

    fn decode(&mut self, h: &Huffman) -> Result<usize, ()> {
        let mut code: i32 = 0;
        let mut first: i32 = 0;
        let mut index: i32 = 0;
        for len in 1..=MAXBITS {
            code |= self.bits(1)? as i32;
            let count = h.count[len] as i32;
            if code - count < first {
                return Ok(h.symbol[(index + (code - first)) as usize] as usize);
            }
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }
        Err(())
    }

    fn codes(&mut self, lencode: &Huffman, distcode: &Huffman) -> Result<(), ()> {
        loop {
            let mut symbol = self.decode(lencode)?;
            if symbol < 256 {
                if self.outcnt >= self.out.len() {
                    return Err(());
                }
                self.out[self.outcnt] = symbol as u8;
                self.outcnt += 1;
            } else if symbol > 256 {
                symbol -= 257;
                if symbol >= 29 {
                    return Err(());
                }
                let len = LENS[symbol] as usize + self.bits(LEXT[symbol] as u32)? as usize;
                let ds = self.decode(distcode)?;
                if ds >= 30 {
                    return Err(());
                }
                let dist = DISTS[ds] as usize + self.bits(DEXT[ds] as u32)? as usize;
                if dist > self.outcnt || self.outcnt + len > self.out.len() {
                    return Err(());
                }
                for _ in 0..len {
                    self.out[self.outcnt] = self.out[self.outcnt - dist];
                    self.outcnt += 1;
                }
            } else {
                return Ok(());
            }
        }
    }

    fn fixed(&mut self) -> Result<(), ()> {
        let mut lengths = [0u16; FIXLCODES];
        for (i, l) in lengths.iter_mut().enumerate() {
            *l = if i < 144 {
                8
            } else if i < 256 {
                9
            } else if i < 280 {
                7
            } else {
                8
            };
        }
        let mut lencode = Huffman::new();
        lencode.construct(&lengths);
        let dlengths = [5u16; MAXDCODES];
        let mut distcode = Huffman::new();
        distcode.construct(&dlengths);
        self.codes(&lencode, &distcode)
    }

    fn dynamic(&mut self) -> Result<(), ()> {
        let nlen = self.bits(5)? as usize + 257;
        let ndist = self.bits(5)? as usize + 1;
        let ncode = self.bits(4)? as usize + 4;
        if nlen > MAXLCODES || ndist > MAXDCODES {
            return Err(());
        }
        let mut lengths = [0u16; MAXCODES];
        for index in 0..ncode {
            lengths[ORDER[index]] = self.bits(3)? as u16;
        }
        let mut clcode = Huffman::new();
        if clcode.construct(&lengths[..19]) != 0 {
            return Err(());
        }
        for l in lengths.iter_mut() {
            *l = 0;
        }
        let mut index = 0usize;
        while index < nlen + ndist {
            let symbol = self.decode(&clcode)?;
            if symbol < 16 {
                lengths[index] = symbol as u16;
                index += 1;
            } else {
                let mut len = 0u16;
                let rep: usize;
                if symbol == 16 {
                    if index == 0 {
                        return Err(());
                    }
                    len = lengths[index - 1];
                    rep = 3 + self.bits(2)? as usize;
                } else if symbol == 17 {
                    rep = 3 + self.bits(3)? as usize;
                } else {
                    rep = 11 + self.bits(7)? as usize;
                }
                if index + rep > nlen + ndist {
                    return Err(());
                }
                for _ in 0..rep {
                    lengths[index] = len;
                    index += 1;
                }
            }
        }
        if lengths[256] == 0 {
            return Err(());
        }
        let mut lencode = Huffman::new();
        let err = lencode.construct(&lengths[..nlen]);
        if err != 0 && (err < 0 || nlen != (lencode.count[0] + lencode.count[1]) as usize) {
            return Err(());
        }
        let mut distcode = Huffman::new();
        let err = distcode.construct(&lengths[nlen..nlen + ndist]);
        if err != 0 && (err < 0 || ndist != (distcode.count[0] + distcode.count[1]) as usize) {
            return Err(());
        }
        self.codes(&lencode, &distcode)
    }
}

/// Inflates a raw DEFLATE stream into exactly `out_size` bytes. Returns None for any malformed stream, for a stream
/// that would write more than `out_size` bytes and for one that produces fewer.
pub fn inflate_raw(input: &[u8], out_size: usize) -> Option<Vec<u8>> {
    let mut st = Inflater { input, incnt: 0, bitbuf: 0, bitcnt: 0, out: vec![0u8; out_size], outcnt: 0 };
    loop {
        let last = st.bits(1).ok()?;
        let kind = st.bits(2).ok()?;
        let r = match kind {
            0 => st.stored(),
            1 => st.fixed(),
            2 => st.dynamic(),
            _ => Err(()),
        };
        r.ok()?;
        if last == 1 {
            break;
        }
    }
    if st.outcnt != out_size {
        return None;
    }
    Some(st.out)
}
