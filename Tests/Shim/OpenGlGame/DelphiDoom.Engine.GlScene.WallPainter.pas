{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of DelphiDoom.Engine.GlScene.WallPainter for the per-game OpenGL scene tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.WallPainter.pas in DelphiDoom.Tests.OpenGl.<Game> only: the class has only the BeginFrame the frame calls.
unit DelphiDoom.Engine.GlScene.WallPainter;

interface

uses
  d_delphi;

type
  /// <summary>Only the call the frame makes at its start: a line of EventLog</summary>
  TEngineGlSceneWallPainter = class(TObject)
  public
    procedure BeginFrame(const ACameraX, ACameraY, ACameraZ: float);
  end;

implementation

uses
  System.SysUtils;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

procedure TEngineGlSceneWallPainter.BeginFrame(const ACameraX, ACameraY, ACameraZ: float);
begin
  ShimEvent('WallPainter.BeginFrame ' + FloatBits(ACameraX) + ' ' + FloatBits(ACameraY) + ' ' + FloatBits(ACameraZ));
end;

end.
