{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .BDY files of Terror from the Deep    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.BdyDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.BinaryReader, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   Surface::loadBdy, a PackBits-like run length coding: a byte of 129 or more is 257 - byte repetitions of the
  ///   byte that follows, any other byte is 1 + byte bytes that follow. A run never goes into the next row:
  ///   what is left of it is dropped. A file that ends early is read like the original does (the last byte
  ///   that was read is reused)
  /// </summary>
  TXcomBdyDecoder = class(TInterfacedObject, IXcomImageDecoder)
  public
    function Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
  end;

implementation

{ TXcomBdyDecoder }

function TXcomBdyDecoder.Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
var
  LReader: TXcomBinaryReader;
  LDataByte: Byte;
  LPixelCount: Integer;
  LX: Integer;
  LY: Integer;
  LCurrentRow: Integer;
  LIndex: Integer;
begin
  Result := TXcomImage.Create(AWidth, AHeight);
  LReader := TXcomBinaryReader.Create(ABytes);
  try
    LDataByte := 0;
    LX := 0;
    LY := 0;
    while LReader.ReadByte(LDataByte) do
    begin
      if LDataByte >= 129 then
      begin
        LPixelCount := 257 - LDataByte;
        LReader.ReadByte(LDataByte);
        LCurrentRow := LY;
        for LIndex := 0 to LPixelCount - 1 do
        begin
          Result.SetPixelIterative(LX, LY, LDataByte);
          // do not go into the next row
          if LCurrentRow <> LY then
            Break;
        end;
      end
      else
      begin
        LPixelCount := 1 + LDataByte;
        LCurrentRow := LY;
        for LIndex := 0 to LPixelCount - 1 do
        begin
          LReader.ReadByte(LDataByte);
          if LCurrentRow = LY then
            Result.SetPixelIterative(LX, LY, LDataByte);
        end;
      end;
    end;
  finally
    LReader.Free;
  end;
end;

end.
