{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the id Tech 4 images - golden files and test images    }
{                                                                              }
{  Tests\Data\IdImages\idimage.golden.txt was written by a harness that        }
{  compiled the real functions of Doom 3 (Image_process.cpp, Image_program.cpp,}
{  Image_files.cpp, Image_load.cpp) with bcc32c and ran them on the images     }
{  that TIdImagesGolden.Generate builds (an LCG, no texture of the game).      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdImages.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Imaging.Rgba.Image;

type
  TIdImagesGolden = class sealed
  strict private
    class var FLines: TStringList;
  public
    class function DataDir: string; static;
    /// <summary>The image of the harness: an LCG, with 0 and 128 bytes now and then when ASpecial</summary>
    class function Generate(const AWidth, AHeight: Integer; const ASeed: Cardinal;
      const ASpecial: Boolean): TImagingRgbaImage; static;
    /// <summary>"CRC32 width height" of an image, as the harness prints it</summary>
    class function Describe(const AImage: TImagingRgbaImage): string; static;
    class function Value(const AName: string): string; static;
    class procedure Check(const AName: string; const AImage: TImagingRgbaImage); static;
    /// <summary>
    ///   Compares with a golden line of hex bytes: every byte within ATolerance and at most
    ///   AMaxDifferent bytes that are not equal
    /// </summary>
    class procedure CheckClose(const AName: string; const AImage: TImagingRgbaImage;
      const ATolerance, AMaxDifferent: Integer); static;
    class function ReadFile(const ARelativePath: string): TBytes; static;
    /// <summary>The 128 bytes of a "ddsheadN" line (hex, then the number of levels)</summary>
    class function HeaderBytes(const AName: string): TBytes; static;
    class destructor Destroy;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32;

{ TIdImagesGolden }

class function TIdImagesGolden.DataDir: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\IdImages\'));
end;

class function TIdImagesGolden.Generate(const AWidth, AHeight: Integer; const ASeed: Cardinal;
  const ASpecial: Boolean): TImagingRgbaImage;
var
  LSeed, LValue, LSpecial: Cardinal;
  LIndex: Integer;
  LByte: Byte;
begin
  Result := TImagingRgbaImage.Create(AWidth, AHeight);
  LSeed := ASeed;
  for LIndex := 0 to AWidth * AHeight * 4 - 1 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    LValue := LSeed;
    LByte := Byte(LValue shr 24);
    if ASpecial then
    begin
      LSpecial := (LValue shr 8) and 15;
      if LSpecial = 0 then
        LByte := 0
      else if LSpecial = 1 then
        LByte := 128;
    end;
    Result.Pixels[LIndex] := LByte;
  end;
end;

class function TIdImagesGolden.Describe(const AImage: TImagingRgbaImage): string;
begin
  Result := Format('%s %d %d', [UpperCase(TCrc32.ToHex(TCrc32.Calculate(AImage.Pixels[0],
    Length(AImage.Pixels)))), AImage.Width, AImage.Height]);
end;

class function TIdImagesGolden.Value(const AName: string): string;
var
  LIndex: Integer;
begin
  if not Assigned(FLines) then
  begin
    FLines := TStringList.Create;
    FLines.NameValueSeparator := '=';
    FLines.LoadFromFile(TPath.Combine(DataDir, 'idimage.golden.txt'));
  end;
  LIndex := FLines.IndexOfName(AName);
  if LIndex < 0 then
    raise Exception.CreateFmt('The case "%s" is not in idimage.golden.txt', [AName]);
  Result := FLines.ValueFromIndex[LIndex];
end;

class procedure TIdImagesGolden.Check(const AName: string; const AImage: TImagingRgbaImage);
begin
  Assert.AreEqual(Value(AName), Describe(AImage), AName);
end;

class procedure TIdImagesGolden.CheckClose(const AName: string; const AImage: TImagingRgbaImage;
  const ATolerance, AMaxDifferent: Integer);
var
  LHex: string;
  LIndex, LDifferent, LDistance: Integer;
begin
  LHex := Value(AName);
  Assert.AreEqual<Integer>(Length(AImage.Pixels) * 2, Length(LHex), AName + ' length');
  LDifferent := 0;
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    LDistance := Abs(Integer(AImage.Pixels[LIndex]) - StrToInt('$' + Copy(LHex, LIndex * 2 + 1, 2)));
    Assert.IsTrue(LDistance <= ATolerance, Format('%s: byte %d is %d away', [AName, LIndex, LDistance]));
    if LDistance <> 0 then
      Inc(LDifferent);
  end;
  Assert.IsTrue(LDifferent <= AMaxDifferent, Format('%s: %d bytes differ', [AName, LDifferent]));
end;

class function TIdImagesGolden.ReadFile(const ARelativePath: string): TBytes;
begin
  Result := TFile.ReadAllBytes(TPath.Combine(DataDir, ARelativePath));
end;

class function TIdImagesGolden.HeaderBytes(const AName: string): TBytes;
var
  LHex: string;
  LIndex: Integer;
begin
  LHex := Copy(Value(AName), 1, 256);
  SetLength(Result, Length(LHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(StrToInt('$' + Copy(LHex, LIndex * 2 + 1, 2)));
end;

class destructor TIdImagesGolden.Destroy;
begin
  FLines.Free;
end;

end.
