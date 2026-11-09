{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .DAT files of raw pictures            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.DatDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   SurfaceSet::loadDat: no offsets and no compression, the file is cut in frames of the same size
  ///   (the size of the file divided by the size of a frame, rounded down)
  /// </summary>
  TXcomDatDecoder = class(TInterfacedObject, IXcomDatDecoder)
  public
    function Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TArray<TXcomImage>;
  end;

implementation

{ TXcomDatDecoder }

function TXcomDatDecoder.Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TArray<TXcomImage>;
var
  LFrameSize: Integer;
  LFrames: Integer;
  LFrame: Integer;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
begin
  if (AWidth <= 0) or (AHeight <= 0) or (Int64(AWidth) * AHeight > MaxInt) then
    raise EXcomException.CreateFmt(SXcomSizeInvalid, [AWidth, AHeight]);
  LFrameSize := AWidth * AHeight;
  LFrames := Length(ABytes) div LFrameSize;
  SetLength(Result, LFrames);
  for LFrame := 0 to LFrames - 1 do
  begin
    Result[LFrame] := TXcomImage.Create(AWidth, AHeight);
    LX := 0;
    LY := 0;
    for LIndex := 0 to LFrameSize - 1 do
      Result[LFrame].SetPixelIterative(LX, LY, ABytes[LFrame * LFrameSize + LIndex]);
  end;
end;

end.
