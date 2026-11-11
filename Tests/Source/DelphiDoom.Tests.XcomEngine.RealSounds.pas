{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sounds of the xcom game against the real SoundSet   }
{  of OpenXcom (Tools\Verifica\176\battle\soundgen.cpp): the samples of every   }
{  entry of the CAT files of UFO and of TFTD (skipped when the game data is     }
{  not there) and of a CAT file made for the test                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.RealSounds;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.CatArchive, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.ModGameLoader,
  DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.SoundConverter, DelphiDoom.XcomEngine.SoundSet,
  DelphiDoom.XcomEngine.SoundFormats.Intf, DelphiDoom.Png.Provider;

type
  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealSounds = class
  strict private
    FGoldenFolder: string;
    FReference: string;
    FUfoFolder: string;
    FTftdFolder: string;
    function Samples(const AWave: TBytes): TBytes;
    function Fingerprint(const ASamples: TBytes): string;
    function Convert(const ARaw: TBytes; AFormat: TXcomSoundSetFormat): TBytes;
    /// <summary>Compares every entry of a CAT file with the lines of the real SoundSet; the number of sounds</summary>
    function CheckCat(const ACatFile, AGolden: string; AFormat: TXcomSoundSetFormat): Integer;
    function LoadUfo(out AResources: IXcomResources): Boolean;
    procedure AssertSame(const AExpected, AActual: TBytes);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure IlCatDiProvaDaGliStessiCampioniDelVeroSoundSetNeiTreModi;
    [Test]
    procedure ISuoniDosDiUfoSonoQuelliDelVeroLoadCat;
    [Test]
    procedure ISuoniDiTftdSonoQuelliDelVeroLoadCatByIndex;
    [Test]
    procedure LeRisorseDiUfoSenzaSoundDefsUsanoIFileDos;
    [Test]
    procedure IlFormatoPreferitoCheMancaRicadeSuQuelloCheCe;
    [Test]
    procedure UnWavChenonEAOttomilaHertzRestaComeE;
  end;

implementation

procedure TTestXcomRealSounds.Setup;
var
  LFolder: string;
begin
  FGoldenFolder := '';
  FReference := '';
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    if (FGoldenFolder = '') and TDirectory.Exists(TPath.Combine(LFolder, 'Tests\Data\XcomEngine\sounds')) then
      FGoldenFolder := TPath.Combine(LFolder, 'Tests\Data\XcomEngine\sounds');
    if (FReference = '') and TDirectory.Exists(TPath.Combine(LFolder, 'Reference\_dati')) then
      FReference := TPath.Combine(LFolder, 'Reference');
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  FUfoFolder := '';
  FTftdFolder := '';
  if FReference <> '' then
  begin
    FUfoFolder := TPath.Combine(FReference, '_dati\xcom_ufo\UFO Enemy Unkown\DOS game');
    if not TFile.Exists(TPath.Combine(FUfoFolder, 'SOUND\SOUND1.CAT')) then
      FUfoFolder := '';
    FTftdFolder := TPath.Combine(FReference, '_dati\xcom_tftd\TFTD');
    if not TFile.Exists(TPath.Combine(FTftdFolder, 'SOUND\SAMPLE.CAT')) then
      FTftdFolder := '';
  end;
end;

function TTestXcomRealSounds.Samples(const AWave: TBytes): TBytes;
var
  LPosition: Integer;
  LSize: Integer;
begin
  // the data chunk of a RIFF WAVE file, as SDL finds it: chunk after chunk from byte 12
  Result := nil;
  if (Length(AWave) < 12) or (PCardinal(@AWave[0])^ <> $46464952) or (PCardinal(@AWave[8])^ <> $45564157) then
    Exit;
  LPosition := 12;
  while LPosition + 8 <= Length(AWave) do
  begin
    LSize := Integer(PCardinal(@AWave[LPosition + 4])^);
    if PCardinal(@AWave[LPosition])^ = $61746164 then
    begin
      if LSize > Length(AWave) - LPosition - 8 then
        LSize := Length(AWave) - LPosition - 8;
      Result := Copy(AWave, LPosition + 8, LSize);
      Exit;
    end;
    Inc(LPosition, 8 + LSize);
  end;
end;

function TTestXcomRealSounds.Fingerprint(const ASamples: TBytes): string;
var
  LHash: UInt64;
  LIndex: Integer;
begin
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to High(ASamples) do
    LHash := (LHash xor UInt64(ASamples[LIndex])) * UInt64($100000001B3);
  Result := IntToHex(Int64(LHash), 16);
end;

function TTestXcomRealSounds.Convert(const ARaw: TBytes; AFormat: TXcomSoundSetFormat): TBytes;
begin
  case AFormat of
    sfDos: Result := TXcomSoundConverter.RawToWave(ARaw);
    sfWave: Result := TXcomSoundConverter.WaveToWave(ARaw);
  else
    Result := TXcomSoundConverter.IndexedToWave(ARaw);
  end;
end;

function TTestXcomRealSounds.CheckCat(const ACatFile, AGolden: string; AFormat: TXcomSoundSetFormat): Integer;
var
  LCatalog: IXcomCatArchive;
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LIndex: Integer;
  LData: TBytes;
  LEntries: Integer;
begin
  Result := 0;
  LEntries := 0;
  LCatalog := TXcomCatArchive.Create(TFile.ReadAllBytes(ACatFile));
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.Combine(FGoldenFolder, AGolden));
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      if (Length(LParts) < 2) or (LParts[0] = 'spec') or (LParts[0] = 'sounds') then
        Continue;
      LIndex := StrToInt(LParts[0]);
      Inc(LEntries);
      LData := Samples(Convert(LCatalog.Load(LIndex), AFormat));
      if LParts[1] = 'none' then
        Assert.AreEqual(0, Length(LData), Format('%s entry %d: the real game has no sound', [AGolden, LIndex]))
      else
      begin
        Assert.AreEqual(StrToInt(LParts[1]), Length(LData), Format('%s entry %d: samples', [AGolden, LIndex]));
        Assert.AreEqual(LParts[2], Fingerprint(LData), Format('%s entry %d: fingerprint', [AGolden, LIndex]));
        Inc(Result);
      end;
    end;
  finally
    LLines.Free;
  end;
  Assert.AreEqual(LCatalog.Count, LEntries, AGolden + ': entries of the file');
