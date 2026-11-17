{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_main for the OpenGL 2D mode unit                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_main.pas in DelphiDoom.Tests.OpenGl only: the swap of the
// buffers does not touch any window, it calls the hook the test sets (nil = nothing).
unit gl_main;

interface

var
  SwapBuffersHook: procedure;

procedure GL_SwapBuffers;

implementation

procedure GL_SwapBuffers;
begin
  if Assigned(SwapBuffersHook) then
    SwapBuffersHook;
end;

end.
