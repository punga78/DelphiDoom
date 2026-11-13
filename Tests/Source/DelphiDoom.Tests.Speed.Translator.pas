{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedTranslator                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.Translator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf, DelphiDoom.Tests.Speed.Fakes;

type
  /// <summary>
  ///   Tests\Data\Speed\translation.*.golden.txt are the lumps (number, name, size and FNV-1a) that the
  ///   TSpeedToWADConverter of the fork (speed_xlat_wad.pas) made, compiled in a throwaway harness
  ///   outside the repository with the minimum of changes to build with Delphi 11 (see
  ///   Tests\Data\Speed\README.md), on the synthetic game of TJclBuilder and on SPEEDH.JCL (the shareware
  ///   of Speed Haste; the test is skipped when the file is missing). The lines "pak" are the files that
  ///   the old code added to the PAK file system
  /// </summary>
  [TestFixture]
  [Category('speed')]
  TTestSpeedTranslator = class(TObject)
  strict private
    FLog: TFakeLog;
    FLogReference: IInterface;
    FWad: IGameWadComposer;
    FTranslator: ISpeedTranslator;
    function Dump(const AWad: IGameWadComposer; const APak: TArray<TSpeedPakEntry>): TArray<string>;
    function ReadGolden(const AFileName: string): TArray<string>;
    function FindShareware: string;
    function Translate(const AGame: TBytes): TArray<TSpeedPakEntry>;
    function IndexOfLump(const AName: string): Integer;
    function Words(const ABytes: TBytes; AOffset: Integer): SmallInt;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareGliStessiLumpDelVecchioCodiceSulGiocoSintetico;
    [Test]
    procedure DovrebbeDareGliStessiLumpDelVecchioCodiceSuSpeedHasteShareware;
    [Test]
    procedure DovrebbeDareLeStesseVoceDelPakDelVecchioCodice;
    [Test]
    procedure DovrebbeScrivereLaPalettaELeMappeDeiColori;
    [Test]
    procedure DovrebbeScrivereLeTextureDeiMuriEIlPnames;
    [Test]
    procedure DovrebbeScrivereUnaTexturaConLeMisureDellaImmagine;
    [Test]
    procedure DovrebbeToglierelUltimaColonnaDeiMuri;
    [Test]
    procedure DovrebbeLeggereUnMuroLaCuiDimensioneDichiarataEPiccola;
    [Test]
    procedure DovrebbeFareLeVentiquattroTraduzioniDelFlatSessantadue;
    [Test]
    procedure DovrebbeScrivereLeDimensioniDeiFlatNelLumpFlatsize;
    [Test]
    procedure DovrebbeFareUnFlatDiSediciMegabytePerOgniCircuito;
    [Test]
    procedure DovrebbeFareIlLivelloEIlSuoMapdata;
    [Test]
    procedure DovrebbeLasciareFuoriIlCircuitoSenzaTuttiIFile;
    [Test]
    procedure DovrebbeFareIFontInCinqueColori;
    [Test]
    procedure DovrebbeFareLeParoleDelSoundInfoEIDieciMotori;
    [Test]
    procedure DovrebbeDareIModelliCheIlMotoreDeveAggiungereAlPak;
    [Test]
    procedure DovrebbeScrivereLaListaDeiFileInSpeedinf;
    [Test]
    procedure DovrebbeAvvisareDiUnaImmagineCheNonELo;
    [Test]
    procedure DovrebbeAvvisareDiUnaImmagineTroppoAlta;
    [Test]
    procedure DovrebbeLasciareLaMusicaSeManca;
    [Test]
    procedure DovrebbeFunzionareConUnContenitoreVuoto;
    [Test]
    procedure DovrebbeAvvisareDiUnaPalettaCorta;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaNil;
    [Test]
    procedure DovrebbeRifiutareUnContenitoreNil;
  end;

implementation

uses
  DelphiDoom.GameData.Types, DelphiDoom.GameData.Factory, DelphiDoom.Palette.Factory,
  DelphiDoom.Speed.Factory, DelphiDoom.Speed.Translator, DelphiDoom.Speed.PaletteBuilder,
  DelphiDoom.Speed.Is2Decoder, DelphiDoom.Speed.CircuitReader, DelphiDoom.Speed.LevelBuilder,
  DelphiDoom.Speed.FontBuilder, DelphiDoom.Speed.MapBitmapBuilder, DelphiDoom.Speed.Names,
  DelphiDoom.Tests.Speed.JclBuilder, DelphiDoom.Tests.GameData.Scenarios;

{ TTestSpeedTranslator }

procedure TTestSpeedTranslator.Setup;
begin
  FLog := TFakeLog.Create;
  FLogReference := FLog;
  FWad := TGameDataFactory.CreateWadComposer;
  FTranslator := TSpeedFactory.CreateTranslator(FLog);
end;

procedure TTestSpeedTranslator.TearDown;
begin
  FTranslator := nil;
  FWad := nil;
  FLogReference := nil;
end;

function TTestSpeedTranslator.Translate(const AGame: TBytes): TArray<TSpeedPakEntry>;
begin
  Result := FTranslator.Translate(TSpeedFactory.OpenContainerBytes(AGame), FWad);
end;

function TTestSpeedTranslator.IndexOfLump(const AName: string): Integer;
begin
  Result := FWad.IndexOf(AName);
  Assert.IsTrue(Result >= 0, 'lump ' + AName);
end;

function TTestSpeedTranslator.Words(const ABytes: TBytes; AOffset: Integer): SmallInt;
begin
  Result := PSmallInt(@ABytes[AOffset])^;
end;

function TTestSpeedTranslator.Dump(const AWad: IGameWadComposer; const APak: TArray<TSpeedPakEntry>): TArray<string>;
var
  LIndex: Integer;
  LData: TBytes;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  try
    LList.Add('lumps ' + IntToStr(AWad.Count));
    for LIndex := 0 to AWad.Count - 1 do
    begin
      LData := AWad.LumpData[LIndex];
      if Length(LData) > 0 then
        LList.Add(Format('%d %s %d %s', [LIndex, AWad.LumpNames[LIndex], Length(LData),
          TGameDataScenarios.Digest(LData)]))
      else
        LList.Add(Format('%d %s 0 00000000', [LIndex, AWad.LumpNames[LIndex]]));
    end;
    for LIndex := 0 to High(APak) do
      LList.Add(Format('pak %d %d %s', [APak[LIndex].Position, APak[LIndex].Size, APak[LIndex].Name]));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TTestSpeedTranslator.ReadGolden(const AFileName: string): TArray<string>;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Speed\' + AFileName)));
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

function TTestSpeedTranslator.FindShareware: string;
var
  LRoot: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..'));
  LCandidates := [TPath.Combine(LRoot, 'bin\Speed\SPEEDH.JCL'), TPath.Combine(LRoot, 'Reference\_dati\speed\SPEEDH.JCL'),
    // the worktrees of the repository are under .claude\worktrees\<name>
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\speed\SPEEDH.JCL'))];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

procedure TTestSpeedTranslator.DovrebbeDareGliStessiLumpDelVecchioCodiceSulGiocoSintetico;
var
  LPak: TArray<TSpeedPakEntry>;
  LActual: TArray<string>;
  LGolden: TArray<string>;
  LIndex: Integer;
begin
  LPak := Translate(TJclBuilder.SyntheticGame);
  LActual := Dump(FWad, LPak);
  LGolden := ReadGolden('translation.synthetic.golden.txt');
  Assert.AreEqual(Length(LGolden), Length(LActual), 'number of lines');
  for LIndex := 0 to High(LGolden) do
    Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'line ' + IntToStr(LIndex));
end;

procedure TTestSpeedTranslator.DovrebbeDareGliStessiLumpDelVecchioCodiceSuSpeedHasteShareware;
var
  LPath: string;
  LPak: TArray<TSpeedPakEntry>;
  LActual: TArray<string>;
  LGolden: TArray<string>;
  LIndex: Integer;
begin
  LPath := FindShareware;
  if LPath = '' then
  begin
    Assert.Pass('SPEEDH.JCL is not there');
    Exit;
  end;
  LPak := FTranslator.Translate(TSpeedFactory.OpenContainer(LPath), FWad);
  LActual := Dump(FWad, LPak);
  LGolden := ReadGolden('translation.shareware.golden.txt');
  Assert.AreEqual(Length(LGolden), Length(LActual), 'number of lines');
  for LIndex := 0 to High(LGolden) do
    Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'line ' + IntToStr(LIndex));
