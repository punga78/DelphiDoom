{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_defs for the OpenGL 2D mode and vsync units      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_defs.pas in DelphiDoom.Tests.OpenGl only: just the two options
// the units read (same names and same initial values as the real ones).
unit gl_defs;

interface

var
  gl_screensync: Boolean = True;
  gl_no_glfinish_hack: Boolean = True;

implementation

end.
