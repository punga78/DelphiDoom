{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of S_LoadSound of the Quake III sound                     }
{                                                                              }
{  Reads WAV files built in memory with the reader of Libs\Sound and, where    }
{  they are, the sounds of OpenArena.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Loader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf, DelphiDoom.Audio.Q3.Loader;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Loader = class
  strict private
    FReader: ISndfile;
    FLoader: TQ3SoundLoader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnMonoASediciBitAlRateDelDispositivo;
    [Test]
    procedure DovrebbeRaddoppiareUnSuonoAMezzoRate;
    [Test]
    procedure DovrebbeCaricareUnMonoAOttoBit;
    [Test]
    procedure DovrebbeRifiutareUnFileStereo;
    [Test]
    procedure DovrebbeRifiutareByteCheNonSonoUnSuono;
    [Test]
    procedure DovrebbeRifiutareUnFileVuoto;
    [Test]
    procedure DovrebbeCaricareUnSuonoSenzaCampioni;
    [Test]
    procedure DovrebbeRifiutareUnRateDelDispositivoNonValido;
    [Test]
    procedure DovrebbeLeggereISuoniDiOpenArenaDoveSono;
    [Test]
    procedure DovrebbeFarSuonareUnSuonoDiOpenArenaFinoInFondo;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Zip, DelphiDoom.Sound.Factory,
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Tests.Audio.Q3.Fakes, DelphiDoom.Tests.Audio.Q3.Rig;

{ TTestQ3Loader }

procedure TTestQ3Loader.Setup;
begin
  FReader := TSoundFactory.CreateEngine;
  FLoader := TQ3SoundLoader.Create(FReader);
end;

procedure TTestQ3Loader.TearDown;
begin
  FLoader.Free;
  FReader := nil;
end;

procedure TTestQ3Loader.DovrebbeCaricareUnMonoASediciBitAlRateDelDispositivo;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsTrue(FLoader.Load(TQ3TestWav.Mono16(22050, [100, -200, 300]), 22050, LSamples));
  Assert.AreEqual<Integer>(3, Length(LSamples));
  Assert.AreEqual(100, Integer(LSamples[0]));
  Assert.AreEqual(-200, Integer(LSamples[1]));
  Assert.AreEqual(300, Integer(LSamples[2]));
end;

procedure TTestQ3Loader.DovrebbeRaddoppiareUnSuonoAMezzoRate;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsTrue(FLoader.Load(TQ3TestWav.Mono16(11025, [100, 200, 300]), 22050, LSamples));
  Assert.AreEqual<Integer>(6, Length(LSamples));
  Assert.AreEqual(100, Integer(LSamples[0]));
  Assert.AreEqual(100, Integer(LSamples[1]));
  Assert.AreEqual(200, Integer(LSamples[2]));
  Assert.AreEqual(300, Integer(LSamples[5]));
end;

procedure TTestQ3Loader.DovrebbeCaricareUnMonoAOttoBit;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsTrue(FLoader.Load(TQ3TestWav.Build(1, 22050, 8, TBytes.Create(128, 192, 64)), 22050,
    LSamples));
  Assert.AreEqual<Integer>(3, Length(LSamples));
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(16384, Integer(LSamples[1]));
  Assert.AreEqual(-16384, Integer(LSamples[2]));
end;

procedure TTestQ3Loader.DovrebbeRifiutareUnFileStereo;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsFalse(FLoader.Load(TQ3TestWav.Build(2, 22050, 16, TBytes.Create(1, 0, 2, 0, 3, 0, 4, 0)),
    22050, LSamples));
  Assert.AreEqual<Integer>(0, Length(LSamples));
end;

procedure TTestQ3Loader.DovrebbeRifiutareByteCheNonSonoUnSuono;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsFalse(FLoader.Load(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), 22050, LSamples));
end;

procedure TTestQ3Loader.DovrebbeRifiutareUnFileVuoto;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsFalse(FLoader.Load(nil, 22050, LSamples));
end;

procedure TTestQ3Loader.DovrebbeCaricareUnSuonoSenzaCampioni;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.IsTrue(FLoader.Load(TQ3TestWav.Mono16(22050, []), 22050, LSamples));
  Assert.AreEqual<Integer>(0, Length(LSamples));
end;

