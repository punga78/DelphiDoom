{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - parity with the old  }
{  code of r_data.R_InitTextures and r_flatinfo                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Tests.TextureDefs.Corpus;

type
  /// <summary>
  ///   The files *.golden.txt in Tests\Data\TextureDefs were written by the old code (the loops of
  ///   R_InitTextures, built for the standard layout and for the one of Strife, and
  ///   R_ParseFlatInfoText) on the lumps built from cases.txt and, for wad.*.golden.txt, on the
  ///   WADs of bin\ (a digest of the dump: these tests are skipped if the WAD is missing).
  ///   The library has to give the same dump, case by case
  /// </summary>
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsParity = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    class procedure SplitSections(ALines: TStrings; ASections: TDictionary<string, string>); static;
    function DumpTextures(ACase: TTextureDefsCase): string;
    function DumpFlats(ACase: TTextureDefsCase): string;
    procedure CompareWithGolden(const AGoldenFile: string; AStrife: Boolean);
  public
    [Test]
    procedure TestTexturesOfTheStandardLayoutAsTheOldCode;
    [Test]
    procedure TestTexturesOfStrifeAsTheOldCode;
    [Test]
    procedure TestFlatInfoAsTheOldCode;
    [Test]
    [TestCase('doom', 'Doom\DOOM1.WAD,standard')]
    [TestCase('freedoom2', 'Doom\FREEDOOM2.WAD,standard')]
    [TestCase('heretic', 'Heretic\HERETIC1.WAD,standard')]
    [TestCase('hexen', 'Hexen\HEXEN.WAD,standard')]
    [TestCase('strife', 'Strife\STRIFE0.WAD,strife')]
    procedure TestRealWadAsTheOldCode(const AWadPath, ALayout: string);
  end;

implementation

uses
  DelphiDoom.Logging.Intf, DelphiDoom.TextureDefs.Types, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Factory,
  DelphiDoom.Tests.TextureDefs.Fakes;

{ TTestTextureDefsParity }

function TTestTextureDefsParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\TextureDefs\' + AFileName));
end;

class procedure TTestTextureDefsParity.SplitSections(ALines: TStrings; ASections: TDictionary<string, string>);
var
  LIndex: Integer;
  LName: string;
  LText: string;
begin
  LName := '';
  LText := '';
  for LIndex := 0 to ALines.Count - 1 do
    if Copy(ALines[LIndex], 1, 4) = '=== ' then
    begin
      if LName <> '' then
        ASections.AddOrSetValue(LName, LText);
      LName := Copy(ALines[LIndex], 5, MaxInt);
      LText := '';
    end
    else
      LText := LText + ALines[LIndex] + #10;
  if LName <> '' then
    ASections.AddOrSetValue(LName, LText);
end;

function TTestTextureDefsParity.DumpTextures(ACase: TTextureDefsCase): string;
var
  LSource: TFakeLumpSource;
  LSourceIntf: ITextureDefsLumpSource;
  LFormat: TTextureDefsFormat;
  LSet: TTextureDefsSet;
  LTexture: TTextureDefsTexture;
  LPatch: TTextureDefsPatch;
begin
  LSource := TFakeLumpSource.Create;
  LSourceIntf := LSource;
  LSource.SetLump('PNAMES', ACase.BuildPatchNames);
  LSource.SetLump('TEXTURE1', ACase.BuildTextureLumpNumber(1));
  if ACase.HasTextureLump(2) then
    LSource.SetLump('TEXTURE2', ACase.BuildTextureLumpNumber(2));
  if ACase.HasTextureLump(3) then
    LSource.SetLump('TEXTURE3', ACase.BuildTextureLumpNumber(3));
  if ACase.HasPk3 then
    LSource.SetLump('TEXTURE0', ACase.BuildPk3Lump);
  if ACase.IsStrife then
    LFormat := TTextureDefsFormat.Strife
  else
    LFormat := TTextureDefsFormat.Standard;

  Result := '';
  try
    LSet := TTextureDefsFactory.CreateLoader(LSourceIntf, LFormat).Load(ACase.HasPk3);
  except
    on E: ETextureDefsException do
      if E.Code = TTextureDefsError.BadDirectory then
        Exit('E|bad texture directory'#10)
      else
        raise;
  end;
  for LTexture in LSet.Textures do
    if LTexture.Origin = TTextureDefsOrigin.Pk3 then
      Result := Result + Format('K|%s|%d|%d|%d|%d|%d|%s'#10, [LTexture.Name, LTexture.Width,
        LTexture.Height, LTexture.Masked, LTexture.Patches[0].OriginX, LTexture.Patches[0].OriginY,
        LTexture.Patches[0].PatchName])
    else
    begin
      Result := Result + Format('T|%s|%d|%d|%d|%d'#10, [LTexture.Name, LTexture.Width,
        LTexture.Height, LTexture.Masked, Length(LTexture.Patches)]);
      for LPatch in LTexture.Patches do
        Result := Result + Format('P|%d|%s|%d|%d'#10, [LPatch.PatchIndex, LPatch.PatchName,
          LPatch.OriginX, LPatch.OriginY]);
    end;
