/*
  Issue #197: il rasterizzatore software di SDL3 (la DLL vera di Reference\war1\deps\lib\win32) su scenari con seme fisso.
  Serve a provare TWarImageBlitter (Games\War\DelphiDoom.War.Render.Blitter.pas) contro i pixel veri: SDL_RenderTexture e
  SDL_RenderTextureRotated con la modalita' NEAREST, specchi, colore e alfa della texture e SDL_BLENDMODE_BLEND, SDL_RenderFillRect
  e SDL_RenderRect, su una SDL_Surface RGBA32 di 320 x 200 con il renderer software.

  Uso:  sdl_raster_ref N [partial]  N scenari (seme 1..N): una riga "R seme fnv1a32" per scenario ("partial": anche alfa parziali)
        sdl_raster_ref one SEED     lo scenario SEED: i 320 x 200 x 4 byte su stdout (binario)
        sdl_raster_ref blend        la tabella (srcAlpha, alphaMod, s, d) -> risultato di un pixel: prova del fuso
  Il generatore degli scenari e' scritto due volte (qui e in Tests\Source\DelphiDoom.Tests.War.RasterScenario.pas): stessa LCG.
*/
#include <SDL3/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>

static unsigned gState;
static unsigned rnd(unsigned n)
{
    gState = gState * 1664525u + 1013904223u;
    return n == 0 ? 0 : (gState >> 8) % n;
}

static SDL_Surface* gSurface;
static SDL_Renderer* gRenderer;

static void makeRenderer(void)
{
    if (!gSurface)
    {
        SDL_Init(0);
        gSurface = SDL_CreateSurface(320, 200, SDL_PIXELFORMAT_RGBA32);
        gRenderer = SDL_CreateSoftwareRenderer(gSurface);
        SDL_SetRenderLogicalPresentation(gRenderer, 320, 200, SDL_LOGICAL_PRESENTATION_INTEGER_SCALE);
    }
}

static unsigned fnv(const unsigned char* p, size_t n)
{
    unsigned h = 2166136261u;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 16777619u; }
    return h;
}

static float fq(int v, int d) { return (float)v / (float)d; }

typedef struct { SDL_Texture* t; int w, h; } Tex;

/* ogni numero a caso si estrae in una istruzione propria: l'ordine di valutazione degli argomenti in C non e' definito */
/* modo (bit): 1 = alfa parziali nelle texture; 2 = tutto dentro lo schermo (niente ritaglio); 4 = posizioni e misure intere;
   8 = niente specchi; 16 = niente scale (misura di arrivo = misura di partenza). Ogni numero si estrae comunque: i modi
   cambiano solo i valori usati, cosi' il generatore resta lo stesso per tutti */
static int gMode = 0;
#define gPartialAlpha (gMode & 1)

