// Parity harness of issue #98: runs the REAL idBitMsg / idBitMsgDelta (idlib\BitMsg.cpp) and the REAL
// idCompressor classes (framework\Compressor.cpp) of Doom 3 and writes their answers as text goldens.
// The Delphi tests (Tests\Source\DelphiDoom.Tests.Compression.Parity.pas and
// DelphiDoom.Tests.Net.BitMessage.Parity.pas) build the same scenarios and compare them line by line.
// Usage: harness <compression-golden> <bitmsg-golden>
#include "idlib/precompiled.h"
#include <map>

idCommon localCommon;
idCommon *common = &localCommon;

// every allocation is zeroed: the compressors keep uninitialised buffers that the Delphi port zeroes
void *operator new(size_t n) { void *p = calloc(1, n ? n : 1); if (!p) throw std::bad_alloc(); return p; }
void *operator new[](size_t n) { void *p = calloc(1, n ? n : 1); if (!p) throw std::bad_alloc(); return p; }
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }

#include "mathfn.inc"

static std::string hexs(const byte *p, int n) {
	static const char *d = "0123456789abcdef";
	std::string s;
	for (int i = 0; i < n; i++) { s += d[p[i] >> 4]; s += d[p[i] & 15]; }
	return s;
}

static unsigned crc32(const byte *p, int n) {
	unsigned c = 0xFFFFFFFFu;
	for (int i = 0; i < n; i++) {
		c ^= p[i];
		for (int k = 0; k < 8; k++) c = (c >> 1) ^ (0xEDB88320u & (0u - (c & 1)));
	}
	return ~c;
}

static unsigned fbits(float f) { unsigned u; memcpy(&u, &f, 4); return u; }

// ------------------------------------------------------------------ compressors

class MemFile : public idFile {
public:
	std::vector<byte> d;
	int pos;
	MemFile() : pos(0) {}
	int Read(void *buffer, int len) {
		int n = (int)d.size() - pos;
		if (n > len) n = len;
		if (n < 0) n = 0;
		if (n) memcpy(buffer, &d[pos], n);
		pos += n;
		return n;
	}
	int Write(const void *buffer, int len) {
		d.insert(d.end(), (const byte *)buffer, (const byte *)buffer + len);
		pos = (int)d.size();
		return len;
	}
	int Length(void) { return (int)d.size(); }
	int Tell(void) { return pos; }
	int Seek(long, fsOrigin_t) { return -1; }
};

struct Lcg {
	unsigned s;
	Lcg(unsigned seed) : s(seed) {}
	unsigned Byte() { s = s * 1664525u + 1013904223u; return s >> 24; }
};

static std::vector<byte> makeData(const std::string &kind) {
	std::vector<byte> v;
	if (kind == "text") {
		const char *ph = "the quick brown fox jumps over the lazy dog. ";
		int pl = (int)strlen(ph);
		for (int i = 0; i < 1500; i++) v.push_back((byte)ph[i % pl]);
	} else if (kind == "zeros") {
		v.assign(3000, 0);
	} else if (kind == "ones") {
		v.assign(700, 0xFF);
	} else if (kind == "runs") {
		Lcg r(1);
		while (v.size() < 4000) {
			byte b = (byte)r.Byte();
			unsigned len = 1 + r.Byte() % 40;
			for (unsigned i = 0; i < len; i++) v.push_back(b);
		}
	} else if (kind == "random") {
		Lcg r(2);
		for (int i = 0; i < 3000; i++) v.push_back((byte)r.Byte());
	} else if (kind == "sparse") {
		Lcg r(3);
		for (int i = 0; i < 6000; i++) {
			unsigned t = r.Byte();
			byte b = (byte)r.Byte();
			v.push_back(t % 8 == 0 ? b : 0);
		}
	} else if (kind == "mixed") {
		Lcg r(4);
		for (int i = 0; i < 10000; i++) v.push_back(0);
		for (int i = 0; i < 10000; i++) v.push_back((byte)r.Byte());
	} else if (kind == "big") {
		Lcg r(5);
		while (v.size() < 70000) {
			unsigned t = r.Byte();
			if (v.size() > 100 && t % 4 == 0) {
				unsigned hi = r.Byte();
				unsigned lo = r.Byte();
				unsigned off = (hi * 256 + lo) % (unsigned)(v.size() - 40);
				unsigned len = 20 + r.Byte() % 41;
				for (unsigned i = 0; i < len; i++) v.push_back(v[off + i]);
			} else {
				unsigned b = r.Byte();
				v.push_back((byte)('a' + (b >> 5)));
			}
		}
		v.resize(70000);
	}
	return v;
}

