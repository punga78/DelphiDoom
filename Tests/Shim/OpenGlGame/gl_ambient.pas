{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_ambient for the per-game OpenGL scene tests     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_ambient.pas in DelphiDoom.Tests.OpenGl.<Game> only: the initialization call is a line of EventLog.
unit gl_ambient;

interface

uses
  System.SysUtils;

procedure gld_InitAmbient;

implementation

uses
  d_delphi;

procedure gld_InitAmbient;
begin
  ShimEvent('gld_InitAmbient');
end;

end.