end;

procedure TTestSpeedTranslator.DovrebbeDareLeStesseVoceDelPakDelVecchioCodice;
var
  LPak: TArray<TSpeedPakEntry>;
begin
  LPak := Translate(TJclBuilder.SyntheticGame);
  Assert.AreEqual<Integer>(2, Length(LPak));
  Assert.AreEqual('MODELS\CAR0N0A.I3D', LPak[0].Name);
  Assert.AreEqual(77, LPak[0].Size);
  Assert.AreEqual('MODELS\XPR061.I3D', LPak[1].Name);
end;

procedure TTestSpeedTranslator.DovrebbeScrivereLaPalettaELeMappeDeiColori;
begin
  Translate(TJclBuilder.SyntheticGame);
  Assert.AreEqual(0, IndexOfLump('PLAYPAL'));
  Assert.AreEqual<Integer>(14 * 768, Length(FWad.LumpData[0]));
  Assert.AreEqual(1, IndexOfLump('COLORMAP'));
  Assert.AreEqual<Integer>(34 * 256, Length(FWad.LumpData[1]));
end;

procedure TTestSpeedTranslator.DovrebbeScrivereLeTextureDeiMuriEIlPnames;
var
  LNames: TBytes;
  LTextures: TBytes;
begin
  Translate(TJclBuilder.SyntheticGame);
  LNames := FWad.LumpData[IndexOfLump('PNAMES')];
  LTextures := FWad.LumpData[IndexOfLump('TEXTURE1')];
  // the stub, 4 walls and 7 skies
  Assert.AreEqual(12, Integer(PInteger(@LNames[0])^));
  Assert.AreEqual(12, Integer(PInteger(@LTextures[0])^));
  Assert.AreEqual('AA0000', string(AnsiString(PAnsiChar(@LNames[4]))));
  Assert.AreEqual('WALL1', string(AnsiString(PAnsiChar(@LNames[12]))));
  Assert.AreEqual('WALL2', string(AnsiString(PAnsiChar(@LNames[20]))));
  Assert.AreEqual('WALL3', string(AnsiString(PAnsiChar(@LNames[28]))));
  Assert.AreEqual('WALL10', string(AnsiString(PAnsiChar(@LNames[36]))));
  Assert.AreEqual('SKY1', string(AnsiString(PAnsiChar(@LNames[44]))));
  Assert.AreEqual<Integer>(4 + 12 * 8, Length(LNames));
  Assert.AreEqual<Integer>(4 + 12 * 4 + 12 * 32, Length(LTextures));
  Assert.AreEqual<Integer>(4, Length(FWad.LumpData[IndexOfLump('TEXTURE2')]));