struct Case { const char *name, *kind, *comp; int wl, wchunk, rchunk; };

static idCompressor *alloc(const std::string &c) {
	if (c == "none") return idCompressor::AllocNoCompression();
	if (c == "bit") return idCompressor::AllocBitStream();
	if (c == "rle") return idCompressor::AllocRunLength();
	if (c == "rlz") return idCompressor::AllocRunLength_ZeroBased();
	if (c == "huff") return idCompressor::AllocHuffman();
	if (c == "arith") return idCompressor::AllocArithmetic();
	if (c == "lzss") return idCompressor::AllocLZSS();
	if (c == "lzssw") return idCompressor::AllocLZSS_WordAligned();
	if (c == "lzw") return idCompressor::AllocLZW();
	return NULL;
}

// the table is repeated in Tests\Source\DelphiDoom.Tests.Compression.Parity.pas
static const Case cases[] = {
	{ "none-random", "random", "none", 8, 0, 0 },
	{ "bit-text", "text", "bit", 8, 0, 0 },
	{ "bit-random-chunked", "random", "bit", 8, 777, 500 },
	{ "rle8-runs", "runs", "rle", 8, 0, 0 },
	{ "rle8-zeros", "zeros", "rle", 8, 0, 0 },
	{ "rle8-ones", "ones", "rle", 8, 0, 0 },
	{ "rle8-text-chunked", "text", "rle", 8, 500, 0 },
	{ "rle4-runs", "runs", "rle", 4, 0, 0 },
	{ "rle5-random", "random", "rle", 5, 0, 0 },
	{ "rle16-zeros", "zeros", "rle", 16, 0, 0 },
	{ "rlz8-sparse", "sparse", "rlz", 8, 0, 0 },
	{ "rlz8-zeros", "zeros", "rlz", 8, 0, 0 },
	{ "rlz4-sparse", "sparse", "rlz", 4, 0, 0 },
	{ "huff-text", "text", "huff", 8, 0, 0 },
	{ "huff-random", "random", "huff", 8, 0, 0 },
	{ "huff-mixed", "mixed", "huff", 8, 0, 0 },
	{ "huff-big-chunked", "big", "huff", 8, 3000, 777 },
	{ "arith-text", "text", "arith", 8, 0, 0 },
	{ "arith-random", "random", "arith", 8, 0, 0 },
	{ "arith-mixed", "mixed", "arith", 8, 0, 0 },
	{ "lzss8-text", "text", "lzss", 8, 0, 0 },
	{ "lzss8-runs", "runs", "lzss", 8, 0, 0 },
	{ "lzss8-big", "big", "lzss", 8, 0, 0 },
	{ "lzss8-big-chunked", "big", "lzss", 8, 4096, 5000 },
	{ "lzss4-runs", "runs", "lzss", 4, 0, 0 },
	{ "lzss16-text", "text", "lzss", 16, 0, 0 },
	{ "lzssw8-text", "text", "lzssw", 8, 0, 0 },
	{ "lzssw8-big", "big", "lzssw", 8, 0, 0 },
	{ "lzssw4-runs", "runs", "lzssw", 4, 0, 0 },
	{ "lzw-text", "text", "lzw", 8, 0, 0 },
	{ "lzw-random", "random", "lzw", 8, 0, 0 },
	{ "lzw-big", "big", "lzw", 8, 0, 0 },
	{ "lzw-big-chunked", "big", "lzw", 8, 1000, 3000 },
};

