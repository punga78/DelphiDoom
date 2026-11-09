{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - a display that is a block of memory        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.MemoryVideoDevice;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomVideoDevice without a window: it keeps the last picture it was given. It is the display of the tests and
  ///   of the screenshots taken with no window (-shot); the size asked for is the size it takes
  /// </summary>
  TXcomMemoryVideoDevice = class(TInterfacedObject, IXcomVideoDevice)
  strict private
    FPixels: TBytes;
    FWidth: Integer;
    FHeight: Integer;
    FPalette: TXcomColors;
    FPresented: Integer;
    FTitle: string;
  public
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
    property Pixels: TBytes read FPixels;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Palette: TXcomColors read FPalette;
    /// <summary>How many pictures were presented</summary>
    property Presented: Integer read FPresented;
    property Title: string read FTitle;
  end;

implementation

procedure TXcomMemoryVideoDevice.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  FWidth := AWidth;
  FHeight := AHeight;
end;

procedure TXcomMemoryVideoDevice.Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
begin
  FPixels := Copy(APixels);
  FWidth := AWidth;
  FHeight := AHeight;
  FPalette := APalette;
  Inc(FPresented);
end;

procedure TXcomMemoryVideoDevice.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
end;

end.
