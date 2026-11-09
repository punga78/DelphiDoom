{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .PCK files with their .TAB            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.PckDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.BinaryReader, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   SurfaceSet::loadPck. A frame is run length coded: the first byte is the number of EMPTY rows, then bytes that
  ///   are pixels, 254 followed by a count that is that many empty pixels (index 0), and 255 that ends the frame.
  ///   The .TAB has the offsets of the frames but OpenXcom does not use them: only how many there are, that it
  ///   takes from the size of the file (and from the first value, that tells 16 bit offsets from 32 bit ones)
  /// </summary>
  TXcomPckDecoder = class(TInterfacedObject, IXcomPckDecoder)
  public
    function Decode(const APck, ATab: TBytes; AWidth, AHeight: Integer): TArray<TXcomImage>;
    /// <summary>
    ///   How many frames the .TAB says: its size divided by 2 when the first 4 bytes are not zero (16 bit
    ///   offsets, the second one is not zero), by 4 when they are (32 bit offsets)
    /// </summary>
    class function FrameCount(const ATab: TBytes): Integer; static;
  end;

implementation

const
  MAX_FRAMES = 65536;

{ TXcomPckDecoder }

class function TXcomPckDecoder.FrameCount(const ATab: TBytes): Integer;
var
  LFirst: Cardinal;
begin
  if Length(ATab) = 0 then
    Exit(1);
  if Length(ATab) < 4 then
    raise EXcomDataException.CreateFmt(SXcomHeaderTooShort, ['the TAB file', 4, Length(ATab)]);
  LFirst := Cardinal(ATab[0]) or (Cardinal(ATab[1]) shl 8) or (Cardinal(ATab[2]) shl 16) or (Cardinal(ATab[3]) shl 24);
  if LFirst <> 0 then
    Result := Length(ATab) div 2
  else
    Result := Length(ATab) div 4;
end;

function TXcomPckDecoder.Decode(const APck, ATab: TBytes; AWidth, AHeight: Integer): TArray<TXcomImage>;
var
  LFrames: Integer;
  LReader: TXcomBinaryReader;
  LFrame: Integer;
  LImage: TXcomImage;
  LX: Integer;
  LY: Integer;
  LValue: Byte;
  LRow: Integer;
  LColumn: Integer;
  LCount: Integer;
begin
  LFrames := FrameCount(ATab);
  if LFrames > MAX_FRAMES then
    raise EXcomDataException.CreateFmt(SXcomTooManyFrames, [LFrames, MAX_FRAMES]);
  SetLength(Result, LFrames);
  LReader := TXcomBinaryReader.Create(APck);
  try
    LValue := 0;
    for LFrame := 0 to LFrames - 1 do
    begin
      LImage := TXcomImage.Create(AWidth, AHeight);
      LX := 0;
      LY := 0;
      LReader.ReadByte(LValue);
      for LRow := 1 to LValue do
        for LColumn := 1 to AWidth do
          LImage.SetPixelIterative(LX, LY, 0);
      while LReader.ReadByte(LValue) and (LValue <> 255) do
      begin
        if LValue = 254 then
        begin
          LReader.ReadByte(LValue);
          for LCount := 1 to LValue do
            LImage.SetPixelIterative(LX, LY, 0);
        end
        else
          LImage.SetPixelIterative(LX, LY, LValue);
      end;
      Result[LFrame] := LImage;
    end;
  finally
    LReader.Free;
  end;
end;

end.
