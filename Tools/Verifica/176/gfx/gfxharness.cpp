// Harness of the SDL_gfx parity (issue #176): the real SDL 1.2.15 and SDL_gfx (libSDL_gfx.a of the OpenXcom
// dependencies) called as Surface::drawLine, drawCircle, drawPolygon, drawTexturedPolygon and drawString do
// (Palette::getRGBA of the palette color, on a surface of 8 bits with color key 0).
//   gfxharness gen <seed> <count> <script.txt>   random cases, one per line
//   gfxharness run <script.txt> <golden.txt>     the FNV-1a of the pixels after every case
// A case: W H palhex pixhex | TW TH tpalhex tpixhex | op;op;...   (TW = 0: no texture)
//   L x1 y1 x2 y2 color | C x y r color | G color n x y x y ... | T n x y x y ... dx dy | S x y color texthex
#undef main
#include <SDL.h>
#include <SDL_gfxPrimitives.h>
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

static Uint32 GetRGBA(SDL_Color *pal, Uint8 color)
{
	return ((Uint32)pal[color].r << 24) | ((Uint32)pal[color].g << 16) | ((Uint32)pal[color].b << 8) | (Uint32)0xFF;
}

static SDL_Surface *MakeSurface(int w, int h, const Bytes &pal, const Bytes &pix)
{
	SDL_Surface *s = SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 8, 0, 0, 0, 0);
	SDL_Color colors[256];
	for (int i = 0; i < 256; ++i)
	{
		int m = (int)(pal.size() / 3);
		colors[i].r = pal[(i % m) * 3]; colors[i].g = pal[(i % m) * 3 + 1]; colors[i].b = pal[(i % m) * 3 + 2]; colors[i].unused = 255;
	}
	SDL_SetColors(s, colors, 0, 256);
	SDL_SetColorKey(s, SDL_SRCCOLORKEY, 0);
	for (int y = 0; y < h; ++y) memcpy((Uint8 *)s->pixels + y * s->pitch, &pix[y * w], w);
	return s;
}

static unsigned long long Fnv(SDL_Surface *s)
{
	unsigned long long hash = 14695981039346656037ULL;
	for (int y = 0; y < s->h; ++y)
		for (int x = 0; x < s->w; ++x)
		{
			hash ^= ((unsigned char *)s->pixels)[y * s->pitch + x];
			hash *= 1099511628211ULL;
		}
	return hash;
}

// The palette of a case is the first colors of the file repeated up to 256 (so colors repeat, as in real palettes)
static Bytes RandomPalette(std::mt19937 &r)
{
	static const int sizes[] = { 2, 4, 16, 64, 256 };
	int m = sizes[r() % 5];
	if (m == 256) m = 128;
	Bytes p(m * 3);
	int kind = r() % 3;
	for (int i = 0; i < m; ++i)
		for (int c = 0; c < 3; ++c)
			p[i * 3 + c] = (kind == 0) ? (int)(r() % 256) : (kind == 1 ? (int)(r() % 4) * 85 : (int)((r() % 4) * 64 + (i * 7) % 8));
	return p;
}
static int Coord(std::mt19937 &r, int size)
{
	int k = r() % 20;
	if (k == 0) return (int)(r() % 1001) - 500;
	if (k == 1) return (int)(r() % 65536) - 32768;
	return (int)(r() % (size + 30)) - 15;
}

static std::string MakeCase(std::mt19937 &r)
{
	int w = 1 + r() % 24, h = 1 + r() % 16;
	Bytes pal = RandomPalette(r);
	Bytes pix(w * h);
	for (size_t i = 0; i < pix.size(); ++i) pix[i] = (r() % 3) ? (r() % 8) : (r() % 256);
	std::ostringstream o;
	o << w << ' ' << h << ' ' << Hex(pal) << ' ' << Hex(pix) << " | ";
	int tw = 0, th = 0;
	if (r() % 2)
	{
		tw = 1 + r() % 12; th = 1 + r() % 10;
		Bytes tpal = (r() % 4 == 0) ? pal : RandomPalette(r);
		Bytes tpix(tw * th);
		for (size_t i = 0; i < tpix.size(); ++i) tpix[i] = (r() % 4) ? (r() % 256) : 0;
		o << tw << ' ' << th << ' ' << Hex(tpal) << ' ' << Hex(tpix);
	}
	else o << "0 0 - -";
	o << " | ";
	int ops = 1 + r() % 8;
	for (int i = 0; i < ops; ++i)
	{
		int c = r() % 256;
		int k = r() % 10;
		if (k < 3)
		{
			int small = r() % 4;
			int lim = small ? 100 : 1000;
			auto cc = [&](int sz) { return small ? Coord(r, sz) : (int)(r() % (2 * lim)) - lim; };
			if (r() % 10 == 0) o << "L " << cc(w) << ' ' << cc(h) << ' ' << cc(w) << ' ' << cc(h) << ' ' << c << ";";
			else o << "L " << Coord(r, w) % 200 << ' ' << Coord(r, h) % 200 << ' ' << Coord(r, w) % 200 << ' ' << Coord(r, h) % 200 << ' ' << c << ";";
		}
		else if (k < 5)
		{
			int rad = (r() % 8 == 0) ? (int)(r() % 65536) - 32768 : (int)(r() % 40) - 2;
			int x = (r() % 12 == 0) ? (int)(r() % 65536) - 32768 : Coord(r, w);
			int y = (r() % 12 == 0) ? (int)(r() % 65536) - 32768 : Coord(r, h);
			o << "C " << x << ' ' << y << ' ' << rad << ' ' << c << ";";
		}
		else if (k < 7 || (k < 9 && tw == 0))
		{
			int n = 2 + r() % 6;
			o << "G " << c << ' ' << n;
			for (int p = 0; p < n; ++p) o << ' ' << (int)(r() % (w + 40)) - 20 << ' ' << (int)(r() % (h + 40)) - 20;
			o << ";";
		}
		else if (k < 9)
		{
			int n = 2 + r() % 6;
			o << "T " << n;
			for (int p = 0; p < n; ++p) o << ' ' << (int)(r() % (w + 40)) - 20 << ' ' << (int)(r() % (h + 40)) - 20;
			o << ' ' << (int)(r() % 80) - 40 << ' ' << (int)(r() % 80) - 40 << ";";
		}
		else
		{
			Bytes text;
			int len = r() % 9;
			for (int p = 0; p < len; ++p) { int ch = 1 + r() % 255; text.push_back(ch); }
			int x = (r() % 12 == 0) ? (int)(r() % 65536) - 32768 : Coord(r, w);
			int y = (r() % 12 == 0) ? (int)(r() % 65536) - 32768 : Coord(r, h);
			o << "S " << x << ' ' << y << ' ' << c << ' ' << (text.empty() ? std::string("-") : Hex(text)) << ";";
		}
	}
	return o.str();
}