end;

function TTestTextureDefsParity.DumpFlats(ACase: TTextureDefsCase): string;
var
  LLog: TFakeLog;
  LLogIntf: ILog;
  LSizes: TArray<TTextureDefsFlatSize>;
  LFlatSizes: TArray<Integer>;
  LEntry: TTextureDefsFlatSize;
  LIndex: Integer;
  LWarning: string;
begin
  LLog := TFakeLog.Create;
  LLogIntf := LLog;
  LSizes := TTextureDefsFactory.CreateFlatInfoParser(LLogIntf).Parse(ACase.Text,
    TFakeFlatCatalog.Create(ACase.Flats));
  SetLength(LFlatSizes, Length(ACase.Flats));
  for LEntry in LSizes do
    LFlatSizes[LEntry.FlatIndex] := LEntry.SizeCode;
  Result := '';
  for LIndex := 0 to High(LFlatSizes) do
    Result := Result + Format('S|%d|%d'#10, [LIndex, LFlatSizes[LIndex]]);
  for LWarning in LLog.Warnings do
    Result := Result + 'W|' + LWarning.Replace(#13, '\r').Replace(#10, '\n') + #10;
end;

procedure TTestTextureDefsParity.CompareWithGolden(const AGoldenFile: string; AStrife: Boolean);
var
  LCases: TObjectList<TTextureDefsCase>;
  LCase: TTextureDefsCase;
  LLines: TStringList;
  LGolden: TDictionary<string, string>;
  LMismatches: string;
  LChecked: Integer;
  LActual: string;
begin
  LCases := TTextureDefsCorpus.Load(DataPath('cases.txt'));
  LLines := TStringList.Create;
  LGolden := TDictionary<string, string>.Create;
  try
    LLines.LoadFromFile(DataPath(AGoldenFile));
    SplitSections(LLines, LGolden);
    LMismatches := '';
    LChecked := 0;
    for LCase in LCases do
    begin
      if LCase.IsFlats or (LCase.IsStrife <> AStrife) then
        Continue;
      Assert.IsTrue(LGolden.ContainsKey(LCase.Name), 'il caso ' + LCase.Name + ' dovrebbe essere nel golden');
      LActual := DumpTextures(LCase);
      Inc(LChecked);
      if LActual <> LGolden[LCase.Name] then
        LMismatches := LMismatches + ' ' + LCase.Name;
    end;
    Assert.IsTrue(LChecked >= 4, 'dovrebbe provare dei casi');
    Assert.AreEqual('', LMismatches, 'dovrebbe dare lo stesso dump del vecchio codice');
  finally
    LGolden.Free;
    LLines.Free;
    LCases.Free;
  end;
end;

procedure TTestTextureDefsParity.TestTexturesOfTheStandardLayoutAsTheOldCode;
begin
  CompareWithGolden('textures.standard.golden.txt', False);
end;

procedure TTestTextureDefsParity.TestTexturesOfStrifeAsTheOldCode;
begin
  CompareWithGolden('textures.strife.golden.txt', True);
end;

procedure TTestTextureDefsParity.TestFlatInfoAsTheOldCode;
var
  LCases: TObjectList<TTextureDefsCase>;
  LCase: TTextureDefsCase;
  LLines: TStringList;
  LGolden: TDictionary<string, string>;
  LMismatches: string;
  LChecked: Integer;
begin
  LCases := TTextureDefsCorpus.Load(DataPath('cases.txt'));
  LLines := TStringList.Create;
  LGolden := TDictionary<string, string>.Create;
  try
    LLines.LoadFromFile(DataPath('textures.standard.golden.txt'));
    SplitSections(LLines, LGolden);
    LMismatches := '';
    LChecked := 0;
    for LCase in LCases do
    begin
      if not LCase.IsFlats then
        Continue;
      Assert.IsTrue(LGolden.ContainsKey(LCase.Name), 'il caso ' + LCase.Name + ' dovrebbe essere nel golden');
      Inc(LChecked);
      if DumpFlats(LCase) <> LGolden[LCase.Name] then
        LMismatches := LMismatches + ' ' + LCase.Name;
    end;
    Assert.IsTrue(LChecked > 10, 'dovrebbe provare dei casi');
    Assert.AreEqual('', LMismatches, 'dovrebbe dare lo stesso dump del vecchio codice');
  finally
    LGolden.Free;
    LLines.Free;
    LCases.Free;
  end;
end;

procedure TTestTextureDefsParity.TestRealWadAsTheOldCode(const AWadPath, ALayout: string);
var
  LWadFile: string;
  LWad: TCorpusWad;
  LWadIntf: ITextureDefsLumpSource;
  LGoldenLines: TStringList;
  LGolden: TDictionary<string, string>;
  LSet: TTextureDefsSet;
  LTexture: TTextureDefsTexture;
  LPatch: TTextureDefsPatch;
  LDump: TStringList;
  LText: string;
  LFormat: TTextureDefsFormat;
  LExpected: string;
  LWadName: string;
begin
  LWadFile := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\' + AWadPath));
  if not TFile.Exists(LWadFile) then
  begin
    Assert.Pass('WAD mancante: prova saltata');
    Exit;
  end;
  LWadName := TPath.GetFileName(LWadFile);
  if ALayout = 'strife' then
    LFormat := TTextureDefsFormat.Strife
  else
    LFormat := TTextureDefsFormat.Standard;

  LGoldenLines := TStringList.Create;
  LGolden := TDictionary<string, string>.Create;
  LDump := TStringList.Create;
  try
    LGoldenLines.LoadFromFile(DataPath('wad.' + ALayout + '.golden.txt'));
    SplitSections(LGoldenLines, LGolden);
    Assert.IsTrue(LGolden.ContainsKey(LWadName), 'dovrebbe essere nel golden');

    LWad := TCorpusWad.Create(LWadFile);
    try
      LWadIntf := TWadSourceAdapter.Create(LWad);
      LSet := TTextureDefsFactory.CreateLoader(LWadIntf, LFormat).Load(False);
    finally
      LWadIntf := nil;
      LWad.Free;
    end;

    for LTexture in LSet.Textures do
    begin
      LDump.Add(Format('T|%s|%d|%d|%d|%d', [LTexture.Name, LTexture.Width, LTexture.Height,
        LTexture.Masked, Length(LTexture.Patches)]));
      for LPatch in LTexture.Patches do
        LDump.Add(Format('P|%d|%s|%d|%d', [LPatch.PatchIndex, LPatch.PatchName, LPatch.OriginX,
          LPatch.OriginY]));
    end;
    LText := LDump.Text;
    LExpected := Format('count|%d'#10'fnv|%u'#10'first|%s'#10'last|%s'#10, [LDump.Count,
      TTextureDefsCorpus.Fnv32(LText), LDump[0], LDump[LDump.Count - 1]]);
    Assert.AreEqual(LGolden[LWadName], LExpected, 'dovrebbe dare lo stesso digest del vecchio codice');
  finally
    LDump.Free;
    LGolden.Free;
    LGoldenLines.Free;
  end;
end;

end.
