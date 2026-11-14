{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Texture library - reads the golden files           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Tests.Texture.Samples;

type
  /// <summary>
  ///   Tests\Data\Texture\*.golden.txt: one "name=value" line for each case, written by a harness
  ///   that ran the old code of TEXLIB on the inputs of the Samples unit
  /// </summary>
  TTextureGolden = class sealed
  public
    class function DataDir: string; static;
    class function Load(const AFile: string): TStringList; static;
    /// <summary>The golden value of a case; fails the test if the file or the case is missing</summary>
    class function Value(const AFile, AName: string): string; static;
    class procedure Check(const AFile, AName, AActual: string); static;
    /// <summary>What the new decoders give for a file, in the form of the golden files</summary>
    class function Decode(const AFormats: ITextureFormats; const AFile: TTextureSampleFile;
      ASwap: Boolean): string; static;
    /// <summary>
    ///   Checks every file of a list against the golden file (what it has for the files that the
    ///   old code did not read the same way is checked by the tests of the decoders)
    /// </summary>
    class procedure CheckFiles(const AFormats: ITextureFormats; const AGolden: string;
      const AFiles: TTextureSampleFiles); static;
  end;

implementation

{ TTextureGolden }

class function TTextureGolden.DataDir: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Texture\'));
end;

class function TTextureGolden.Load(const AFile: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.NameValueSeparator := '=';
    Result.LoadFromFile(TPath.Combine(DataDir, AFile));
  except
    Result.Free;
    raise;
  end;
end;

class function TTextureGolden.Value(const AFile, AName: string): string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := Load(AFile);
  try
    LIndex := LLines.IndexOfName(AName);
    if LIndex < 0 then
      raise Exception.CreateFmt('The case "%s" is not in %s', [AName, AFile]);
    Result := LLines.ValueFromIndex[LIndex];
  finally
    LLines.Free;
  end;
end;

class procedure TTextureGolden.Check(const AFile, AName, AActual: string);
begin
  Assert.AreEqual(Value(AFile, AName), AActual, AFile + ': ' + AName);
end;

class function TTextureGolden.Decode(const AFormats: ITextureFormats; const AFile: TTextureSampleFile;
  ASwap: Boolean): string;
var
  LImage: TTextureImage;
  LOk: Boolean;
begin
  LImage := TTextureImage.Create;
  try
    try
      LOk := AFormats.Decode(AFile.Extension, AFile.Bytes, LImage);
      if ASwap and LOk then
        LImage.SwapRGB;
      Result := TTextureSamples.Describe(LOk, LImage, AFile.ShapeOnly and not ASwap, AFile.PaletteCompare);
    except
      on E: Exception do
        Result := 'EXC:' + E.ClassName;
    end;
  finally
    LImage.Free;
  end;
end;

class procedure TTextureGolden.CheckFiles(const AFormats: ITextureFormats; const AGolden: string;
  const AFiles: TTextureSampleFiles);
var
  LLines: TStringList;
  LFile: TTextureSampleFile;

  procedure CheckLine(const AName, AActual: string);
  var
    LIndex: Integer;
  begin
    LIndex := LLines.IndexOfName(AName);
    if LIndex < 0 then
      Assert.Fail('Manca il caso ' + AName + ' in ' + AGolden);
    Assert.AreEqual(LLines.ValueFromIndex[LIndex], AActual, AGolden + ': ' + AName);
  end;

begin
  LLines := Load(AGolden);
  try
    for LFile in AFiles do
    begin
      if LFile.KnownDifference then
        Continue;
      CheckLine(LFile.Name, Decode(AFormats, LFile, False));
      // the 16 bit images were black in the old code
      if (not LFile.ShapeOnly) and (Copy(LFile.Name, 1, 10) <> 'tga-true16') then
        CheckLine(LFile.Name + '@swap', Decode(AFormats, LFile, True));
    end;
  finally
    LLines.Free;
  end;
end;

end.