static void scenario(unsigned seed, int dump)
{
    makeRenderer();
    gState = seed * 2654435761u + 12345u;
    unsigned cr, cg, cb, ca;
    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
    cr = rnd(256); cg = rnd(256); cb = rnd(256);
    SDL_SetRenderDrawColor(gRenderer, (Uint8)cr, (Uint8)cg, (Uint8)cb, 255);
    SDL_RenderClear(gRenderer);

    Tex tex[3];
    for (int i = 0; i < 3; i++)
    {
        tex[i].w = 1 + rnd(20);
        tex[i].h = 1 + rnd(20);
        unsigned* px = (unsigned*)malloc(tex[i].w * tex[i].h * 4);
        for (int k = 0; k < tex[i].w * tex[i].h; k++)
        {
            unsigned a, r, g, b;
            unsigned q = rnd(100);
            if (q < 60) a = 255;
            else if (!gPartialAlpha) a = 0;
            else
            {
                unsigned q2 = rnd(100);
                if (q2 < 60) a = 0; else a = rnd(256);
            }
            r = rnd(256); g = rnd(256); b = rnd(256);
            px[k] = r | (g << 8) | (b << 16) | (a << 24);
        }
        tex[i].t = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STATIC, tex[i].w, tex[i].h);
        SDL_UpdateTexture(tex[i].t, NULL, px, tex[i].w * 4);
        SDL_SetTextureScaleMode(tex[i].t, SDL_SCALEMODE_NEAREST);
        free(px);
    }

    int ops = 24;
    for (int o = 0; o < ops; o++)
    {
        int kind = rnd(10);
        if (kind < 6)
        {
            int ti = rnd(3);
            Tex* t = &tex[ti];
            int sx = rnd(t->w);
            int sy = rnd(t->h);
            int sw = 1 + rnd(t->w - sx);
            int sh = 1 + rnd(t->h - sy);
            SDL_FRect s = { (float)sx, (float)sy, (float)sw, (float)sh };
            if (rnd(10) == 0)
            {
                int fr = rnd(4);
                s.x = fq(sx * 4 + fr, 4);
                if (s.x + s.w > t->w) s.x = (float)sx;
            }
            SDL_FRect d;
            int dxi = rnd(370 * 8);
            int dyi = rnd(240 * 8);
            d.x = fq(dxi - 40 * 8, 8);
            d.y = fq(dyi - 30 * 8, 8);
            int m = rnd(8);
            if (m < 4) { d.w = (float)sw; d.h = (float)sh; }
            else if (m == 4) { d.w = (float)(sw * 2); d.h = (float)(sh * 2); }
            else if (m == 5) { d.w = (float)(sw * 3); d.h = (float)(sh * 3); }
            else if (m == 6) { d.w = fq(sw * 5, 2); d.h = fq(sh * 3, 2); }
            else
            {
                int rw = rnd(120);
                int rh = rnd(120);
                d.w = fq(1 + rw, 4); d.h = fq(1 + rh, 4);
            }
            if (rnd(4) == 0) { d.x = (float)(int)d.x; d.y = (float)(int)d.y; }
            if (gMode & 2) { d.x = fq(dxi % (250 * 8), 8); d.y = fq(dyi % (130 * 8), 8); }
            if (gMode & 4) { d.x = (float)(int)d.x; d.y = (float)(int)d.y; d.w = (float)(int)d.w; d.h = (float)(int)d.h; if (d.w < 1) d.w = 1; if (d.h < 1) d.h = 1; }
            if (gMode & 16) { d.w = (float)sw; d.h = (float)sh; }
            int am;
            int q = rnd(10);
            if (q < 5) am = 255;
            else if (rnd(2)) am = 127;
            else am = rnd(256);
            SDL_SetTextureAlphaMod(t->t, (Uint8)am);
            if (rnd(10) < 6) SDL_SetTextureColorMod(t->t, 255, 255, 255);
            else
            {
                unsigned mr = rnd(256), mg = rnd(256), mb = rnd(256);
                SDL_SetTextureColorMod(t->t, (Uint8)mr, (Uint8)mg, (Uint8)mb);
            }
            SDL_SetTextureBlendMode(t->t, SDL_BLENDMODE_BLEND);
            int flip = rnd(4);
            if (getenv("RTRACE")) { Uint8 qr, qg, qb; SDL_GetTextureColorMod(t->t, &qr, &qg, &qb); fprintf(stderr, "T%d tex%d s %.4f %.4f %.4f %.4f d %.4f %.4f %.4f %.4f am %d cm %d,%d,%d flip %d\n", kind, ti, s.x, s.y, s.w, s.h, d.x, d.y, d.w, d.h, am, qr, qg, qb, flip); }
            if (gMode & 64) {}
            else if ((gMode & 8) || flip == 0)
                SDL_RenderTexture(gRenderer, t->t, &s, &d);
            else
                SDL_RenderTextureRotated(gRenderer, t->t, &s, &d, 0.0, NULL,
                                         (SDL_FlipMode)((flip & 1 ? SDL_FLIP_HORIZONTAL : 0) | (flip & 2 ? SDL_FLIP_VERTICAL : 0)));
        }
        else
        {
            SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_BLEND);
            cr = rnd(256); cg = rnd(256); cb = rnd(256);
            ca = rnd(2) ? 255 : rnd(256);
            SDL_SetRenderDrawColor(gRenderer, (Uint8)cr, (Uint8)cg, (Uint8)cb, (Uint8)ca);
            int rx = rnd(340 * 4), ry = rnd(220 * 4), rw = rnd(100 * 4), rh = rnd(60 * 4);
            SDL_FRect r = { fq(rx - 10 * 4, 4), fq(ry - 10 * 4, 4), fq(rw, 4), fq(rh, 4) };
            if (gMode & 2) { r.x = fq(rx % (250 * 4), 4); r.y = fq(ry % (150 * 4), 4); }
            if (gMode & 4) { r.x = (float)(int)r.x; r.y = (float)(int)r.y; r.w = (float)(int)r.w; r.h = (float)(int)r.h; }
            if (kind >= 8) { if (r.w < 2) r.w = 2; if (r.h < 2) r.h = 2; }
            if (getenv("RTRACE")) fprintf(stderr, "K%d r %.4f %.4f %.4f %.4f c %u,%u,%u,%u\n", kind, r.x, r.y, r.w, r.h, cr, cg, cb, ca);
            if (gMode & 32) {}
            else if (kind < 8) SDL_RenderFillRect(gRenderer, &r);
            else SDL_RenderRect(gRenderer, &r);
        }
    }
    SDL_Surface* o = SDL_RenderReadPixels(gRenderer, NULL);
    if (dump)
    {
        _setmode(_fileno(stdout), _O_BINARY);
        for (int y = 0; y < o->h; y++) fwrite((Uint8*)o->pixels + (size_t)y * o->pitch, 1, 4 * o->w, stdout);
    }
    else
    {
        unsigned h = 2166136261u;
        for (int y = 0; y < o->h; y++) h = fnv((Uint8*)o->pixels + (size_t)y * o->pitch, 4 * o->w) ^ (h * 31);
        printf("R %u %08x\n", seed, h);
    }
    SDL_DestroySurface(o);
    for (int i = 0; i < 3; i++) SDL_DestroyTexture(tex[i].t);
}