static void runCompressors(FILE *f) {
	for (size_t ci = 0; ci < sizeof(cases) / sizeof(cases[0]); ci++) {
		const Case &c = cases[ci];
		std::vector<byte> data = makeData(c.kind);
		int n = (int)data.size();
		MemFile out;
		idCompressor *comp = alloc(c.comp);
		comp->Init(&out, true, c.wl);
		int wc = c.wchunk ? c.wchunk : n;
		for (int p = 0; p < n; p += wc) {
			int k = std::min(wc, n - p);
			comp->Write(&data[p], k);
		}
		comp->FinishCompress();
		float ratio = comp->GetCompressionRatio();
		delete comp;

		MemFile in;
		in.d = out.d;
		comp = alloc(c.comp);
		comp->Init(&in, false, c.wl);
		std::vector<byte> back(n + 16, 0);
		int rc = c.rchunk ? c.rchunk : n;
		for (int p = 0; p < n; p += rc) {
			int k = std::min(rc, n - p);
			int got = comp->Read(&back[p], k);
			if (got <= 0) break;
		}
		delete comp;
		int clen = (int)out.d.size();
		fprintf(f, "C|%s|%d|%08x|%08x|%d|%08x|%s\n", c.name, clen, crc32(out.d.empty() ? (const byte *)"" : &out.d[0], clen),
			fbits(ratio), memcmp(&back[0], &data[0], n) == 0 ? 1 : 0, crc32(&back[0], n),
			clen <= 1100 ? hexs(&out.d[0], clen).c_str() : "-");
	}
}

// ------------------------------------------------------------------ bit messages

static std::vector<std::string> L;

static void put(const char *fmt, ...) {
	char buf[2048];
	va_list a; va_start(a, fmt); vsnprintf(buf, sizeof(buf), fmt, a); va_end(a);
	L.push_back(buf);
}

static void dumpMsg(const char *tag, const idBitMsg &m) {
	put("%s.hex %s", tag, hexs(m.GetData(), m.GetSize()).c_str());
	put("%s.size %d", tag, m.GetSize());
	put("%s.bits %d", tag, m.GetNumBitsWritten());
}

static std::string dictText(const idDict &d) {
	std::string s;
	for (int i = 0; i < d.GetNumKeyVals(); i++) {
		const idKeyValue *kv = d.GetKeyVal(i);
		s += std::string(kv->GetKey()) + "=" + std::string(kv->GetValue()) + ";";
	}
	return hexs((const byte *)s.c_str(), (int)s.size());
}

