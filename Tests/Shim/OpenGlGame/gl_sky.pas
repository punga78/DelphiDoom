{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_sky for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_sky.pas in DelphiDoom.Tests.OpenGl.<Game> only: the initialization call is a line of EventLog.
unit gl_sky;

interface

uses
  System.SysUtils;

procedure gld_CalculateSky(const aSize : Double);

implementation

uses
  d_delphi;

procedure gld_CalculateSky(const aSize : Double);
begin
  ShimEvent('gld_CalculateSky ' + FloatToStr(aSize));
end;

end.