/* il fuso di un pixel: sorgente (s,s,s,srcA) con alfa mod M sul fondo (d,d,d,255), BLEND */
static void blendTable(void)
{
    makeRenderer();
    SDL_Texture* t = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STATIC, 1, 1);
    SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(t, SDL_SCALEMODE_NEAREST);
    unsigned s_[] = { 0, 1, 17, 64, 100, 127, 128, 200, 254, 255 };
    for (int a = 0; a < 256; a += 5)
        for (int m = 0; m < 256; m += 3)
            for (int si = 0; si < 10; si++)
                for (int di = 0; di < 10; di++)
                {
                    unsigned s = s_[si], d = s_[di];
                    unsigned px = s | (s << 8) | (s << 16) | ((unsigned)a << 24);
                    SDL_UpdateTexture(t, NULL, &px, 4);
                    SDL_SetTextureAlphaMod(t, (Uint8)m);
                    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
                    SDL_SetRenderDrawColor(gRenderer, d, d, d, 255);
                    SDL_RenderClear(gRenderer);
                    SDL_FRect r = { 0, 0, 1, 1 };
                    SDL_RenderTexture(gRenderer, t, NULL, &r);
                    SDL_Rect one = { 0, 0, 1, 1 };
                    SDL_Surface* o = SDL_RenderReadPixels(gRenderer, &one);
                    unsigned v = *(unsigned*)o->pixels;
                    printf("B %d %d %u %u %u %u\n", a, m, s, d, v & 255, v >> 24);
                    SDL_DestroySurface(o);
                }
}

/* il fuso di un riempimento e di un contorno: colore (s,s,s,A) su (d,d,d,255), 1 pixel */
static void fillTable(int stroke)
{
    makeRenderer();
    unsigned s_[] = { 0, 1, 17, 64, 100, 127, 128, 200, 254, 255 };
    for (int a = 0; a < 256; a += 5)
        for (int si = 0; si < 10; si++)
            for (int di = 0; di < 10; di++)
            {
                unsigned s = s_[si], d = s_[di];
                SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
                SDL_SetRenderDrawColor(gRenderer, d, d, d, 255);
                SDL_RenderClear(gRenderer);
                SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_BLEND);
                SDL_SetRenderDrawColor(gRenderer, s, s, s, a);
                SDL_FRect r = { 0, 0, 1, 1 };
                SDL_FRect big = { 0, 0, 5, 5 };
                if (stroke) SDL_RenderRect(gRenderer, &big); else SDL_RenderFillRect(gRenderer, &r);
                SDL_Rect one = { stroke ? 2 : 0, 0, 1, 1 };
                SDL_Surface* o = SDL_RenderReadPixels(gRenderer, &one);
                unsigned v = *(unsigned*)o->pixels;
                printf("%c %d 255 %u %u %u %u\n", stroke ? 'S' : 'F', a, s, d, v & 255, v >> 24);
                SDL_DestroySurface(o);
            }
}

/* il contorno: la forma di un rettangolo x y w h (alfa 128, bianco su nero): quante volte e' disegnato ogni pixel */
static void strokeShape(float x, float y, float w, float h)
{
    makeRenderer();
    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
    SDL_SetRenderDrawColor(gRenderer, 0, 0, 0, 255);
    SDL_RenderClear(gRenderer);
    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(gRenderer, 255, 255, 255, 128);
    SDL_FRect r = { x, y, w, h };
    SDL_RenderRect(gRenderer, &r);
    SDL_Rect area = { 0, 0, 12, 9 };
    SDL_Surface* o = SDL_RenderReadPixels(gRenderer, &area);
    for (int j = 0; j < 9; j++)
    {
        for (int i = 0; i < 12; i++)
        {
            unsigned v = ((unsigned*)((Uint8*)o->pixels + j * o->pitch))[i] & 255;
            printf("%4u", v);
        }
        printf("\n");
    }
    SDL_DestroySurface(o);
}