end;

procedure TTestSpeedTranslator.DovrebbeScrivereUnaTexturaConLeMisureDellaImmagine;
var
  LTextures: TBytes;
  LOffset: Integer;
begin
  Translate(TJclBuilder.SyntheticGame);
  LTextures := FWad.LumpData[IndexOfLump('TEXTURE1')];
  // the texture 1 (after the stub): WALL1, the picture of 20 x 30 without the last column
  LOffset := PInteger(@LTextures[4 + 1 * 4])^;
  Assert.AreEqual<SmallInt>(19, Words(LTextures, LOffset + 12), 'width');
  Assert.AreEqual<SmallInt>(30, Words(LTextures, LOffset + 14), 'height');
  Assert.AreEqual<SmallInt>(1, Words(LTextures, LOffset + 20), 'one patch');
  Assert.AreEqual<SmallInt>(1, Words(LTextures, LOffset + 26), 'the patch 1 of PNAMES');
end;

procedure TTestSpeedTranslator.DovrebbeToglierelUltimaColonnaDeiMuri;
var
  LWall: TBytes;
begin
  Translate(TJclBuilder.SyntheticGame);
  LWall := FWad.LumpData[IndexOfLump('WALL1')];
  Assert.AreEqual<SmallInt>(19, Words(LWall, 0));
  Assert.AreEqual<SmallInt>(30, Words(LWall, 2));