static void scenarioBasic() {
	put("[basic]");
	byte buf[512];
	memset(buf, 0, sizeof(buf));
	idBitMsg m;
	m.Init(buf, sizeof(buf));
	m.BeginWriting();
	m.WriteBits(5, 3);
	m.WriteBits(-3, -4);
	m.WriteChar(-100);
	m.WriteByte(200);
	m.WriteShort(-12345);
	m.WriteUShort(54321);
	m.WriteLong(-123456789);
	m.WriteFloat(3.14159f);
	m.WriteFloat(0.75f, 5, 10);
	m.WriteFloat(-123.5f, 8, 23);
	m.WriteAngle8(90.0f);
	m.WriteAngle16(-45.5f);
	m.WriteDir(idVec3(0.267261f, 0.534522f, 0.801784f), 30);
	m.WriteDir(idVec3(-0.6f, 0.0f, -0.8f), 24);
	m.WriteBits(1, 1);
	m.WriteString("Hello %d w\xF6rld");
	m.WriteString("abcdef", 4);
	m.WriteString("raw\xE9", -1, false);
	m.WriteString("");
	const byte d5[5] = { 1, 2, 3, 250, 255 };
	m.WriteData(d5, 5);
	netadr_t adr; adr.type = NA_IP; adr.ip[0] = 192; adr.ip[1] = 168; adr.ip[2] = 1; adr.ip[3] = 2; adr.port = 27666;
	m.WriteNetadr(adr);
	m.WriteDeltaChar(5, 5);
	m.WriteDeltaChar(5, -9);
	m.WriteDeltaByte(7, 200);
	m.WriteDeltaShort(100, -300);
	m.WriteDeltaLong(1, 1);
	m.WriteDeltaLong(1, 1000000);
	m.WriteDeltaFloat(1.0f, 2.0f);
	m.WriteDeltaFloat(1.5f, 1.5f, 5, 10);
	m.WriteDeltaFloat(1.5f, 2.5f, 5, 10);
	m.WriteDeltaByteCounter(0x12, 0x1F);
	m.WriteDeltaByteCounter(0x12, 0x12);
	m.WriteDeltaShortCounter(0x1234, 0x1F34);
	m.WriteDeltaLongCounter(0x12345678, 0x12355678);
	idDict d1, base;
	d1.Set("classname", "light"); d1.Set("origin", "1 2 3"); d1.Set("Same", "Value");
	base.Set("CLASSNAME", "LIGHT"); base.Set("gone", "x"); base.Set("same", "value");
	bool c1 = m.WriteDeltaDict(d1, &base);
	bool c2 = m.WriteDeltaDict(d1, NULL);
	put("dictchanged %d %d", c1 ? 1 : 0, c2 ? 1 : 0);
	dumpMsg("w", m);
	put("remainingspace %d writebit %d", m.GetRemainingSpace(), m.GetWriteBit());

	m.BeginReading();
	put("r.bits %d", m.ReadBits(3));
	put("r.sbits %d", m.ReadBits(-4));
	put("r.char %d", m.ReadChar());
	put("r.byte %d", m.ReadByte());
	put("r.short %d", m.ReadShort());
	put("r.ushort %d", m.ReadUShort());
	put("r.long %d", m.ReadLong());
	put("r.float %08x", fbits(m.ReadFloat()));
	put("r.float510 %08x", fbits(m.ReadFloat(5, 10)));
	put("r.float823 %08x", fbits(m.ReadFloat(8, 23)));
	put("r.angle8 %08x", fbits(m.ReadAngle8()));
	put("r.angle16 %08x", fbits(m.ReadAngle16()));
	idVec3 v = m.ReadDir(30);
	put("r.dir30 %08x %08x %08x", fbits(v.x), fbits(v.y), fbits(v.z));
	v = m.ReadDir(24);
	put("r.dir24 %08x %08x %08x", fbits(v.x), fbits(v.y), fbits(v.z));
	put("r.bit %d", m.ReadBits(1));
	char sb[64];
	int l = m.ReadString(sb, sizeof(sb)); put("r.str %d %s", l, hexs((byte *)sb, l).c_str());
	l = m.ReadString(sb, sizeof(sb)); put("r.str %d %s", l, hexs((byte *)sb, l).c_str());
	l = m.ReadString(sb, sizeof(sb)); put("r.str %d %s", l, hexs((byte *)sb, l).c_str());
	l = m.ReadString(sb, 3); put("r.str %d %s", l, hexs((byte *)sb, l).c_str());
	byte rd[5];
	int rdn = m.ReadData(rd, 5);
	put("r.data %d %s", rdn, hexs(rd, 5).c_str());
	netadr_t ra; m.ReadNetadr(&ra);
	put("r.netadr %d.%d.%d.%d:%d", ra.ip[0], ra.ip[1], ra.ip[2], ra.ip[3], ra.port);
	put("r.dchar %d", m.ReadDeltaChar(5));
	put("r.dchar %d", m.ReadDeltaChar(5));
	put("r.dbyte %d", m.ReadDeltaByte(7));
	put("r.dshort %d", m.ReadDeltaShort(100));
	put("r.dlong %d", m.ReadDeltaLong(1));
	put("r.dlong %d", m.ReadDeltaLong(1));
	put("r.dfloat %08x", fbits(m.ReadDeltaFloat(1.0f)));
	put("r.dfloat510 %08x", fbits(m.ReadDeltaFloat(1.5f, 5, 10)));
	put("r.dfloat510 %08x", fbits(m.ReadDeltaFloat(1.5f, 5, 10)));
	put("r.dbc %d", m.ReadDeltaByteCounter(0x12));
	put("r.dbc %d", m.ReadDeltaByteCounter(0x12));
	put("r.dsc %d", m.ReadDeltaShortCounter(0x1234));
	put("r.dlc %d", m.ReadDeltaLongCounter(0x12345678));
	idDict r1, r2;
	bool rc1 = m.ReadDeltaDict(r1, &base);
	bool rc2 = m.ReadDeltaDict(r2, NULL);
	put("r.dict1 %d %s", rc1 ? 1 : 0, dictText(r1).c_str());
	put("r.dict2 %d %s", rc2 ? 1 : 0, dictText(r2).c_str());
	put("r.remaining bits %d bytes %d count %d bit %d", m.GetRemainingReadBits(), m.GetRemaingData(), m.GetReadCount(), m.GetReadBit());
	put("r.pastend %d", m.ReadBits(8));
	put("r.readdata %d", m.ReadData(NULL, 10));

	// direction coding, static
	int bits = idBitMsg::DirToBits(idVec3(0.0f, -1.0f, 0.0f), 18);
	idVec3 bd = idBitMsg::BitsToDir(bits, 18);
	put("dir.bits %08x back %08x %08x %08x", bits, fbits(bd.x), fbits(bd.y), fbits(bd.z));
}

