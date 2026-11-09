// Harness of the LBM parity (issue #176): the real SDL_image 1.2.12 (IMG_Load) on IFF files.
//   lbmharness gen <seed> <count> <corpus.txt>   writes <count> pseudo random IFF files, one hex line each
//   lbmharness run <corpus.txt> <golden.txt>     what IMG_Load makes of each of them
//   lbmharness file <golden.txt> <file>...       the same for real files (the name is the base name)
#include <SDL.h>
#include <SDL_image.h>
#undef main
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <random>
#include <fstream>
#include <sstream>

typedef std::vector<unsigned char> Bytes;

static void Put32(Bytes &b, unsigned v) { b.push_back(v >> 24); b.push_back(v >> 16); b.push_back(v >> 8); b.push_back(v); }
static void Put16(Bytes &b, unsigned v) { b.push_back(v >> 8); b.push_back(v); }
static void PutId(Bytes &b, const char *id) { for (int i = 0; i < 4; ++i) b.push_back(id[i]); }

static void Chunk(Bytes &b, const char *id, const Bytes &data)
{
	PutId(b, id);
	Put32(b, (unsigned)data.size());
	b.insert(b.end(), data.begin(), data.end());
	if (data.size() & 1) b.push_back(0);
}

static Bytes Rle(const Bytes &row, std::mt19937 &r)
{
	Bytes out;
	size_t i = 0;
	while (i < row.size())
	{
		size_t run = 1;
		while (i + run < row.size() && row[i + run] == row[i] && run < 128) ++run;
		if (run > 1 && (r() & 3))
		{
			out.push_back((unsigned char)(257 - run));
			out.push_back(row[i]);
			i += run;
		}
		else
		{
			size_t n = 1 + r() % 5;
			if (i + n > row.size()) n = row.size() - i;
			out.push_back((unsigned char)(n - 1));
			for (size_t k = 0; k < n; ++k) out.push_back(row[i + k]);
			i += n;
		}
	}
	return out;
}

static std::string gInfo;
static Bytes MakeFile(std::mt19937 &r)
{
	bool pbm = (r() % 3) != 0;
	int w = 1 + r() % 40, h = 1 + r() % 20;
	int planes = pbm ? 8 : 1 + r() % 8;
	
	int masking = (r() % 4 == 0) ? (r() % 3) : 0;
	if (pbm && masking == 1) masking = 0; // not defined for SDL_image
	int comp = r() % 2;
	int trans = r() % 4;
	Bytes bmhd;
	Put16(bmhd, w); Put16(bmhd, h); Put16(bmhd, 0); Put16(bmhd, 0);
	bmhd.push_back(planes); bmhd.push_back(masking); bmhd.push_back(comp); bmhd.push_back(0);
	Put16(bmhd, trans); bmhd.push_back(10); bmhd.push_back(11); Put16(bmhd, w); Put16(bmhd, h);
	int ncol = (r() % 5 == 0) ? (int)(r() % 257) : (1 << planes);
	if (r() % 40 == 0) ncol = 257 + r() % 40;
	Bytes cmap;
	int cmapBytes = ncol * 3;
	for (int i = 0; i < cmapBytes; ++i) cmap.push_back(r());
	Bytes body;
	if (pbm && planes == 8)
	{
		int stride = (w + 15) & ~15;
		for (int y = 0; y < h; ++y)
		{
			Bytes row;
			for (int x = 0; x < stride; ++x) row.push_back(r() % ((r() % 3) ? 8 : 256));
			if (comp) { Bytes e = Rle(row, r); body.insert(body.end(), e.begin(), e.end()); }
			else body.insert(body.end(), row.begin(), row.end());
		}
	}
	else
	{
		int stride = ((w + 15) / 16) * 2;
		int total = planes + (masking == 1 ? 1 : 0);
		for (int y = 0; y < h; ++y)
			for (int p = 0; p < total; ++p)
			{
				Bytes row;
				for (int x = 0; x < stride; ++x) row.push_back(r());
				if (comp) { Bytes e = Rle(row, r); body.insert(body.end(), e.begin(), e.end()); }
				else body.insert(body.end(), row.begin(), row.end());
			}
	}
	Bytes inner;
	PutId(inner, pbm ? "PBM " : "ILBM");
	if (r() % 5 == 0) { Bytes x; int n = 1 + (int)(r() % 7); for (int i = 0; i < n; ++i) x.push_back(r()); Chunk(inner, "ANNO", x); }
	Chunk(inner, "BMHD", bmhd);
	if (r() % 10 != 0) Chunk(inner, "CMAP", cmap);
	if (r() % 6 == 0) { Bytes x(4, 0); Chunk(inner, "CAMG", x); }
	Chunk(inner, "BODY", body);
	Bytes f;
	PutId(f, "FORM");
	Put32(f, (unsigned)inner.size());
	f.insert(f.end(), inner.begin(), inner.end());
	int damage = r() % 14;
	{ std::ostringstream o; o << (pbm ? "pbm" : "ilbm") << " w" << w << " h" << h << " p" << planes << " m" << masking << " c" << comp << " n" << ncol << " cm" << cmapBytes << " d" << damage; gInfo = o.str(); }
	if (damage == 0) f.resize(8 + r() % 12);
	else if (damage == 1) f[0] = 'X';
	else if (damage == 2) { f[8] = 'Q'; }
	
	return f;
}