end;

procedure TTestSpeedTranslator.DovrebbeLeggereUnMuroLaCuiDimensioneDichiarataEPiccola;
var
  LWall: TBytes;
begin
  // the directory says 100 bytes for the wall 3 and the picture is longer
  Translate(TJclBuilder.SyntheticGame);
  LWall := FWad.LumpData[IndexOfLump('WALL3')];
  Assert.AreEqual<SmallInt>(11, Words(LWall, 0));
  Assert.AreEqual<SmallInt>(12, Words(LWall, 2));
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestSpeedTranslator.DovrebbeFareLeVentiquattroTraduzioniDelFlatSessantadue;
var
  LIndex: Integer;
  LFlat: TBytes;
  LPlain: TBytes;
  LPixel: Integer;
  LExpected: Integer;
begin
  Translate(TJclBuilder.SyntheticGame);
  LPlain := FWad.LumpData[IndexOfLump('FLAT0062')];
  Assert.AreEqual<Integer>(4096, Length(LPlain));
  for LIndex := 1 to 24 do
  begin
    LFlat := FWad.LumpData[IndexOfLump('FTRN' + TSpeedNames.ZeroFill(4, LIndex))];
    Assert.AreEqual<Integer>(4096, Length(LFlat));
    for LPixel := 0 to 4095 do
      if LPlain[LPixel] in [64..79] then
      begin
        LExpected := SPEED_TRANSLATION_ROVERS[LIndex] + (LPlain[LPixel] - 64) div 2;
        Assert.AreEqual<Byte>(Byte(LExpected), LFlat[LPixel]);
      end
      else
        Assert.AreEqual<Byte>(LPlain[LPixel], LFlat[LPixel]);
  end;
end;

procedure TTestSpeedTranslator.DovrebbeScrivereLeDimensioniDeiFlatNelLumpFlatsize;
var
  LText: string;