static std::string RunCase(const std::string &line)
{
	std::istringstream in(line);
	int w, h, tw, th;
	std::string palhex, pixhex, bar, tpal, tpix;
	in >> w >> h >> palhex >> pixhex >> bar >> tw >> th >> tpal >> tpix >> bar;
	SDL_Surface *dst = MakeSurface(w, h, FromHex(palhex), FromHex(pixhex));
	SDL_Surface *tex = tw ? MakeSurface(tw, th, FromHex(tpal), FromHex(tpix)) : 0;
	std::string rest;
	std::getline(in, rest);
	std::istringstream ops(rest);
	std::string op;
	while (std::getline(ops, op, ';'))
	{
		std::istringstream o(op);
		std::string k;
		if (!(o >> k)) continue;
		if (k == "L")
		{
			int x1, y1, x2, y2, c; o >> x1 >> y1 >> x2 >> y2 >> c;
			lineColor(dst, (Sint16)x1, (Sint16)y1, (Sint16)x2, (Sint16)y2, GetRGBA(dst->format->palette->colors, c));
		}
		else if (k == "C")
		{
			int x, y, r, c; o >> x >> y >> r >> c;
			filledCircleColor(dst, (Sint16)x, (Sint16)y, (Sint16)r, GetRGBA(dst->format->palette->colors, c));
		}
		else if (k == "G" || k == "T")
		{
			int c = 0, n;
			if (k == "G") o >> c;
			o >> n;
			std::vector<Sint16> vx(n), vy(n);
			for (int i = 0; i < n; ++i) { int x, y; o >> x >> y; vx[i] = x; vy[i] = y; }
			if (k == "G") filledPolygonColor(dst, &vx[0], &vy[0], n, GetRGBA(dst->format->palette->colors, c));
			else { int dx, dy; o >> dx >> dy; if (tex) texturedPolygon(dst, &vx[0], &vy[0], n, tex, dx, dy); }
		}
		else if (k == "S")
		{
			int x, y, c; std::string th2; o >> x >> y >> c >> th2;
			Bytes t = th2 == "-" ? Bytes() : FromHex(th2);
			t.push_back(0);
			stringColor(dst, (Sint16)x, (Sint16)y, (const char *)&t[0], GetRGBA(dst->format->palette->colors, c));
		}
	}
	if (getenv("GFX_DUMP")) { for (int y = 0; y < h; ++y) { for (int x = 0; x < w; ++x) printf("%02x ", ((unsigned char *)dst->pixels)[y * dst->pitch + x]); printf("\n"); } printf("pal0 %02x%02x%02x\n", dst->format->palette->colors[0].r, dst->format->palette->colors[0].g, dst->format->palette->colors[0].b); }
	char buf[32];
	snprintf(buf, sizeof buf, "%llu", Fnv(dst));
	SDL_FreeSurface(dst);
	if (tex) SDL_FreeSurface(tex);
	return buf;
}

int main(int argc, char **argv)
{
	std::string mode = argc > 1 ? argv[1] : "";
	if (mode == "gen" && argc == 5)
	{
		std::mt19937 r((unsigned)atoi(argv[2]));
		int n = atoi(argv[3]);
		std::ofstream out(argv[4], std::ios::binary);
		for (int i = 0; i < n; ++i) out << MakeCase(r) << "\n";
		return 0;
	}
	if (mode == "run" && argc == 4)
	{
		std::ifstream in(argv[2]);
		std::ofstream out(argv[3], std::ios::binary);
		std::string line;
		while (std::getline(in, line)) out << RunCase(line) << "\n";
		return 0;
	}
	fprintf(stderr, "usage\n");
	return 1;
}
