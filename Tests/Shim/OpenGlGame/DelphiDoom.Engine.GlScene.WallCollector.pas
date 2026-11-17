{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of DelphiDoom.Engine.GlScene.WallCollector for the per-game OpenGL scene tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.WallCollector.pas in DelphiDoom.Tests.OpenGl.<Game> only: the class has only the BeginFrame the frame calls.
unit DelphiDoom.Engine.GlScene.WallCollector;

interface

uses
  d_delphi;

type
  /// <summary>Only the call the frame makes at its start: a line of EventLog</summary>
  TEngineGlSceneWallCollector = class(TObject)
  public
    procedure BeginFrame(const AMarker: Byte; const AYaw, ACameraZ: float);
  end;

implementation

uses
  System.SysUtils;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

procedure TEngineGlSceneWallCollector.BeginFrame(const AMarker: Byte; const AYaw, ACameraZ: float);
begin
  ShimEvent('Walls.BeginFrame ' + IntToStr(AMarker) + ' ' + FloatBits(AYaw) + ' ' + FloatBits(ACameraZ));
end;

end.