begin
  Translate(TJclBuilder.SyntheticGame);
  LText := TEncoding.ASCII.GetString(FWad.LumpData[IndexOfLump(SPEED_FLAT_SIZE_LUMP)]);
  Assert.IsTrue(LText.Contains('FLAT0001=128'#13#10));
  Assert.IsTrue(LText.Contains('FTRN0024=128'#13#10));
  Assert.IsTrue(LText.Contains('F_SKY1=64'#13#10));
  Assert.IsTrue(LText.Contains('FMAP00=8192'#13#10));
end;

procedure TTestSpeedTranslator.DovrebbeFareUnFlatDiSediciMegabytePerOgniCircuito;
begin
  Translate(TJclBuilder.SyntheticGame);
  Assert.AreEqual<Integer>(4096 * 4096, Length(FWad.LumpData[IndexOfLump('FMAP00')]));
  Assert.AreEqual<Integer>(4096 * 4096, Length(FWad.LumpData[IndexOfLump('FMAP01')]));
  // MAP02 has the tiles but not the other files: its floor is made, its level is not
  Assert.AreEqual<Integer>(4096 * 4096, Length(FWad.LumpData[IndexOfLump('FMAP02')]));
end;

procedure TTestSpeedTranslator.DovrebbeFareIlLivelloEIlSuoMapdata;
var
  LText: string;
  LIndex: Integer;
begin
  Translate(TJclBuilder.SyntheticGame);
  IndexOfLump('E1M1');
  IndexOfLump('E1M2');
  for LIndex := 0 to FWad.Count - 1 do
    if FWad.LumpNames[LIndex] = 'MAPDATA' then
      Break;
  LText := TEncoding.ASCII.GetString(FWad.LumpData[LIndex]);
  Assert.IsTrue(LText.StartsWith('sprite=MAPSPR00'#13#10'sky=NUBES0'#13#10'mountain=MOUNT0'#13#10'ground=FLAT'));
  Assert.IsTrue(LText.Contains('name=Circuit 0 of Speed'#13#10'length=2000'#13#10'best=1000'#13#10'level=0'#13#10));
end;

procedure TTestSpeedTranslator.DovrebbeLasciareFuoriIlCircuitoSenzaTuttiIFile;
begin
  Translate(TJclBuilder.SyntheticGame);
  Assert.AreEqual(-1, FWad.IndexOf('E1M3'));
end;

procedure TTestSpeedTranslator.DovrebbeFareIFontInCinqueColori;
var
  LIndex: Integer;
  LSmall: Integer;
  LBig: Integer;
  LMarkers: Integer;
  LName: string;
  LPatch: TBytes;
begin
  Translate(TJclBuilder.SyntheticGame);
  LSmall := 0;
  LBig := 0;
  LMarkers := 0;
  for LIndex := 0 to FWad.Count - 1 do
  begin
    LName := FWad.LumpNames[LIndex];
    if LName = 'FN_START' then
      Inc(LMarkers)
    else if LName.StartsWith('SFNT') then
    begin
      Inc(LSmall);
      LPatch := FWad.LumpData[LIndex];
      Assert.AreEqual<SmallInt>(8, Words(LPatch, 0), LName);
      Assert.AreEqual<SmallInt>(8, Words(LPatch, 2), LName);
    end
    else if LName.StartsWith('BFNT') then
    begin
      Inc(LBig);
      LPatch := FWad.LumpData[LIndex];
      Assert.AreEqual<SmallInt>(16, Words(LPatch, 2), LName);
      Assert.IsTrue(Words(LPatch, 0) <= 16, LName);
    end;
  end;
  Assert.AreEqual(5 * 95, LSmall);
  Assert.AreEqual(5 * 95, LBig);
  Assert.AreEqual(10, LMarkers, 'a pair of markers for each color of each font');
  IndexOfLump('SFNTA033');
  IndexOfLump('SFNTE127');
  IndexOfLump('BFNTA033');
end;

procedure TTestSpeedTranslator.DovrebbeFareLeParoleDelSoundInfoEIDieciMotori;
var
  LText: string;
begin
  Translate(TJclBuilder.SyntheticGame);
  LText := TEncoding.ASCII.GetString(FWad.LumpData[IndexOfLump('SNDINFO')]);
  Assert.IsTrue(LText.StartsWith('// Speed Haste sounds'#13#10#13#10));
  Assert.IsTrue(LText.Contains('speedhaste/CRASH.RAW DS_00000'#13#10));
  Assert.IsTrue(LText.Contains('speedhaste/GO.RAW DS_00001'#13#10));
  Assert.IsTrue(LText.Contains('speedhaste/MOTOR0_9 MOTOR0_9'#13#10));
  Assert.AreEqual(13000, Integer(PInteger(@FWad.LumpData[IndexOfLump('DS_00000')][24])^));
  Assert.AreEqual(11025 + 300, Integer(PInteger(@FWad.LumpData[IndexOfLump('MOTOR0_3')][24])^));
end;

procedure TTestSpeedTranslator.DovrebbeDareIModelliCheIlMotoreDeveAggiungereAlPak;
var
  LPak: TArray<TSpeedPakEntry>;
  LContainer: ISpeedContainer;
  LData: TBytes;
begin
  LContainer := TSpeedFactory.OpenContainerBytes(TJclBuilder.SyntheticGame);
  LPak := FTranslator.Translate(LContainer, FWad);
  Assert.AreEqual<Integer>(2, Length(LPak));
  // the position and the size are those of the container: the engine reads the bytes from there
  Assert.AreEqual(LContainer.Entries[LContainer.IndexOf('XPR061.I3D')].Position, LPak[1].Position);
  Assert.IsTrue(LContainer.TryRead('XPR061.I3D', LData));
  Assert.AreEqual<Integer>(Length(LData), LPak[1].Size);
end;

procedure TTestSpeedTranslator.DovrebbeScrivereLaListaDeiFileInSpeedinf;
var
  LText: string;
begin
  Translate(TJclBuilder.SyntheticGame);
  LText := TEncoding.ASCII.GetString(FWad.LumpData[IndexOfLump(SPEED_INFO_LUMP)]);
  Assert.IsTrue(LText.StartsWith('WALL1=1.IS2'#13#10));
  Assert.IsTrue(LText.Contains('DEMOLOGO=DEMOLOGO.IS2'#13#10));
  Assert.IsTrue(LText.Contains('S020A0=XPR020.IS2'#13#10));
  Assert.IsTrue(LText.Contains('S021A0=XPR021.IS2'#13#10), 'a sprite that the container does not have is listed too');
  Assert.IsTrue(LText.Contains('LOGO=LOGO.PIX'#13#10));
end;

procedure TTestSpeedTranslator.DovrebbeAvvisareDiUnaImmagineCheNonELo;
var
  LBuilder: TJclBuilder;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('BAD.IS2', TJclBuilder.TextBytes('this is not a picture at all'));
    Translate(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.IsTrue(FLog.Warnings[0].Contains('BAD.IS2'));
  Assert.AreEqual(-1, FWad.IndexOf('BAD'));
end;

procedure TTestSpeedTranslator.DovrebbeAvvisareDiUnaImmagineTroppoAlta;
var
  LBuilder: TJclBuilder;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('TALL.IS2', TJclBuilder.Is2(1, 4, 300, False));
    Translate(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual(-1, FWad.IndexOf('TALL'));
end;

procedure TTestSpeedTranslator.DovrebbeLasciareLaMusicaSeManca;
var
  LBuilder: TJclBuilder;
begin
  LBuilder := TJclBuilder.Create;
  try
    // the music of the menu is what makes the rest of the music: without it there is none
    LBuilder.Add('HASTE1.S3M', TBytes.Create(1, 2, 3));
    Translate(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(-1, FWad.IndexOf('D_INTRO'));
  Assert.AreEqual(-1, FWad.IndexOf('D_E1M1'));
end;

procedure TTestSpeedTranslator.DovrebbeFunzionareConUnContenitoreVuoto;
var
  LBuilder: TJclBuilder;
  LPak: TArray<TSpeedPakEntry>;
begin
  LBuilder := TJclBuilder.Create;
  try
    LPak := Translate(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual<Integer>(0, Length(LPak));
  Assert.AreEqual(-1, FWad.IndexOf('PLAYPAL'));
  // what is always there: the stub texture, the empty second table and the markers
  IndexOfLump('AA0000');
  IndexOfLump('TEXTURE2');
  IndexOfLump('G_START');
  IndexOfLump('S_START');
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestSpeedTranslator.DovrebbeAvvisareDiUnaPalettaCorta;
var
  LBuilder: TJclBuilder;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('GRAFS.PAL', TBytes.Create(1, 2, 3));
    Translate(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual(-1, FWad.IndexOf('PLAYPAL'));
end;

procedure TTestSpeedTranslator.DovrebbeRifiutareUnaDipendenzaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedTranslator.Create(nil, TPaletteFactory.CreateColorMatcher, nil, nil, nil, nil, nil, nil, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TSpeedTranslator.Create(FLog, nil, nil, nil, nil, nil, nil, nil, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TSpeedTranslator.Create(FLog, TPaletteFactory.CreateColorMatcher, nil, nil, nil, nil, nil, nil, nil);
    end, EArgumentNilException);
end;

procedure TTestSpeedTranslator.DovrebbeRifiutareUnContenitoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FTranslator.Translate(nil, FWad);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      FTranslator.Translate(TSpeedFactory.OpenContainerBytes(TJclBuilder.SyntheticGame), nil);
    end, EArgumentNilException);
end;

end.
