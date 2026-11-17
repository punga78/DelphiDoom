{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of DelphiDoom.Engine.GlScene.FlatCollector for the per-game OpenGL scene tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.FlatCollector.pas in DelphiDoom.Tests.OpenGl.<Game> only: the class has only the BeginFrame the frame calls.
unit DelphiDoom.Engine.GlScene.FlatCollector;

interface

uses
  d_delphi;

type
  /// <summary>Only the call the frame makes at its start: a line of EventLog</summary>
  TEngineGlSceneFlatCollector = class(TObject)
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

procedure TEngineGlSceneFlatCollector.BeginFrame(const AMarker: Byte);
begin
  ShimEvent('Flats.BeginFrame ' + IntToStr(AMarker));
end;

end.
