{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .SCR files                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ScrDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   Surface::loadScr: the file is the palette index of every pixel, row after row, with no header (the screens
  ///   are 320 x 200). Surface::loadRaw copies what is there: a short file leaves the end of the picture at 0
  ///   and the bytes past the picture are not used
  /// </summary>
  TXcomScrDecoder = class(TInterfacedObject, IXcomImageDecoder)
  public
    function Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
  end;

implementation

{ TXcomScrDecoder }

function TXcomScrDecoder.Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
var
  LCount: Integer;
begin
  Result := TXcomImage.Create(AWidth, AHeight);
  LCount := Length(Result.Pixels);
  if LCount > Length(ABytes) then
    LCount := Length(ABytes);
  if LCount > 0 then
    Move(ABytes[0], Result.Pixels[0], LCount);
end;

end.
