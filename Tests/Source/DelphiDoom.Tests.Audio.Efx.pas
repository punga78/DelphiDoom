{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - the EFX reverb presets             }
{                                                                              }
{  The unit tests of TEfxEffectsFile and the parity with the real              }
{  snd_efxfile.cpp of Doom 3: Tests\Data\Audio\efx.input.txt is run with the   }
{  class and the output is compared with efx.golden.txt (see                   }
{  Tests\Data\Audio\README.md).                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Efx;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Audio.Efx.Types,
  DelphiDoom.Audio.Efx.EffectsFile, DelphiDoom.Tests.Scanner.IdFakes;

type
  [TestFixture]
  [Category('Audio')]
  TTestEfxEffectsFile = class
  strict private
    FFiles: TFakeIdLibFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FLog: IIdLibLog;
    FLines: TStringList;
    FEfx: TEfxEffectsFile;
    function Load(const AText: AnsiString): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereTuttiIParametriDiUnReverb;
    [Test]
    procedure DovrebbeTenereL0DiCioCheIlFileNonDice;
    [Test]
    procedure DovrebbeUsareUnaStrutturaDi112Byte;
    [Test]
    procedure DovrebbeLeggereDueEffettiEdElencarliNellOrdine;
    [Test]
    procedure DovrebbeTrovareIlPrimoEffettoConQuelNomeSoloSeUgualeInMaiuscole;
    [Test]
    procedure DovrebbeDareFalsoESegnareIndiceMenoUnoSeNonTrovaIlNome;
    [Test]
    procedure DovrebbeAccettareUnEffettoSenzaNome;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeDareVeroPerUnFileConLaSolaVersione;
    [Test]
    procedure DovrebbeAggiungereGliEffettiDiUnSecondoFile;
    [Test]
    procedure DovrebbeSvuotareLaListaConUnloadFile;
    [Test]
    procedure DovrebbeSolleverePerUnaVersioneSconosciuta;
    [Test]
    procedure DovrebbeSollevarePerUnFileSenzaVersione;
    [Test]
    procedure DovrebbeSolleverePerUnEffettoCheNonESReverb;
    [Test]
    procedure DovrebbeSollevarePerUnaGraffaMancante;
    [Test]
    procedure DovrebbeSollevarePerUnBloccoSenzaGraffaChiusa;
    [Test]
    procedure DovrebbeSollevarePerUnParametroSconosciuto;
    [Test]
    procedure DovrebbeTenereGliEffettiLettiPrimaDiUnErrore;
    [Test]
    procedure DovrebbeLeggereUnaVirgolaMobileNegativaEUnInteroSenzaSegno;
    [Test]
    procedure DovrebbeLeggereIlFlagInEsadecimale;
    [Test]
    procedure DovrebbeUsareLUltimoValoreDiUnParametroRipetuto;
    [Test]
    procedure DovrebbeNonLeggereUnValoreSuUnaRigaDiversa;
    [Test]
    procedure DovrebbeAccettareLeParoleSenzaVirgolette;
    [Test]
    procedure DovrebbeFermarsiSeUnLexerCheNonSollevaTrovaUnErrore;
    [Test]
    procedure DovrebbeDareIlNumeroDiEffetti;
  end;

  [TestFixture]
  [Category('Audio')]
  TTestEfxGolden = class
  strict private
    FLines: TStringList;
    FFiles: TFakeIdLibFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FEfx: TEfxEffectsFile;
    FLog: IIdLibLog;
    function DataFolder: string;
    procedure Emit(const ALine: string);
    class function Bits(const AValue: Single): string; static;
    procedure DumpEffects;
    procedure Execute(const AOperation: string);
    function Run(const AInput: TStrings): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdEfxFile;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Types;

{ TTestEfxEffectsFile }

procedure TTestEfxEffectsFile.Setup;
begin
  FLines := TStringList.Create;
  FLog := TFakeIdLibLog.Create(FLines);
  FFiles := TFakeIdLibFileSystem.Create;
  FFilesIntf := FFiles;
  FEfx := TEfxEffectsFile.Create(FFilesIntf, FLog);
end;

procedure TTestEfxEffectsFile.TearDown;
begin
  FreeAndNil(FEfx);
  FFilesIntf := nil;
  FLog := nil;
  FreeAndNil(FLines);
end;

function TTestEfxEffectsFile.Load(const AText: AnsiString): Boolean;
begin
  FFiles.Add('efx/test.efx', AText);
  Result := FEfx.LoadFile('efx/test.efx');
end;

procedure TTestEfxEffectsFile.DovrebbeLeggereTuttiIParametriDiUnReverb;
var
  LReverb: TEfxReverbProperties;
begin
  Assert.IsTrue(Load('Version 1'#10'reverb "room"'#10'{'#10 +
    '"environment" 26 "environment size" 7.5 "environment diffusion" 0.875'#10 +
    '"room" -1000 "room hf" -454 "room lf" -12'#10 +
    '"decay time" 1.49 "decay hf ratio" 0.5 "decay lf ratio" 1.25'#10 +
    '"reflections" -2273 "reflections delay" 0.25 "reflections pan" 0.25 -0.5 1'#10 +
    '"reverb" 1700 "reverb delay" 0.5 "reverb pan" 0 0.125 -2'#10 +
    '"echo time" 0.25 "echo depth" 0.5 "modulation time" 0.75 "modulation depth" 1.5'#10 +
    '"air absorption hf" -5 "hf reference" 5000 "lf reference" 250 "room rolloff factor" 3.5'#10 +
    '"flags" 63'#10'}'#10));
  Assert.AreEqual(1, FEfx.Count);
  Assert.AreEqual<string>('room', string(FEfx[0].Name));
  LReverb := FEfx[0].Reverb;
  Assert.AreEqual<Cardinal>(26, LReverb.Environment);
  Assert.AreEqual<Single>(7.5, LReverb.EnvironmentSize);
  Assert.AreEqual<Single>(0.875, LReverb.EnvironmentDiffusion);
  Assert.AreEqual(-1000, LReverb.Room);
  Assert.AreEqual(-454, LReverb.RoomHF);
  Assert.AreEqual(-12, LReverb.RoomLF);
  Assert.AreEqual<Single>(1.49, LReverb.DecayTime);
  Assert.AreEqual<Single>(0.5, LReverb.DecayHFRatio);
  Assert.AreEqual<Single>(1.25, LReverb.DecayLFRatio);
  Assert.AreEqual(-2273, LReverb.Reflections);
  Assert.AreEqual<Single>(0.25, LReverb.ReflectionsDelay);
  Assert.AreEqual<Single>(0.25, LReverb.ReflectionsPan.X);
  Assert.AreEqual<Single>(-0.5, LReverb.ReflectionsPan.Y);
  Assert.AreEqual<Single>(1, LReverb.ReflectionsPan.Z);
  Assert.AreEqual(1700, LReverb.Reverb);
  Assert.AreEqual<Single>(0.5, LReverb.ReverbDelay);
  Assert.AreEqual<Single>(0, LReverb.ReverbPan.X);
  Assert.AreEqual<Single>(0.125, LReverb.ReverbPan.Y);
  Assert.AreEqual<Single>(-2, LReverb.ReverbPan.Z);
  Assert.AreEqual<Single>(0.25, LReverb.EchoTime);
  Assert.AreEqual<Single>(0.5, LReverb.EchoDepth);
  Assert.AreEqual<Single>(0.75, LReverb.ModulationTime);
  Assert.AreEqual<Single>(1.5, LReverb.ModulationDepth);
  Assert.AreEqual<Single>(-5, LReverb.AirAbsorptionHF);
  Assert.AreEqual<Single>(5000, LReverb.HFReference);
  Assert.AreEqual<Single>(250, LReverb.LFReference);
  Assert.AreEqual<Single>(3.5, LReverb.RoomRolloffFactor);
  Assert.AreEqual<Cardinal>(63, LReverb.Flags);
end;

procedure TTestEfxEffectsFile.DovrebbeTenereL0DiCioCheIlFileNonDice;
var
  LReverb: TEfxReverbProperties;
begin
  Assert.IsTrue(Load('Version 1 reverb "sparse" { "room" 5 }'));
  LReverb := FEfx[0].Reverb;
  Assert.AreEqual(5, LReverb.Room);
  Assert.AreEqual<Cardinal>(0, LReverb.Environment);
  Assert.AreEqual<Single>(0, LReverb.DecayTime);
  Assert.AreEqual<Single>(0, LReverb.ReverbPan.Z);
  Assert.AreEqual<Cardinal>(0, LReverb.Flags);
end;

procedure TTestEfxEffectsFile.DovrebbeUsareUnaStrutturaDi112Byte;
begin
  // sizeof(EAXREVERBPROPERTIES) of eax4.h: the datasize of an idSoundEffect
  Assert.AreEqual(112, SizeOf(TEfxReverbProperties));
  Assert.AreEqual(12, SizeOf(TEfxVector));
end;

procedure TTestEfxEffectsFile.DovrebbeLeggereDueEffettiEdElencarliNellOrdine;
begin
  Assert.IsTrue(Load('Version 1 reverb "one" { "room" 1 } reverb "two" { "room" 2 }'));
  Assert.AreEqual(2, FEfx.Count);
  Assert.AreEqual<string>('one', string(FEfx[0].Name));
  Assert.AreEqual<string>('two', string(FEfx[1].Name));
  Assert.AreEqual(2, FEfx[1].Reverb.Room);
end;

procedure TTestEfxEffectsFile.DovrebbeTrovareIlPrimoEffettoConQuelNomeSoloSeUgualeInMaiuscole;
var
  LEffect: TEfxEffect;
  LIndex: Integer;
begin
  Load('Version 1 reverb "dup" { "room" 1 } reverb "other" { } reverb "dup" { "room" 3 }');
  Assert.IsTrue(FEfx.FindEffect('dup', LEffect, LIndex));
  Assert.AreEqual(0, LIndex);
  Assert.AreEqual(1, LEffect.Reverb.Room);
  Assert.IsFalse(FEfx.FindEffect('DUP', LEffect, LIndex));
end;

procedure TTestEfxEffectsFile.DovrebbeDareFalsoESegnareIndiceMenoUnoSeNonTrovaIlNome;
var
  LEffect: TEfxEffect;
  LIndex: Integer;
begin
  Load('Version 1 reverb "a" { }');
  Assert.IsFalse(FEfx.FindEffect('b', LEffect, LIndex));
  Assert.AreEqual(-1, LIndex);
  Assert.AreEqual<string>('', string(LEffect.Name));
end;

procedure TTestEfxEffectsFile.DovrebbeAccettareUnEffettoSenzaNome;
var
  LEffect: TEfxEffect;
  LIndex: Integer;
begin
  Assert.IsTrue(Load('Version 1'#10'reverb'#10'{'#10'"flags" 3'#10'}'));
  Assert.AreEqual<string>('', string(FEfx[0].Name));
  Assert.AreEqual<Cardinal>(3, FEfx[0].Reverb.Flags);
  Assert.IsTrue(FEfx.FindEffect('', LEffect, LIndex));
end;

procedure TTestEfxEffectsFile.DovrebbeDareFalsoSeIlFileNonEsiste;
begin
  Assert.IsFalse(FEfx.LoadFile('efx/missing.efx'));
  Assert.AreEqual(0, FEfx.Count);
end;

procedure TTestEfxEffectsFile.DovrebbeDareVeroPerUnFileConLaSolaVersione;
begin
  Assert.IsTrue(Load('Version 1'#10#10));
  Assert.AreEqual(0, FEfx.Count);
end;

procedure TTestEfxEffectsFile.DovrebbeAggiungereGliEffettiDiUnSecondoFile;
begin
  FFiles.Add('efx/a.efx', 'Version 1 reverb "a" { }');
  FFiles.Add('efx/b.efx', 'Version 1 reverb "b" { }');
  Assert.IsTrue(FEfx.LoadFile('efx/a.efx'));
  Assert.IsTrue(FEfx.LoadFile('efx/b.efx', True));
  Assert.AreEqual(2, FEfx.Count);
  Assert.IsTrue(FEfx.LoadFile('efx/a.efx'));
  Assert.AreEqual(3, FEfx.Count);
end;

procedure TTestEfxEffectsFile.DovrebbeSvuotareLaListaConUnloadFile;
var
  LEffect: TEfxEffect;
  LIndex: Integer;
begin
  Load('Version 1 reverb "a" { }');
  FEfx.UnloadFile;
  Assert.AreEqual(0, FEfx.Count);
  Assert.IsFalse(FEfx.FindEffect('a', LEffect, LIndex));
end;

procedure TTestEfxEffectsFile.DovrebbeSolleverePerUnaVersioneSconosciuta;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('Version 2 reverb "x" { }');
    end, EIdLexerException, 'file efx/test\.efx, line 1: idEFXFile::LoadFile: Unknown file version');
end;

procedure TTestEfxEffectsFile.DovrebbeSollevarePerUnFileSenzaVersione;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('reverb "x" { }');
    end, EIdLexerException, 'expected ''Version'' but found ''reverb''');
end;

procedure TTestEfxEffectsFile.DovrebbeSolleverePerUnEffettoCheNonESReverb;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('Version 1'#10'eax "x" { }');
    end, EIdLexerException, 'line 2: idEFXFile::ReadEffect: Unknown effect definition');
  FEfx.UnloadFile;
  // the key words are case sensitive
  Assert.WillRaise(
    procedure
    begin
      Load('Version 1'#10'REVERB "x" { }');
    end, EIdLexerException);
end;

procedure TTestEfxEffectsFile.DovrebbeSollevarePerUnaGraffaMancante;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('Version 1'#10'reverb "x" foo');
    end, EIdLexerException, '\{ not found, found foo');
end;

procedure TTestEfxEffectsFile.DovrebbeSollevarePerUnBloccoSenzaGraffaChiusa;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('Version 1'#10'reverb "x" {'#10'"room" 1'#10);
    end, EIdLexerException, 'EOF without closing brace');
  // a file that ends before the brace is just the end of the list
  FEfx.UnloadFile;
  Assert.IsTrue(Load('Version 1'#10'reverb "x"'#10));
  Assert.AreEqual(0, FEfx.Count);
end;

procedure TTestEfxEffectsFile.DovrebbeSollevarePerUnParametroSconosciuto;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('Version 1'#10'reverb "x" { "wrong param" 1 }');
    end, EIdLexerException, 'Invalid parameter in reverb definition');
end;

procedure TTestEfxEffectsFile.DovrebbeTenereGliEffettiLettiPrimaDiUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      Load('Version 1'#10'reverb "ok" { "room" 5 }'#10'reverb "x" { "wrong" 1 }');
    end, EIdLexerException);
  Assert.AreEqual(1, FEfx.Count);
  Assert.AreEqual<string>('ok', string(FEfx[0].Name));
end;

procedure TTestEfxEffectsFile.DovrebbeLeggereUnaVirgolaMobileNegativaEUnInteroSenzaSegno;
begin
  Load('"Version" 1 reverb "n" { "environment" 4294967295 "environment size" -3.25 "room" -2147483647 }');
  Assert.AreEqual<Cardinal>($FFFFFFFF, FEfx[0].Reverb.Environment);
  Assert.AreEqual<Single>(-3.25, FEfx[0].Reverb.EnvironmentSize);
  Assert.AreEqual(-2147483647, FEfx[0].Reverb.Room);
end;

procedure TTestEfxEffectsFile.DovrebbeLeggereIlFlagInEsadecimale;
begin
  Load('Version 1 reverb "h" { "flags" 0x3f }');
  Assert.AreEqual<Cardinal>($3F, FEfx[0].Reverb.Flags);
end;

procedure TTestEfxEffectsFile.DovrebbeUsareLUltimoValoreDiUnParametroRipetuto;
begin
  Load('Version 1 reverb "r" { "room" 5 "room" 7 }');
  Assert.AreEqual(7, FEfx[0].Reverb.Room);
end;

procedure TTestEfxEffectsFile.DovrebbeNonLeggereUnValoreSuUnaRigaDiversa;
begin
  // the number of "environment" is read on the same line only: here it is not, and the 5 is a parameter
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Load('Version 1'#10'reverb "x" { "environment"'#10'5 }');
    end, EIdLexerException, 'Invalid parameter');
end;

procedure TTestEfxEffectsFile.DovrebbeAccettareLeParoleSenzaVirgolette;
begin
  // a key is the text of the token: without the quotes it is the same
  Assert.IsTrue(Load('Version 1 reverb x { room 5 flags 2 }'));
  Assert.AreEqual<string>('x', string(FEfx[0].Name));
  Assert.AreEqual(5, FEfx[0].Reverb.Room);
  Assert.AreEqual<Cardinal>(2, FEfx[0].Reverb.Flags);
end;

procedure TTestEfxEffectsFile.DovrebbeFermarsiSeUnLexerCheNonSollevaTrovaUnErrore;
var
  LSource: TIdLexer;
  LEffect: TEfxEffect;
begin
  LSource := TIdLexer.Create(LEXFL_NOSTRINGCONCAT or LEXFL_NOERRORS, FLog, FFilesIntf);
  try
    LSource.LoadMemory('reverb "x" { "wrong" 1 }', 'mem');
    Assert.IsFalse(FEfx.ReadEffect(LSource, LEffect));
    LSource.FreeSource;
    LSource.LoadMemory('eax "x" { }', 'mem');
    Assert.IsFalse(FEfx.ReadEffect(LSource, LEffect));
    LSource.FreeSource;
    LSource.LoadMemory('reverb "x" foo', 'mem');
    Assert.IsFalse(FEfx.ReadEffect(LSource, LEffect));
    LSource.FreeSource;
    LSource.LoadMemory('reverb "x" {', 'mem');
    Assert.IsFalse(FEfx.ReadEffect(LSource, LEffect));
    LSource.FreeSource;
    LSource.LoadMemory('', 'mem');
    Assert.IsFalse(FEfx.ReadEffect(LSource, LEffect));
  finally
    LSource.Free;
  end;
end;

procedure TTestEfxEffectsFile.DovrebbeDareIlNumeroDiEffetti;
begin
  Assert.AreEqual(0, FEfx.Count);
  Load('Version 1 reverb "a" { } reverb "b" { } reverb "c" { }');
  Assert.AreEqual(3, FEfx.Count);
end;

{ TTestEfxGolden }

function TTestEfxGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Audio\');
end;

procedure TTestEfxGolden.Emit(const ALine: string);
begin
  FLines.Add(ALine);
end;

class function TTestEfxGolden.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

procedure TTestEfxGolden.DumpEffects;
var
  LIndex: Integer;
  LReverb: TEfxReverbProperties;
begin
  Emit(Format('n=%d', [FEfx.Count]));
  for LIndex := 0 to FEfx.Count - 1 do
  begin
    LReverb := FEfx[LIndex].Reverb;
    Emit(Format('fx %d name=[%s] size=%d', [LIndex, TFakeIdLibLog.Escape(FEfx[LIndex].Name), SizeOf(LReverb)]));
    Emit(Format(' env=%u size=%s diff=%s room=%d,%d,%d decay=%s,%s,%s', [LReverb.Environment,
      Bits(LReverb.EnvironmentSize), Bits(LReverb.EnvironmentDiffusion), LReverb.Room, LReverb.RoomHF, LReverb.RoomLF,
      Bits(LReverb.DecayTime), Bits(LReverb.DecayHFRatio), Bits(LReverb.DecayLFRatio)]));
    Emit(Format(' refl=%d,%s pan=%s,%s,%s reverb=%d,%s pan=%s,%s,%s', [LReverb.Reflections,
      Bits(LReverb.ReflectionsDelay), Bits(LReverb.ReflectionsPan.X), Bits(LReverb.ReflectionsPan.Y),
      Bits(LReverb.ReflectionsPan.Z), LReverb.Reverb, Bits(LReverb.ReverbDelay), Bits(LReverb.ReverbPan.X),
      Bits(LReverb.ReverbPan.Y), Bits(LReverb.ReverbPan.Z)]));
    Emit(Format(' echo=%s,%s mod=%s,%s air=%s hf=%s lf=%s rolloff=%s flags=%u', [Bits(LReverb.EchoTime),
      Bits(LReverb.EchoDepth), Bits(LReverb.ModulationTime), Bits(LReverb.ModulationDepth),
      Bits(LReverb.AirAbsorptionHF), Bits(LReverb.HFReference), Bits(LReverb.LFReference),
      Bits(LReverb.RoomRolloffFactor), LReverb.Flags]));
  end;
end;

procedure TTestEfxGolden.Execute(const AOperation: string);
var
  LWords: TArray<string>;
  LEffect: TEfxEffect;
  LIndex: Integer;
  LName: string;
begin
  LWords := AOperation.Split([' '], TStringSplitOptions.ExcludeEmpty);
  Emit('> ' + string.Join(' ', LWords));
  if LWords[0] = 'load' then
  begin
    try
      Emit(Format('ret=%d', [Ord(FEfx.LoadFile(AnsiString(LWords[1]), (Length(LWords) > 2) and (LWords[2] = 'os')))]));
    except
      on E: EIdLexerException do
        Emit('ERR ' + E.Message);
    end;
    DumpEffects;
  end
  else if LWords[0] = 'find' then
  begin
    LName := string.Join(' ', Copy(LWords, 1, MaxInt));
    Emit(Format('find ret=%d index=%d', [Ord(FEfx.FindEffect(AnsiString(LName), LEffect, LIndex)), LIndex]));
  end
  else if LWords[0] = 'unload' then
  begin
    FEfx.UnloadFile;
    DumpEffects;
  end
  else if LWords[0] = 'size' then
    Emit(Format('size=%d', [SizeOf(TEfxReverbProperties)]));
end;

function TTestEfxGolden.Run(const AInput: TStrings): TStringList;
var
  LLine: string;
  LFile: string;
  LInFile: Boolean;
begin
  Result := TStringList.Create;
  FLines := Result;
  FLog := TFakeIdLibLog.Create(Result);
  FFiles := TFakeIdLibFileSystem.Create;
  FFilesIntf := FFiles;
  FEfx := TEfxEffectsFile.Create(FFilesIntf, FLog);
  LInFile := False;
  try
    for LLine in AInput do
    begin
      if LLine.StartsWith('@case ') then
      begin
        FEfx.UnloadFile;
        FFiles.Clear;
        LInFile := False;
        Emit('## ' + Copy(LLine, 7, MaxInt));
      end
      else if LLine = '@end' then
        LInFile := False
      else if LLine.StartsWith('@file ') then
      begin
        LFile := Copy(LLine, 7, MaxInt);
        FFiles.Add(AnsiString(LFile), '');
        LInFile := True;
      end
      else if LLine.StartsWith('@op ') then
      begin
        LInFile := False;
        Execute(Copy(LLine, 5, MaxInt));
      end
      else if LInFile then
        FFiles.Add(AnsiString(LFile), FFiles.Content(AnsiString(LFile)) + AnsiString(LLine) + #10);
    end;
  finally
    FreeAndNil(FEfx);
    FFilesIntf := nil;
    FLog := nil;
    FLines := nil;
  end;
end;

procedure TTestEfxGolden.DovrebbeDareLeStesseRisposteDelVeroIdEfxFile;
var
  LInput, LGolden, LActual: TStringList;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'efx.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'efx.golden.txt', TEncoding.ANSI);
    LActual := Run(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (LGolden[LIndex] <> LActual[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.efx.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEfxEffectsFile);
  TDUnitX.RegisterTestFixture(TTestEfxGolden);

end.
