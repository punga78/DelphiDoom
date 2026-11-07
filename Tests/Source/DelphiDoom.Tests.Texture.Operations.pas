{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Texture library - the operations on images that    }
{  the golden file of the old code covers                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Operations;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image;

type
  /// <summary>One image to start from: the bytes per pixel and the size</summary>
  TTextureOperationCase = record
    BytesPerPixel: Integer;
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>
  ///   The operations of Tests\Data\Texture\image.golden.txt: the harness that wrote the file did
  ///   the same on the old TTexture, and the line of each case has its name, as
  ///   op-NAME-bppB-WxH
  /// </summary>
  TTextureOperations = class sealed
  public
    const
      COUNT = 24;
    class function Cases: TArray<TTextureOperationCase>; static;
    class function Name(AOperation: Integer): string; static;
    class function CaseName(AOperation: Integer; const ACase: TTextureOperationCase): string; static;
    class function Seed(ACaseIndex: Integer): Integer; static;
    /// <summary>The image of the case, filled with the pseudo random pixels of its seed</summary>
    class function CreateImage(const ACase: TTextureOperationCase; ASeed: Integer): TTextureImage; static;
    /// <summary>Does the operation; the text is what the operation gave (hashes of the colors it read)</summary>
    class function Apply(AOperation: Integer; const AImage: TTextureImage; AWidth, AHeight,
      ASeed: Integer): string; static;
    /// <summary>The line of the golden file for an image after an operation</summary>
    class function Describe(AOperation: Integer; const AImage: TTextureImage;
      const AExtra: string): string; static;
  end;

implementation

uses
  DelphiDoom.Texture.Alpha, DelphiDoom.Tests.Texture.Samples;

function HashColorArray(const AColors: TArray<Cardinal>): string;
begin
  if Length(AColors) = 0 then
    Result := '-'
  else
    Result := TTextureSamples.Hex(TTextureSamples.HashColors(@AColors[0], Length(AColors)));
end;

// a hash of the first ARowBytes bytes of ARows rows that begin every AStride bytes
function PreservedHash(const APixels: PByte; AStride, ARowBytes, ARows: Integer): string;
var
  LBytes: TBytes;
  LRow: Integer;
begin
  SetLength(LBytes, ARowBytes * ARows);
  for LRow := 0 to ARows - 1 do
    Move(PByte(NativeUInt(APixels) + NativeUInt(LRow * AStride))^, LBytes[LRow * ARowBytes], ARowBytes);
  Result := TTextureSamples.Hex(TTextureSamples.Hash(LBytes));
end;

{ TTextureOperations }

class function TTextureOperations.Cases: TArray<TTextureOperationCase>;
const
  Data: array[0..6, 0..2] of Integer = ((1, 5, 4), (1, 16, 16), (2, 6, 5), (4, 7, 3), (4, 16, 16),
    (1, 1, 1), (4, 1, 9));
var
  LIndex: Integer;
begin
  SetLength(Result, Length(Data));
  for LIndex := 0 to High(Data) do
  begin
    Result[LIndex].BytesPerPixel := Data[LIndex, 0];
    Result[LIndex].Width := Data[LIndex, 1];
    Result[LIndex].Height := Data[LIndex, 2];
  end;
end;

class function TTextureOperations.Name(AOperation: Integer): string;
begin
  case AOperation of
    0: Result := 'identity';
    1: Result := 'scale-up';
    2: Result := 'scale-down';
    3: Result := 'scale-height';
    4: Result := 'convert32';
    5: Result := 'gray';
    6: Result := 'mirror';
    7: Result := 'swap';
    8: Result := 'column32';
    9: Result := 'row32';
    10: Result := 'paletted-column32';
    11: Result := 'paletted-row32';
    12: Result := 'alpha-channel';
    13: Result := 'default-alpha';
    14: Result := 'remove-transparency';
    15: Result := 'adjust-transparency';
    16: Result := 'alpha-from-image';
    17: Result := 'grow-width';
    18: Result := 'grow-height';
    19: Result := 'set-column32';
    20: Result := 'set-row32';
    21: Result := 'swap-twice';
    22: Result := 'default-alpha-three-colors';
    23: Result := 'scale-then-convert';
  else
    Result := 'op' + IntToStr(AOperation);
  end;
end;

class function TTextureOperations.CaseName(AOperation: Integer; const ACase: TTextureOperationCase): string;
begin
  Result := Format('op-%s-bpp%d-%dx%d', [Name(AOperation), ACase.BytesPerPixel, ACase.Width, ACase.Height]);
end;

class function TTextureOperations.Seed(ACaseIndex: Integer): Integer;
begin
  Result := 500 + ACaseIndex * 13;
end;

class function TTextureOperations.CreateImage(const ACase: TTextureOperationCase; ASeed: Integer): TTextureImage;
begin
  Result := TTextureImage.Create;
  TTextureSamples.FillImage(Result, ACase.Width, ACase.Height, ACase.BytesPerPixel, ASeed);
end;

class function TTextureOperations.Describe(AOperation: Integer; const AImage: TTextureImage;
  const AExtra: string): string;
begin
  Result := TTextureSamples.Describe(True, AImage, AOperation in [17, 18], 256) + '|' + AExtra;
end;

class function TTextureOperations.Apply(AOperation: Integer; const AImage: TTextureImage; AWidth,
  AHeight, ASeed: Integer): string;
var
  LBuffer: TArray<Cardinal>;
  LOther: TTextureImage;
  LFirst: Cardinal;
  LColumn: Integer;
  LOk: Boolean;
  LIndexes: TArray<Integer>;
begin
  Result := '';
  case AOperation of
    0: ;
    1: AImage.ScaleTo(AWidth * 2 + 1, AHeight + 3);
    2: AImage.ScaleTo(AWidth div 2 + 1, AHeight div 3 + 1);
    3: AImage.ScaleTo(AWidth, AHeight + 5);
    4: AImage.ConvertTo32bit;
    5: AImage.ConvertToGrayScale;
    6: AImage.Mirror;
    7: AImage.SwapRGB;
    8:
    begin
      LIndexes := TArray<Integer>.Create(0, 1, AWidth - 1, AWidth + 3);
      for LColumn in LIndexes do
      begin
        SetLength(LBuffer, AHeight * 2 + 1);
        AImage.GetColumn32(LColumn, AHeight * 2 + 1, @LBuffer[0]);
        Result := Result + HashColorArray(LBuffer) + ',';
      end;
    end;
    9:
    begin
      LIndexes := TArray<Integer>.Create(0, 1, AHeight - 1, AHeight + 2);
      for LColumn in LIndexes do
      begin
        SetLength(LBuffer, AWidth * 2 + 1);
        AImage.GetRow32(LColumn, AWidth * 2 + 1, @LBuffer[0]);
        Result := Result + HashColorArray(LBuffer) + ',';
      end;
    end;
    10:
    begin
      SetLength(LBuffer, AHeight + 2);
      LOk := AImage.GetPalettedColumn32(1, AHeight + 2, @LBuffer[0], $0A0B0C);
      Result := IntToStr(Ord(LOk)) + ':';
      if LOk then
        Result := Result + HashColorArray(LBuffer);
    end;
    11:
    begin
      SetLength(LBuffer, AWidth + 2);
      LOk := AImage.GetPalettedRow32(1, AWidth + 2, @LBuffer[0], $0A0B0C);
      Result := IntToStr(Ord(LOk)) + ':';
      if LOk then
        Result := Result + HashColorArray(LBuffer) + Format(' [%.8x %.8x %.8x]', [LBuffer[0], LBuffer[1], LBuffer[2]]);
    end;
    12: TTextureAlpha.SetChannel(AImage, $80);
    13:
    begin
      AImage.ConvertTo32bit;
      LFirst := PCardinal(AImage.PixelsPointer)^;
      AImage.TransparentColor := LFirst;
      AImage.TransparentColor2 := LFirst;
      AImage.TransparentColor3 := LFirst;
      TTextureAlpha.SetDefaultChannel(AImage);
    end;
    14: TTextureAlpha.RemoveTransparency(AImage);
    15:
    begin
      AImage.ConvertTo32bit;
      LFirst := PCardinal(AImage.PixelsPointer)^;
      AImage.TransparentColor := LFirst;
      AImage.TransparentColor2 := LFirst;
      AImage.TransparentColor3 := LFirst;
      TTextureAlpha.AdjustTransparency(AImage);
    end;
    16:
    begin
      LOther := TTextureImage.Create;
      try
        TTextureSamples.FillImage(LOther, 3, 3, 1, ASeed + 9);
        LOther.SetPalette(TTextureSamples.Palette(ASeed + 10));
        AImage.ConvertTo32bit;
        TTextureAlpha.SetChannelFromImage(AImage, LOther);
      finally
        LOther.Free;
      end;
    end;
    17:
    begin
      AImage.SetWidth(AWidth + 3);
      Result := PreservedHash(AImage.PixelsPointer, (AWidth + 3) * AImage.BytesPerPixel,
        AWidth * AImage.BytesPerPixel, AHeight);
    end;
    18:
    begin
      AImage.SetHeight(AHeight + 2);
      Result := PreservedHash(AImage.PixelsPointer, AWidth * AImage.BytesPerPixel,
        AWidth * AImage.BytesPerPixel, AHeight);
    end;
    19:
    begin
      SetLength(LBuffer, AHeight);
      for LColumn := 0 to AHeight - 1 do
        LBuffer[LColumn] := $11000000 + Cardinal(LColumn) * 977;
      AImage.SetColumn32(AWidth div 2, @LBuffer[0]);
    end;
    20:
    begin
      SetLength(LBuffer, AWidth);
      for LColumn := 0 to AWidth - 1 do
        LBuffer[LColumn] := $22000000 + Cardinal(LColumn) * 733;
      AImage.SetRow32(AHeight div 2, @LBuffer[0]);
    end;
    21:
    begin
      AImage.SwapRGB;
      AImage.SwapRGB;
    end;
    22:
    begin
      AImage.ConvertTo32bit;
      AImage.TransparentColor := PCardinal(AImage.PixelsPointer)^;
      AImage.TransparentColor2 := PTextureColorArray(AImage.PixelsPointer)^[Ord(AWidth * AHeight > 1)];
      AImage.TransparentColor3 := PTextureColorArray(AImage.PixelsPointer)^[Ord(AWidth * AHeight > 2) * 2];
      TTextureAlpha.SetDefaultChannel(AImage);
    end;
    23:
    begin
      AImage.ScaleTo(AWidth + 2, AHeight * 2);
      AImage.ConvertTo32bit;
    end;
  end;
end;

end.
