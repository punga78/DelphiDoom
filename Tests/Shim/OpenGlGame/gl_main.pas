{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_main for the per-game OpenGL scene tests        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_main.pas in DelphiDoom.Tests.OpenGl.<Game> only: the swap of the buffers does not touch any window, it is a line of EventLog.
unit gl_main;

interface

procedure GL_SwapBuffers;

implementation

uses
  d_delphi;

procedure GL_SwapBuffers;
begin
  ShimEvent('GL_SwapBuffers');
end;

end.