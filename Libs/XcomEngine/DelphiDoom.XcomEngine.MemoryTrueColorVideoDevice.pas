{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - a display in memory that also takes        }
{  frames of colors (the tests and the screenshots of the true color path)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.XcomEngine.TrueColor.Intf;

type
  /// <summary>
  ///   TXcomMemoryVideoDevice that is also an IXcomTrueColorDisplay: it keeps the last frame of colors it was
  ///   given. A frame of colors counts as a presented picture
  /// </summary>
  TXcomMemoryTrueColorVideoDevice = class(TXcomMemoryVideoDevice, IXcomTrueColorDisplay)
  strict private
    FTrueColorPixels: TXcomTrueColorPixels;
    FTrueColorWidth: Integer;
    FTrueColorHeight: Integer;
    FTrueColorPresented: Integer;
    FRefuses: Boolean;
  public
    function PresentTrueColor(const APixels: TXcomTrueColorPixels; AWidth, AHeight: Integer): Boolean;
    /// <summary>The last frame: TrueColorWidth x TrueColorHeight values $FFRRGGBB</summary>
    property TrueColorPixels: TXcomTrueColorPixels read FTrueColorPixels;
    property TrueColorWidth: Integer read FTrueColorWidth;
    property TrueColorHeight: Integer read FTrueColorHeight;
    /// <summary>How many frames of colors were presented</summary>
    property TrueColorPresented: Integer read FTrueColorPresented;
    /// <summary>The device answers that it cannot show frames of colors (a display that lost that ability)</summary>
    property Refuses: Boolean read FRefuses write FRefuses;
  end;

implementation

function TXcomMemoryTrueColorVideoDevice.PresentTrueColor(const APixels: TXcomTrueColorPixels; AWidth,
  AHeight: Integer): Boolean;
begin
  Result := not FRefuses;
  if not Result then
    Exit;
  FTrueColorPixels := Copy(APixels);
  FTrueColorWidth := AWidth;
  FTrueColorHeight := AHeight;
  Inc(FTrueColorPresented);
end;

end.