static std::string Hex(const Bytes &b)
{
	static const char *d = "0123456789abcdef";
	std::string s;
	for (size_t i = 0; i < b.size(); ++i) { s += d[b[i] >> 4]; s += d[b[i] & 15]; }
	return s;
}

static Bytes FromHex(const std::string &s)
{
	Bytes b;
	for (size_t i = 0; i + 1 < s.size(); i += 2) b.push_back((unsigned char)strtoul(s.substr(i, 2).c_str(), 0, 16));
	return b;
}

static void Describe(SDL_Surface *s, std::ostream &out)
{
	if (!s) { out << "ERR\n"; return; }
	out << s->w << ' ' << s->h << ' ' << (int)s->format->BitsPerPixel << ' ' << ((s->flags & SDL_SRCCOLORKEY) ? 1 : 0)
		<< ' ' << s->format->colorkey << ' ';
	if (s->format->palette)
	{
		out << s->format->palette->ncolors << ' ';
		char tmp[16];
		for (int i = 0; i < s->format->palette->ncolors; ++i)
		{
			SDL_Color *c = s->format->palette->colors + i;
			snprintf(tmp, sizeof tmp, "%02x%02x%02x", c->r, c->g, c->b);
			out << tmp;
		}
	}
	else out << "0 -";
	unsigned long long hash = 14695981039346656037ULL;
	if (s->format->BitsPerPixel == 8)
		for (int y = 0; y < s->h; ++y)
			for (int x = 0; x < s->w; ++x)
			{
				hash ^= ((unsigned char *)s->pixels)[y * s->pitch + x];
				hash *= 1099511628211ULL;
			}
	out << ' ' << hash << '\n';
}

int main(int argc, char **argv)
{
	std::string mode = argc > 1 ? argv[1] : "";
	if (mode == "gen" && argc == 5)
	{
		std::mt19937 r((unsigned)atoi(argv[2]));
		int n = atoi(argv[3]);
		std::ofstream out(argv[4], std::ios::binary);
		for (int i = 0; i < n; ++i) { Bytes f = MakeFile(r); out << Hex(f) << " " << gInfo << "\n"; }
		return 0;
	}
	if (mode == "run" && argc == 4)
	{
		std::ifstream in(argv[2]);
		std::ofstream out(argv[3], std::ios::binary);
		std::string line;
		while (std::getline(in, line))
		{
			Bytes b = FromHex(line);
			SDL_RWops *rw = SDL_RWFromConstMem(b.data(), (int)b.size());
			SDL_Surface *s = IMG_Load_RW(rw, 1);
			Describe(s, out);
			if (s) SDL_FreeSurface(s);
		}
		return 0;
	}
	if (mode == "pix" && argc == 4)
	{
		// the pixels of one file of a corpus, row by row (to understand a difference)
		std::ifstream in(argv[2]);
		std::string line;
		for (int i = 0; i <= atoi(argv[3]); ++i) std::getline(in, line);
		Bytes b = FromHex(line.substr(0, line.find(' ')));
		std::printf("%s\n", line.c_str() + line.find(' ') + 1);
		for (size_t i = 0; i < b.size(); ++i) std::printf("%02x%s", b[i], (i % 32 == 31) ? "\n" : "");
		std::printf("\n--\n");
		SDL_Surface *s = IMG_Load_RW(SDL_RWFromConstMem(b.data(), (int)b.size()), 1);
		if (!s) { std::printf("ERR\n"); return 0; }
		for (int y = 0; y < s->h; ++y)
		{
			for (int x = 0; x < s->w; ++x) std::printf("%02x ", ((unsigned char *)s->pixels)[y * s->pitch + x]);
			std::printf("\n");
		}
		return 0;
	}
	if (mode == "file" && argc >= 4)
	{
		std::ofstream out(argv[2], std::ios::binary);
		for (int i = 3; i < argc; ++i)
		{
			std::string p = argv[i];
			size_t k = p.find_last_of("/\\");
			out << (k == std::string::npos ? p : p.substr(k + 1)) << ' ';
			SDL_Surface *s = IMG_Load(argv[i]);
			Describe(s, out);
			if (s) SDL_FreeSurface(s);
		}
		return 0;
	}
	fprintf(stderr, "usage\n");
	return 1;
}