static void scenarioState() {
	put("[state]");
	byte buf[16];
	memset(buf, 0xAA, sizeof(buf));
	idBitMsg m;
	m.Init(buf, sizeof(buf));
	m.BeginWriting();
	m.WriteBits(0x7FF, 11);
	int s, b;
	m.SaveWriteState(s, b);
	put("saved %d %d", s, b);
	m.WriteBits(0xFFFF, 16);
	put("after %d %d bits %d", m.GetSize(), m.GetWriteBit(), m.GetNumBitsWritten());
	m.RestoreWriteState(s, b);
	put("restored %d %d bits %d remaining %d", m.GetSize(), m.GetWriteBit(), m.GetNumBitsWritten(), m.GetRemainingWriteBits());
	m.WriteBits(0, 2);
	dumpMsg("w", m);
	m.SetWriteBit(3);
	dumpMsg("w3", m);
	m.SetSize(100);
	put("size %d max %d", m.GetSize(), m.GetMaxSize());
	m.SetSize(2);
	m.BeginReading();
	put("a %d", m.ReadBits(5));
	int c, rb; m.SaveReadState(c, rb);
	put("readstate %d %d", c, rb);
	put("b %d", m.ReadBits(7));
	m.RestoreReadState(c, rb);
	put("b2 %d", m.ReadBits(7));
	m.SetReadBit(9);
	put("rbit %d", m.GetReadBit());
	m.ReadByteAlign();
	put("numread %d", m.GetNumBitsRead());
	put("big %d", m.ReadBits(32));
	put("signed31 %d", m.ReadBits(-31));
	m.BeginReading();
	put("signed12 %d", m.ReadBits(-12));
}