/* il fuso di un pixel con colori diversi per canale: modo 0 = RenderTexture, 1 = RenderTextureRotated con specchio orizzontale;
   alfa mod M; stampa "G sa m sr sg sb dr dg db -> vr vg vb va" */
static void colorBlend(int flip, int m)
{
    makeRenderer();
    gState = 777;
    SDL_Texture* t = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STATIC, 1, 1);
    SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(t, SDL_SCALEMODE_NEAREST);
    for (int n = 0; n < 20000; n++)
    {
        unsigned sa = 1 + rnd(254), sr = rnd(256), sg = rnd(256), sb = rnd(256), dr = rnd(256), dg = rnd(256), db = rnd(256);
        unsigned px = sr | (sg << 8) | (sb << 16) | (sa << 24);
        SDL_UpdateTexture(t, NULL, &px, 4);
        SDL_SetTextureAlphaMod(t, (Uint8)m);
        SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
        SDL_SetRenderDrawColor(gRenderer, dr, dg, db, 255);
        SDL_RenderClear(gRenderer);
        SDL_FRect r = { 0, 0, 1, 1 };
        if (flip) SDL_RenderTextureRotated(gRenderer, t, NULL, &r, 0.0, NULL, SDL_FLIP_HORIZONTAL);
        else SDL_RenderTexture(gRenderer, t, NULL, &r);
        SDL_Rect one = { 0, 0, 1, 1 };
        SDL_Surface* o = SDL_RenderReadPixels(gRenderer, &one);
        unsigned v = *(unsigned*)o->pixels;
        printf("G %u %d %u %u %u %u %u %u %u %u %u %u\n", sa, m, sr, sg, sb, dr, dg, db, v & 255, (v >> 8) & 255, (v >> 16) & 255, v >> 24);
        SDL_DestroySurface(o);
    }
}

/* le linee: SDL_RenderLine (SDL_BLENDMODE_BLEND) con estremi float. modo (bit): 1 = alfa parziali; 2 = tutto dentro lo schermo;
   4 = estremi interi; 16 = fino a 2000 pixel fuori dallo schermo; 8 = solo linee corte (le frecce del debug: fino a 6 pixel). Il generatore e' scritto due volte (qui e in
   Tests\Source\DelphiDoom.Tests.War.RasterScenario.pas) */
static void lineScenario(unsigned seed, int dump)
{
    makeRenderer();
    gState = seed * 2654435761u + 777u;
    unsigned cr, cg, cb, ca;
    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
    cr = rnd(256); cg = rnd(256); cb = rnd(256);
    SDL_SetRenderDrawColor(gRenderer, (Uint8)cr, (Uint8)cg, (Uint8)cb, 255);
    SDL_RenderClear(gRenderer);
    for (int o = 0; o < 40; o++)
    {
        int ax = rnd(400 * 4), ay = rnd(260 * 4), kind = rnd(8);
        int bx = rnd(400 * 4), by = rnd(260 * 4);
        int sa = rnd(8);
        float px = fq(ax - 40 * 4, 4), py = fq(ay - 30 * 4, 4);
        float qx = fq(bx - 40 * 4, 4), qy = fq(by - 30 * 4, 4);
        if (gMode & 2) { px = fq(ax % (300 * 4), 4); py = fq(ay % (180 * 4), 4); qx = fq(bx % (300 * 4), 4); qy = fq(by % (180 * 4), 4); }
        if (gMode & 8) { qx = px + fq(bx % (6 * 4 * 2) - 6 * 4, 4); qy = py + fq(by % (6 * 4 * 2) - 6 * 4, 4); }
        if (gMode & 16) { px = fq(ax * 8 - 1200 * 4, 4); py = fq(ay * 8 - 800 * 4, 4); qx = fq(bx * 8 - 1200 * 4, 4); qy = fq(by * 8 - 800 * 4, 4); }
        if (kind == 0) qy = py;
        else if (kind == 1) qx = px;
        else if (kind == 2) qy = py + (qx - px);
        else if (kind == 3) qy = py - (qx - px);
        if (gMode & 4) { px = (float)(int)px; py = (float)(int)py; qx = (float)(int)qx; qy = (float)(int)qy; }
        /* una linea obliqua con una coordinata in (-1, 0) la SDL la disegna in un altro modo (non portato): si sposta */
        if (px != qx && py != qy)
        {
            if (px > -1 && px < 0) px -= 1;
            if (py > -1 && py < 0) py -= 1;
            if (qx > -1 && qx < 0) qx -= 1;
            if (qy > -1 && qy < 0) qy -= 1;
        }
        cr = rnd(256); cg = rnd(256); cb = rnd(256);
        ca = rnd(2) ? 128 : rnd(256);
        if (!(gMode & 1) || sa < 4) ca = 255;
        SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_BLEND);
        SDL_SetRenderDrawColor(gRenderer, (Uint8)cr, (Uint8)cg, (Uint8)cb, (Uint8)ca);
        if (getenv("RTRACE")) fprintf(stderr, "L%d %.4f %.4f %.4f %.4f c %u,%u,%u,%u\n", kind, px, py, qx, qy, cr, cg, cb, ca);
        SDL_RenderLine(gRenderer, px, py, qx, qy);
    }
    SDL_Surface* o = SDL_RenderReadPixels(gRenderer, NULL);
    if (dump)
    {
        _setmode(_fileno(stdout), _O_BINARY);
        for (int y = 0; y < o->h; y++) fwrite((Uint8*)o->pixels + (size_t)y * o->pitch, 1, 4 * o->w, stdout);
    }
    else
    {
        unsigned h = 2166136261u;
        for (int y = 0; y < o->h; y++) h = fnv((Uint8*)o->pixels + (size_t)y * o->pitch, 4 * o->w) ^ (h * 31);
        printf("R %u %08x\n", seed, h);
    }
    SDL_DestroySurface(o);
}