procedure TTestQ3Loader.DovrebbeRifiutareUnRateDelDispositivoNonValido;
var
  LSamples: TArray<SmallInt>;
begin
  Assert.WillRaise(
    procedure
    begin
      FLoader.Load(TQ3TestWav.Mono16(22050, [1, 2]), 0, LSamples);
    end);
end;

procedure TTestQ3Loader.DovrebbeLeggereISuoniDiOpenArenaDoveSono;
var
  LFolder, LFile: string;
  LZip: TZipFile;
  LIndex, LMono, LRefused, LChecked: Integer;
  LBytes: TBytes;
  LSamples: TArray<SmallInt>;
begin
  LFolder := TQ3TestData.OpenArenaFolder;
  if LFolder = '' then
  begin
    Assert.Pass('OpenArena not found (DELPHIDOOM_OPENARENA): skipped');
    Exit;
  end;
  LMono := 0;
  LRefused := 0;
  LChecked := 0;
  for LFile in TDirectory.GetFiles(LFolder, 'pak*.pk3') do
  begin
    LZip := TZipFile.Create;
    try
      LZip.Open(LFile, zmRead);
      for LIndex := 0 to LZip.FileCount - 1 do
      begin
        if (not LZip.FileNames[LIndex].StartsWith('sound/')) or
          (not LZip.FileNames[LIndex].EndsWith('.wav')) then
          Continue;
        if LChecked >= 2000 then
          Break;
        LZip.Read(LIndex, LBytes);
        Inc(LChecked);
        if FLoader.Load(LBytes, 22050, LSamples) then
        begin
          Inc(LMono);
          Assert.IsTrue(Length(LSamples) > 0, LZip.FileNames[LIndex]);
        end
        else
          Inc(LRefused);
      end;
    finally
      LZip.Free;
    end;
  end;
  if LChecked = 0 then
    Assert.Pass('no sound in the pk3 of OpenArena: skipped')
  else
    Assert.IsTrue(LMono > 0, Format('%d files read, %d mono, %d refused', [LChecked, LMono,
      LRefused]));
end;

procedure TTestQ3Loader.DovrebbeFarSuonareUnSuonoDiOpenArenaFinoInFondo;
var
  LFolder: string;
  LZip: TZipFile;
  LRig: TQ3TestRig;
  LBytes: TBytes;
  LIndex, LHandle, LSound, LLoud: Integer;
begin
  LFolder := TQ3TestData.OpenArenaFolder;
  if (LFolder = '') or (not TFile.Exists(TPath.Combine(LFolder, 'pak6-misc.pk3'))) then
  begin
    Assert.Pass('OpenArena not found: skipped');
    Exit;
  end;
  LRig := TQ3TestRig.Create(2, 32768, 16, 22050, 1024, True);
  LZip := TZipFile.Create;
  try
    LZip.Open(TPath.Combine(LFolder, 'pak6-misc.pk3'), zmRead);
    LSound := -1;
    for LIndex := 0 to LZip.FileCount - 1 do
      if LZip.FileNames[LIndex].StartsWith('sound/') and LZip.FileNames[LIndex].EndsWith('.wav') then
      begin
        LSound := LIndex;
        Break;
      end;
    if LSound < 0 then
    begin
      Assert.Pass('no sound in pak6-misc.pk3: skipped');
      Exit;
    end;
    LZip.Read(LSound, LBytes);
    LRig.Files.Files.Add(LZip.FileNames[LSound], LBytes);
    // the first handle is 0: register a dummy first so that the sound has a handle that is not 0
    LRig.AddConstant('dummy', 0, 10);
    LHandle := LRig.Sound.RegisterSound(LZip.FileNames[LSound]);
    Assert.AreEqual(1, LHandle);
    LRig.Sound.State.Volume := 1.0;
    LRig.Clock.Milliseconds := 1000;
    LRig.Sound.StartSound(nil, 4, Q3_CHAN_AUTO, LHandle);
    LRig.Sound.Update;
    LLoud := 0;
    for LIndex := 0 to 8191 do
      if LRig.DeviceSample(LIndex) <> 0 then
        Inc(LLoud);
    Assert.IsTrue(LLoud > 0, 'the sound of ' + LZip.FileNames[LSound] + ' is silent');
  finally
    LZip.Free;
    LRig.Free;
  end;
end;

end.
