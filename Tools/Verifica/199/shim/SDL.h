/*
 * Minimal stand-in of SDL.h for the parity harness of the FLIC decoder (issue #199).
 * FlcPlayer.h of OpenXcom only needs these types; the lines of FlcPlayer.cpp that the harness
 * includes need the surface, the colors and the byte order macros.
 */
#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef uint8_t Uint8;
typedef int8_t Sint8;
typedef uint16_t Uint16;
typedef int16_t Sint16;
typedef uint32_t Uint32;
typedef int32_t Sint32;

struct SDL_Color { Uint8 r, g, b, unused; };
struct SDL_PixelFormat { int BytesPerPixel; int BitsPerPixel; };
struct SDL_Surface { void *pixels; int pitch; int w; int h; SDL_PixelFormat *format; };
struct SDL_sem;

#define SDL_LIL_ENDIAN 1234
#define SDL_BIG_ENDIAN 4321
#define SDL_BYTEORDER SDL_LIL_ENDIAN
#define SDL_SwapLE16(x) (x)

static inline int SDL_LockSurface(SDL_Surface *) { return 0; }
static inline void SDL_UnlockSurface(SDL_Surface *) {}
static inline void SDL_SetColors(SDL_Surface *, SDL_Color *, int, int) {}
static inline void SDL_BlitSurface(SDL_Surface *, void *, SDL_Surface *, void *) {}
