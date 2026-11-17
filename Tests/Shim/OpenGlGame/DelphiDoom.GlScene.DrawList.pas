{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of DelphiDoom.GlScene.DrawList for the per-game OpenGL scene tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\GlScene\DelphiDoom.GlScene.DrawList.pas in DelphiDoom.Tests.OpenGl.<Game> only: the class has only the BeginFrame the frame calls.
unit DelphiDoom.GlScene.DrawList;

interface

uses
  d_delphi;

type
  /// <summary>Only the call the frame makes at its start: a line of EventLog</summary>
  TGlSceneDrawList = class(TObject)
  public
    procedure BeginFrame(const AMarker: Byte);
  end;

implementation

uses
  System.SysUtils;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

procedure TGlSceneDrawList.BeginFrame(const AMarker: Byte);
begin
  ShimEvent('DrawList.BeginFrame ' + IntToStr(AMarker));
end;

end.
