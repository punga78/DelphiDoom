{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .SPK files                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.SpkDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.BinaryReader, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   Surface::loadSpk, the compression of the full screen pictures: a word 65535 and a count are COUNT * 2
  ///   empty pixels, a word 65534 and a count are COUNT * 2 pixels that follow in the file. Any other word is
  ///   ignored. A file that ends in the middle of a run gives what the original gives (the last value that
  ///   was read, repeated): the reader keeps the habits of std::ifstream
  /// </summary>
  TXcomSpkDecoder = class(TInterfacedObject, IXcomImageDecoder)
  public
    function Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
  end;

implementation

{ TXcomSpkDecoder }

function TXcomSpkDecoder.Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
var
  LReader: TXcomBinaryReader;
  LFlag: Word;
  LValue: Byte;
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  Result := TXcomImage.Create(AWidth, AHeight);
  LReader := TXcomBinaryReader.Create(ABytes);
  try
    LFlag := 0;
    LValue := 0;
    LX := 0;
    LY := 0;
    while LReader.ReadWord(LFlag) do
    begin
      if LFlag = 65535 then
      begin
        LReader.ReadWord(LFlag);
        for LIndex := 0 to LFlag * 2 - 1 do
          Result.SetPixelIterative(LX, LY, 0);
      end
      else if LFlag = 65534 then
      begin
        LReader.ReadWord(LFlag);
        for LIndex := 0 to LFlag * 2 - 1 do
        begin
          LReader.ReadByte(LValue);
          Result.SetPixelIterative(LX, LY, LValue);
        end;
      end;
    end;
  finally
    LReader.Free;
  end;
end;

end.