static void scenarioOverflow() {
	put("[overflow]");
	byte buf[4];
	memset(buf, 0, sizeof(buf));
	idBitMsg m;
	m.Init(buf, sizeof(buf));
	m.SetAllowOverflow(true);
	m.BeginWriting();
	m.WriteByte(1); m.WriteByte(2); m.WriteByte(3);
	m.WriteLong(0x04030201);
	put("overflowed %d size %d bits %d", m.IsOverflowed() ? 1 : 0, m.GetSize(), m.GetNumBitsWritten());
	m.WriteByte(300);
	dumpMsg("w", m);
	m.BeginWriting();
	put("overflowed after begin %d", m.IsOverflowed() ? 1 : 0);
	// errors
	idBitMsg e;
	byte eb[4]; memset(eb, 0, 4);
	e.Init(eb, 4);
	e.BeginWriting();
	try { e.WriteBits(1, 0); put("err none"); } catch (std::runtime_error &) { put("err badbits0"); }
	try { e.WriteBits(1, 33); put("err none"); } catch (std::runtime_error &) { put("err badbits33"); }
	try { e.WriteBits(1, -32); put("err none"); } catch (std::runtime_error &) { put("err badbits-32"); }
	e.WriteLong(1);
	try { e.WriteBits(1, 1); put("err none"); } catch (std::runtime_error &) { put("err overflow"); }
	try { e.ReadBits(0); put("err none"); } catch (std::runtime_error &) { put("err readbits0"); }
	// read only
	const byte ro[3] = { 0xA5, 0x5A, 0xFF };
	idBitMsg r;
	r.Init(ro, 3);
	r.SetSize(3);
	r.BeginReading();
	int ro1 = r.ReadByte();
	int ro2 = r.ReadBits(4);
	int ro3 = r.ReadBits(4);
	int ro4 = r.ReadBits(9);
	put("ro %d %d %d %d", ro1, ro2, ro3, ro4);
	put("ro.remaining %d", r.GetRemainingReadBits());
	put("ro.past %d", r.ReadBits(16));
	try { r.WriteBits(1, 1); put("err none"); } catch (std::runtime_error &) { put("err readonly"); }
}

// the sequence of fields of the delta scenario: set 0 is the first state, set 1 the second
struct Fields {
	int lng; const char *str; byte data[3]; int byte_; int shrt; float fl; int dshort_old, dshort_new;
	int dlong_old, dlong_new; int bc_old, bc_new; int sc_old, sc_new; int lc_old, lc_new;
	const char *key2; const char *val2;
};
static const Fields sets[2] = {
	{ 100, "alpha", { 1, 2, 3 }, 5, -7, 1.5f, 10, 12, 1000, 1000, 3, 4, 300, 301, 70, 71, "b", "2" },
	{ 100, "beta", { 1, 2, 4 }, 5, -8, 2.5f, 12, 12, 1000, 2000, 4, 4, 301, 302, 71, 72, "b", "3" },
};

static void writeFields(idBitMsgDelta &d, const Fields &f) {
	d.WriteLong(f.lng);
	d.WriteString(f.str);
	d.WriteData(f.data, 3);
	d.WriteByte(f.byte_);
	d.WriteShort(f.shrt);
	d.WriteFloat(f.fl);
	d.WriteDeltaShort(f.dshort_old, f.dshort_new);
	d.WriteDeltaLong(f.dlong_old, f.dlong_new);
	d.WriteDeltaByteCounter(f.bc_old, f.bc_new);
	d.WriteDeltaShortCounter(f.sc_old, f.sc_new);
	d.WriteDeltaLongCounter(f.lc_old, f.lc_new);
	idDict dict;
	dict.Set("a", "1"); dict.Set(f.key2, f.val2);
	d.WriteDict(dict);
	d.WriteAngle8(45.0f);
	d.WriteDir(idVec3(0.0f, 0.0f, 1.0f), 15);
}

