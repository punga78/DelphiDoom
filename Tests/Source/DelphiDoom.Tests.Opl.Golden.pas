{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OPL library - parity with fmopl.cpp and             }
{  adlplayer.cpp of OpenXcom                                                    }
{                                                                              }
{  The files of Tests\Data\Opl are what the real C++ files, compiled by an      }
{  harness outside the repository, printed (Tests\Data\README.md):              }
{    opl.tables.golden.txt  hashes of the static tables and of the tables of    }
{                           chips with seven clock and rate pairs               }
{    opl.script.txt/opl.golden.txt      80 scenarios of the chip (instruments,  }
{                           rhythm, random registers, two chips, timers)        }
{    adlib.songs.txt, adlib.script.txt/adlib.golden.txt  21 scenarios of the    }
{                           player on 14 songs                                  }
{                                                                              }
{  Derived from fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later) and   }
{  OpenXcom (GPL v3 or later): see Libs\Opl\README.md                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Opl.Golden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Opl.Types, DelphiDoom.Opl.Intf,
  DelphiDoom.Opl.Tables, DelphiDoom.Opl.Noise, DelphiDoom.Opl.Chip, DelphiDoom.Tests.Opl.Script;

type
  [TestFixture]
  [Category('opl')]
  [Category('opl-golden')]
  TTestOplGolden = class(TObject)
  private
    function DataFile(const AName: string): string;
    function Lines(const AName: string): TStringList;
    procedure CompareLines(const AExpected, AActual: TStringList);
    function Fnv(const AValues: TArray<Integer>): UInt64;
    function HashText(AValue: UInt64): string;
    function TableLine(const AName: string; const AValues: TArray<Integer>): string;
  public
    [Test]
    procedure DovrebbeDareLeStesseTabelleDelC;
    [Test]
    procedure DovrebbeDareLeStesseTabelleDiOgniChipDelC;
    [Test]
    procedure DovrebbeDareLeStesseRigheDelC_SuTuttiGliScenariDelChip;
    [Test]
    procedure DovrebbeDareLeStesseRigheDelC_SuTuttiGliScenariDelPlayer;
    [Test]
    procedure DovrebbeRipetereLoStessoRisultatoAOgniEsecuzione;
  end;

implementation

{$Q-}
{$R-}

type
  TChipConfig = record
    Clock: Integer;
    Rate: Integer;
  end;

const
  CHIP_CONFIGS: array[0..6] of TChipConfig = (
    (Clock: 3579545; Rate: 49716), (Clock: 3579545; Rate: 44100), (Clock: 3579545; Rate: 22050),
    (Clock: 3579545; Rate: 11025), (Clock: 3579545; Rate: 48000), (Clock: 3600000; Rate: 32000),
    (Clock: 3579545; Rate: 8000));

{ TTestOplGolden }

function TTestOplGolden.DataFile(const AName: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 6 do
  begin
    Result := LFolder + 'Tests\Data\Opl\' + AName;
    if FileExists(Result) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  raise Exception.CreateFmt('Data file %s not found', [AName]);
end;

function TTestOplGolden.Lines(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.LoadFromFile(DataFile(AName));
  except
    Result.Free;
    raise;
  end;
end;

procedure TTestOplGolden.CompareLines(const AExpected, AActual: TStringList);
var
  LIndex: Integer;
begin
  Assert.AreEqual(AExpected.Count, AActual.Count, 'numero di righe');
  for LIndex := 0 to AExpected.Count - 1 do
    if AExpected[LIndex] <> AActual[LIndex] then
      Assert.Fail(Format('riga %d: atteso "%s" ottenuto "%s"', [LIndex + 1, AExpected[LIndex], AActual[LIndex]]));
end;

function TTestOplGolden.Fnv(const AValues: TArray<Integer>): UInt64;
var
  LIndex: Integer;
  LShift: Integer;
begin
  Result := UInt64($CBF29CE484222325);
  for LIndex := 0 to High(AValues) do
    for LShift := 0 to 3 do
      Result := (Result xor ((Cardinal(AValues[LIndex]) shr (8 * LShift)) and $FF)) * UInt64($100000001B3);
end;

function TTestOplGolden.HashText(AValue: UInt64): string;
begin
  Result := LowerCase(IntToHex(AValue, 16));
end;

function TTestOplGolden.TableLine(const AName: string; const AValues: TArray<Integer>): string;
begin
  Result := Format('TABLE %s %d %s', [AName, Length(AValues), HashText(Fnv(AValues))]);
end;

procedure TTestOplGolden.DovrebbeDareLeStesseTabelleDelC;
var
  LGolden: TStringList;
  LTables: IOplTables;
  LActual: TStringList;
begin
  LGolden := Lines('opl.tables.golden.txt');
  LActual := TStringList.Create;
  try
    LTables := TOplTables.Create;
    LActual.Add(TableLine('TL', LTables.TotalLevel));
    LActual.Add(TableLine('SIN', LTables.SinOffsets));
    LActual.Add(TableLine('ENV', LTables.EnvelopeCurve));
    LActual.Add(TableLine('AMS', LTables.AmsTable));
    LActual.Add(TableLine('VIB', LTables.VibTable));
    Assert.AreEqual(LGolden[0], LActual[0], 'TL_TABLE');
    Assert.AreEqual(LGolden[1], LActual[1], 'SIN_TABLE');
    Assert.AreEqual(LGolden[2], LActual[2], 'ENV_CURVE');
    Assert.AreEqual(LGolden[3], LActual[3], 'AMS_TABLE');
    Assert.AreEqual(LGolden[4], LActual[4], 'VIB_TABLE');
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestOplGolden.DovrebbeDareLeStesseTabelleDiOgniChipDelC;
var
  LGolden: TStringList;
  LTables: IOplTables;
  LChip: IOplChip;
  LObject: TOplChip;
  LIndex: Integer;
  LAttack: TArray<Integer>;
  LDecay: TArray<Integer>;
  LSteps: TArray<Integer>;
  LStep: Integer;
  LLine: string;
begin
  LGolden := Lines('opl.tables.golden.txt');
  try
    LTables := TOplTables.Create;
    for LIndex := 0 to High(CHIP_CONFIGS) do
    begin
      LObject := TOplChip.Create(LTables, TOplMsvcrtNoise.Create(1), octYm3812, CHIP_CONFIGS[LIndex].Clock,
        CHIP_CONFIGS[LIndex].Rate);
      LChip := LObject;
      SetLength(LAttack, 75);
      SetLength(LDecay, 75);
      SetLength(LSteps, 1024);
      for LStep := 0 to 74 do
      begin
        LAttack[LStep] := LObject.AttackRate(LStep);
        LDecay[LStep] := LObject.DecayRate(LStep);
      end;
      for LStep := 0 to 1023 do
        LSteps[LStep] := Integer(LObject.FrequencyStep(LStep));
      LLine := Format('CHIPTABLE %d %d AR %s DR %s FN %s ams %d vib %d', [CHIP_CONFIGS[LIndex].Clock,
        CHIP_CONFIGS[LIndex].Rate, HashText(Fnv(LAttack)), HashText(Fnv(LDecay)), HashText(Fnv(LSteps)),
        LObject.AmsIncrement, LObject.VibIncrement]);
      Assert.AreEqual(LGolden[5 + LIndex], LLine, 'chip ' + IntToStr(LIndex));
      LChip := nil;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestOplGolden.DovrebbeDareLeStesseRigheDelC_SuTuttiGliScenariDelChip;
var
  LScript, LGolden, LActual: TStringList;
  LRunner: TOplScriptRunner;
begin
  LScript := Lines('opl.script.txt');
  LGolden := Lines('opl.golden.txt');
  LRunner := TOplScriptRunner.Create;
  try
    LActual := LRunner.Run(LScript);
    CompareLines(LGolden, LActual);
  finally
    LRunner.Free;
    LGolden.Free;
    LScript.Free;
  end;
end;

procedure TTestOplGolden.DovrebbeDareLeStesseRigheDelC_SuTuttiGliScenariDelPlayer;
var
  LSongs, LScript, LGolden, LActual: TStringList;
  LRunner: TOplScriptRunner;
begin
  LSongs := Lines('adlib.songs.txt');
  LScript := Lines('adlib.script.txt');
  LGolden := Lines('adlib.golden.txt');
  LRunner := TOplScriptRunner.Create;
  try
    LRunner.LoadSongs(LSongs);
    LActual := LRunner.Run(LScript);
    CompareLines(LGolden, LActual);
  finally
    LRunner.Free;
    LGolden.Free;
    LScript.Free;
    LSongs.Free;
  end;
end;

procedure TTestOplGolden.DovrebbeRipetereLoStessoRisultatoAOgniEsecuzione;
var
  LScript, LFirst, LSecond: TStringList;
  LRunnerA, LRunnerB: TOplScriptRunner;
begin
  LScript := Lines('opl.script.txt');
  LRunnerA := TOplScriptRunner.Create;
  LRunnerB := TOplScriptRunner.Create;
  try
    LFirst := LRunnerA.Run(LScript);
    LSecond := LRunnerB.Run(LScript);
    Assert.AreEqual(LFirst.Text, LSecond.Text);
  finally
    LRunnerB.Free;
    LRunnerA.Free;
    LScript.Free;
  end;
end;

end.