/* la forma di una linea x1 y1 x2 y2 con colore bianco e alfa A su nero: il canale rosso di una finestra 24 x 12 */
static void lineShape(float x1, float y1, float x2, float y2, int a)
{
    makeRenderer();
    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_NONE);
    SDL_SetRenderDrawColor(gRenderer, 0, 0, 0, 255);
    SDL_RenderClear(gRenderer);
    SDL_SetRenderDrawBlendMode(gRenderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(gRenderer, 255, 255, 255, (Uint8)a);
    SDL_RenderLine(gRenderer, x1, y1, x2, y2);
    SDL_Rect area = { 0, 0, 24, 12 };
    SDL_Surface* o = SDL_RenderReadPixels(gRenderer, &area);
    for (int j = 0; j < 12; j++)
    {
        for (int i = 0; i < 24; i++)
        {
            unsigned v = ((unsigned*)((Uint8*)o->pixels + j * o->pitch))[i] & 255;
            printf("%4u", v);
        }
        printf("\n");
    }
    SDL_DestroySurface(o);
}

int main(int argc, char** argv)
{
    if (argc >= 7 && !strcmp(argv[1], "lineshape")) { lineShape((float)atof(argv[2]), (float)atof(argv[3]), (float)atof(argv[4]), (float)atof(argv[5]), atoi(argv[6])); return 0; }
    if (argc >= 3 && !strcmp(argv[1], "lines")) { int n = atoi(argv[2]); gMode = argc >= 4 ? atoi(argv[3]) : 0; for (int i = 1; i <= n; i++) lineScenario((unsigned)i, 0); return 0; }
    if (argc >= 3 && !strcmp(argv[1], "lineone")) { gMode = argc >= 4 ? atoi(argv[3]) : 0; lineScenario((unsigned)atoi(argv[2]), 1); return 0; }
    if (argc >= 4 && !strcmp(argv[1], "colorblend")) { colorBlend(atoi(argv[2]), atoi(argv[3])); return 0; }
    if (argc >= 6 && !strcmp(argv[1], "shape")) { strokeShape((float)atof(argv[2]), (float)atof(argv[3]), (float)atof(argv[4]), (float)atof(argv[5])); return 0; }
    if (argc >= 2 && !strcmp(argv[1], "fill")) { fillTable(0); return 0; }
    if (argc >= 2 && !strcmp(argv[1], "stroke")) { fillTable(1); return 0; }
    if (argc >= 3 && !strcmp(argv[1], "one"))
    {
        gMode = argc >= 4 ? atoi(argv[3]) : 0;
        scenario((unsigned)atoi(argv[2]), 1);
        return 0;
    }
    if (argc >= 2 && !strcmp(argv[1], "blend")) { blendTable(); return 0; }
    int n = argc >= 2 ? atoi(argv[1]) : 100;
    gMode = argc >= 3 ? atoi(argv[2]) : 0;
    for (int i = 1; i <= n; i++) scenario((unsigned)i, 0);
    return 0;
}