static void readFields(const char *tag, idBitMsgDelta &d, const Fields &f) {
	put("%s.long %d", tag, d.ReadLong());
	char sb[64]; d.ReadString(sb, sizeof(sb)); put("%s.str %s", tag, hexs((byte *)sb, (int)strlen(sb)).c_str());
	byte rd[3]; d.ReadData(rd, 3); put("%s.data %s", tag, hexs(rd, 3).c_str());
	put("%s.byte %d", tag, d.ReadByte());
	put("%s.short %d", tag, d.ReadShort());
	put("%s.float %08x", tag, fbits(d.ReadFloat()));
	put("%s.dshort %d", tag, d.ReadDeltaShort(f.dshort_old));
	put("%s.dlong %d", tag, d.ReadDeltaLong(f.dlong_old));
	put("%s.bc %d", tag, d.ReadDeltaByteCounter(f.bc_old));
	put("%s.sc %d", tag, d.ReadDeltaShortCounter(f.sc_old));
	put("%s.lc %d", tag, d.ReadDeltaLongCounter(f.lc_old));
	idDict dict; d.ReadDict(dict); put("%s.dict %s", tag, dictText(dict).c_str());
	put("%s.angle %08x", tag, fbits(d.ReadAngle8()));
	idVec3 v = d.ReadDir(15); put("%s.dir %08x %08x %08x", tag, fbits(v.x), fbits(v.y), fbits(v.z));
	put("%s.changed %d", tag, d.HasChanged() ? 1 : 0);
}

static void scenarioDelta() {
	put("[delta]");
	byte b0[256], b1[256], b2[256], b3[256], b4[256];
	memset(b0, 0, 256); memset(b1, 0, 256); memset(b2, 0, 256); memset(b3, 0, 256); memset(b4, 0, 256);
	idBitMsg newBase0, delta0, newBase1, delta1;
	newBase0.Init(b0, 256); delta0.Init(b1, 256); newBase1.Init(b2, 256); delta1.Init(b3, 256);
	newBase0.BeginWriting(); delta0.BeginWriting(); newBase1.BeginWriting(); delta1.BeginWriting();

	// first state, no base
	idBitMsgDelta w0;
	w0.Init(NULL, &newBase0, &delta0);
	writeFields(w0, sets[0]);
	put("w0.changed %d", w0.HasChanged() ? 1 : 0);
	dumpMsg("w0.delta", delta0);
	dumpMsg("w0.newbase", newBase0);

	// second state against the first
	newBase0.BeginReading();
	idBitMsgDelta w1;
	w1.Init(&newBase0, &newBase1, &delta1);
	writeFields(w1, sets[1]);
	put("w1.changed %d", w1.HasChanged() ? 1 : 0);
	dumpMsg("w1.delta", delta1);
	dumpMsg("w1.newbase", newBase1);

	// reading the second delta against the first state
	newBase0.BeginReading();
	delta1.BeginReading();
	idBitMsg newBase2;
	newBase2.Init(b4, 256);
	newBase2.BeginWriting();
	idBitMsgDelta r1;
	r1.Init(&newBase0, &newBase2, (const idBitMsg *)&delta1);
	readFields("r1", r1, sets[1]);
	dumpMsg("r1.newbase", newBase2);

	// reading the first delta without base
	delta0.BeginReading();
	idBitMsgDelta r0;
	r0.Init(NULL, NULL, (const idBitMsg *)&delta0);
	readFields("r0", r0, sets[0]);

	// writing the same state again against itself: nothing changed
	byte b5[256], b6[256]; memset(b5, 0, 256); memset(b6, 0, 256);
	idBitMsg nb, dl; nb.Init(b5, 256); dl.Init(b6, 256); nb.BeginWriting(); dl.BeginWriting();
	newBase1.BeginReading();
	idBitMsgDelta w2;
	w2.Init(&newBase1, &nb, &dl);
	writeFields(w2, sets[1]);
	put("w2.changed %d", w2.HasChanged() ? 1 : 0);
	dumpMsg("w2.delta", dl);
}

int main(int argc, char **argv) {
	if (argc < 3) { fprintf(stderr, "usage: harness compression.txt bitmsg.txt\n"); return 2; }
	FILE *f = fopen(argv[1], "wb");
	runCompressors(f);
	fclose(f);
	scenarioBasic();
	scenarioState();
	scenarioOverflow();
	scenarioDelta();
	f = fopen(argv[2], "wb");
	for (size_t i = 0; i < L.size(); i++) fprintf(f, "%s\n", L[i].c_str());
	fclose(f);
	return 0;
}