end;

procedure TTestXcomRealSounds.IlCatDiProvaDaGliStessiCampioniDelVeroSoundSetNeiTreModi;
var
  LCat: string;
begin
  Assert.IsTrue(FGoldenFolder <> '', 'Tests\Data\XcomEngine\sounds not found');
  LCat := TPath.Combine(FGoldenFolder, 'synthetic_wav.cat');
  // two 8 kHz files (one with a name, one odd), an 11025 Hz one, junk and an empty entry
  Assert.AreEqual(3, CheckCat(LCat, 'synthetic_wav.txt', sfWave));
  Assert.AreEqual(4, CheckCat(LCat, 'synthetic_dos.txt', sfDos));
  Assert.AreEqual(4, CheckCat(LCat, 'synthetic_index.txt', sfIndexed));
end;

procedure TTestXcomRealSounds.ISuoniDosDiUfoSonoQuelliDelVeroLoadCat;
begin
  if (FUfoFolder = '') or (FGoldenFolder = '') then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  Assert.AreEqual(54, CheckCat(TPath.Combine(FUfoFolder, 'SOUND\SOUND1.CAT'), 'ufo_sound1.txt', sfDos));
  Assert.AreEqual(13, CheckCat(TPath.Combine(FUfoFolder, 'SOUND\SOUND2.CAT'), 'ufo_sound2.txt', sfDos));
  Assert.AreEqual(25, CheckCat(TPath.Combine(FUfoFolder, 'SOUND\INTRO.CAT'), 'ufo_intro.txt', sfDos));
end;

procedure TTestXcomRealSounds.ISuoniDiTftdSonoQuelliDelVeroLoadCatByIndex;
begin
  if (FTftdFolder = '') or (FGoldenFolder = '') then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  Assert.IsTrue(CheckCat(TPath.Combine(FTftdFolder, 'SOUND\SAMPLE.CAT'), 'tftd_sample.txt', sfIndexed) > 100);
end;

function TTestXcomRealSounds.LoadUfo(out AResources: IXcomResources): Boolean;
var
  LSettings: TXcomLoaderSettings;
  LLoader: IXcomGameLoader;
  LLanguage: TXcomLanguage;
begin
  Result := False;
  if (FUfoFolder = '') or not TDirectory.Exists(TPath.Combine(FReference, 'OpenXcom\bin\common')) then
    Exit;
  LSettings.DataFolder := TPath.Combine(FReference, 'OpenXcom\bin');
  LSettings.GameFolder := FUfoFolder;
  LSettings.ModId := 'xcom1';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLanguage := nil;
  LLoader.Load(AResources, LLanguage);
  LLanguage.Free;
  Result := True;
end;

procedure TTestXcomRealSounds.AssertSame(const AExpected, AActual: TBytes);
begin
  Assert.AreEqual(Length(AExpected), Length(AActual), 'size');
  if Length(AExpected) > 0 then
    Assert.IsTrue(CompareMem(@AExpected[0], @AActual[0], Length(AExpected)), 'bytes');
end;

procedure TTestXcomRealSounds.LeRisorseDiUfoSenzaSoundDefsUsanoIFileDos;
var
  LResources: IXcomResources;
  LFormats: IXcomSoundFormats;
  LGeo: IXcomCatArchive;
  LBattle: IXcomCatArchive;
  LIntro: IXcomCatArchive;
  LIndex: Integer;
  LCount: Integer;
begin
  if not LoadUfo(LResources) then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  Assert.IsFalse(LResources.HasSoundDefinitions);
  Assert.IsTrue(Supports(LResources, IXcomSoundFormats, LFormats));
  Assert.AreEqual(XCOM_SOUND_10, LFormats.CurrentSound);
  // GEO.CAT is SOUND2.CAT and BATTLE.CAT is SOUND1.CAT, entry by entry
  LGeo := TXcomCatArchive.Create(TFile.ReadAllBytes(TPath.Combine(FUfoFolder, 'SOUND\SOUND2.CAT')));
  LBattle := TXcomCatArchive.Create(TFile.ReadAllBytes(TPath.Combine(FUfoFolder, 'SOUND\SOUND1.CAT')));
  LIntro := TXcomCatArchive.Create(TFile.ReadAllBytes(TPath.Combine(FUfoFolder, 'SOUND\INTRO.CAT')));
  LCount := 0;
  for LIndex := 0 to LGeo.Count - 1 do
  begin
    AssertSame(TXcomSoundConverter.RawToWave(LGeo.Load(LIndex)), LResources.SoundWave('GEO.CAT', LIndex));
    if Length(LResources.SoundWave('GEO.CAT', LIndex)) > 0 then
      Inc(LCount);
  end;
  for LIndex := 0 to LBattle.Count - 1 do
  begin
    AssertSame(TXcomSoundConverter.RawToWave(LBattle.Load(LIndex)), LResources.SoundWave('BATTLE.CAT', LIndex));
    if Length(LResources.SoundWave('BATTLE.CAT', LIndex)) > 0 then
      Inc(LCount);
  end;
  for LIndex := 0 to LIntro.Count - 1 do
    AssertSame(TXcomSoundConverter.RawToWave(LIntro.Load(LIndex)), LResources.SoundWave('INTRO.CAT', LIndex));
  Assert.AreEqual(67, LCount, 'sounds of GEO.CAT and BATTLE.CAT');
  // past the end of the file, and the sets that UFO does not have
  Assert.AreEqual(0, Length(LResources.SoundWave('GEO.CAT', LGeo.Count)));
  Assert.AreEqual(0, Length(LResources.SoundWave('BATTLE2.CAT', 0)));
  Assert.AreEqual(0, Length(LResources.SoundWave('SAMPLE3.CAT', 0)));
end;

procedure TTestXcomRealSounds.IlFormatoPreferitoCheMancaRicadeSuQuelloCheCe;
var
  LResources: IXcomResources;
  LFormats: IXcomSoundFormats;
  LBefore: TBytes;
begin
  if not LoadUfo(LResources) then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  Assert.IsTrue(Supports(LResources, IXcomSoundFormats, LFormats));
  LBefore := LResources.SoundWave('GEO.CAT', 0);
  Assert.IsTrue(Length(LBefore) > 44);
  // the DOS installation has no SAMPLE.CAT: the Windows format is asked for and the DOS one is found
  LFormats.SetPreferredSound(XCOM_SOUND_14);
  Assert.AreEqual(XCOM_SOUND_10, LFormats.CurrentSound);
  AssertSame(LBefore, LResources.SoundWave('GEO.CAT', 0));
  LFormats.SetPreferredSound(XCOM_SOUND_10);
  Assert.AreEqual(XCOM_SOUND_10, LFormats.CurrentSound);
  AssertSame(LBefore, LResources.SoundWave('GEO.CAT', 0));
end;

procedure TTestXcomRealSounds.UnWavChenonEAOttomilaHertzRestaComeE;
var
  LWave: TBytes;
  LIndex: Integer;
begin
  SetLength(LWave, 60);
  for LIndex := 0 to High(LWave) do
    LWave[LIndex] := Byte(LIndex);
  PCardinal(@LWave[$18])^ := 11025;
  AssertSame(LWave, TXcomSoundConverter.WaveToWave(LWave));
  // 8000 Hz: 16 samples become 23 and the header says 11025
  PCardinal(@LWave[$18])^ := 8000;
  LWave := TXcomSoundConverter.WaveToWave(LWave);
  Assert.AreEqual(44 + 23, Length(LWave));
  Assert.AreEqual(Cardinal($2B11), PCardinal(@LWave[$18])^);
  Assert.AreEqual(Cardinal(23), PCardinal(@LWave[$28])^);
  Assert.AreEqual(Byte(44), LWave[44]);
  Assert.AreEqual(Byte(44), LWave[45]);
  Assert.AreEqual(Byte(45), LWave[46]);
  // too short to have a header
  Assert.AreEqual(0, Length(TXcomSoundConverter.WaveToWave(nil)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealSounds);

end.
