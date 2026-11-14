{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - parity with the virtual machine of   }
{  Quake III (vm.c and vm_interpreted.c compiled with gcc)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.Qvm.Support;

type
  /// <summary>
  ///   Every program of TQvmPrograms is run on the classes and its lines (return values, system calls with
  ///   their arguments, fingerprint of the data image) are compared with Tests\Data\Qvm\parity.golden.txt,
  ///   which Tools\Verifica\120 made by running the same images on the C of Quake III (32 bit x86, SSE
  ///   floats). Floats are compared as bits: no tolerance. With QVM_DUMP=folder the images and the scenario
  ///   file are written there, to make the golden again
  /// </summary>
  [TestFixture]
  [Category('Qvm')]
  TTestQvmParity = class
  strict private
    class var
      FScenarios: TArray<TQvmScenario>;
      FGolden: TStringList;
    class function Scenarios: TArray<TQvmScenario>; static;
    class function GoldenBlock(const AName: string): TStringList; static;
    procedure CheckGroup(const APrefix: string; AAtLeast: Integer);
  public
    class destructor Destroy;
    [Test]
    procedure LeIstruzioniIntereDovrebberoDareLeRisposteDelC;
    [Test]
    procedure LeDivisioniCheFermanoIlProcessoreDovrebberoFermareAncheLaMacchina;
    [Test]
    procedure ISaltiCondizionatiDovrebberoDareLeRisposteDelC;
    [Test]
    procedure LeIstruzioniFloatDovrebberoDareGliStessiBitDelC;
    [Test]
    procedure CaricamentiScrittureECopieDovrebberoLasciareLaStessaMemoriaDelC;
    [Test]
    procedure ChiamateRicorsioneETabelleDiSaltoDovrebberoDareLeRisposteDelC;
    [Test]
    procedure LeIstruzioniSenzaEffettoELoStackSbilanciatoDovrebberoFareComeIlC;
    [Test]
    procedure LeChiamateDiSistemaDovrebberoArrivareAllHostComeNelC;
    [Test]
    procedure IProgrammiCompostiDovrebberoDareLeRisposteDelC;
    [Test]
    procedure IProgrammiCasualiDovrebberoDareLeRisposteDelC;
    [Test]
    procedure IlGoldenNonDovrebbeAvereScenariCheNonEsistonoPiu;
    [Test]
    procedure DovrebbeScrivereImmaginiEScenariSeRichiesto;
  end;

implementation

uses
  System.IOUtils, DUnitX.Exceptions, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Qvm.Programs;

const
  GOLDEN_AREA = 'Qvm';
  GOLDEN_FILE = 'parity.golden.txt';
  DUMP_VARIABLE = 'QVM_DUMP';
  BENCH_IMAGE = 1 shl 22;

{ TTestQvmParity }

class destructor TTestQvmParity.Destroy;
begin
  FGolden.Free;
end;

class function TTestQvmParity.Scenarios: TArray<TQvmScenario>;
begin
  if Length(FScenarios) = 0 then
    FScenarios := TQvmPrograms.All;
  Result := FScenarios;
end;

class function TTestQvmParity.GoldenBlock(const AName: string): TStringList;
var
  LIndex: Integer;
begin
  if not Assigned(FGolden) then
    FGolden := TTestFiles.Lines(TTestFiles.DataFile(GOLDEN_AREA, GOLDEN_FILE));
  Result := TStringList.Create;
  LIndex := FGolden.IndexOf('scenario ' + AName);
  if LIndex < 0 then
    Exit;
  repeat
    Result.Add(FGolden[LIndex]);
    Inc(LIndex);
  until (LIndex >= FGolden.Count) or (FGolden[LIndex - 1] = 'end');
end;

procedure TTestQvmParity.CheckGroup(const APrefix: string; AAtLeast: Integer);
var
  LScenario: TQvmScenario;
  LGolden, LActual: TStringList;
  LCount: Integer;
begin
  LCount := 0;
  for LScenario in Scenarios do
  begin
    if not LScenario.Name.StartsWith(APrefix) then
      Continue;
    Inc(LCount);
    LActual := TStringList.Create;
    LGolden := GoldenBlock(LScenario.Name);
    try
      TQvmScenarioRunner.Run(LScenario, LActual);
      try
        TTestGolden.AssertSameLines(LGolden, LActual);
      except
        // which scenario it was
        on E: ETestFailure do
          raise ETestFailure.Create(LScenario.Name + ', ' + E.Message);
      end;
    finally
      LGolden.Free;
      LActual.Free;
    end;
  end;
  Assert.IsTrue(LCount >= AAtLeast, Format('%d scenari con prefisso %s', [LCount, APrefix]));
end;

procedure TTestQvmParity.LeIstruzioniIntereDovrebberoDareLeRisposteDelC;
begin
  CheckGroup('int.', 19);
end;

procedure TTestQvmParity.LeDivisioniCheFermanoIlProcessoreDovrebberoFermareAncheLaMacchina;
begin
  CheckGroup('trap.', 6);
end;

procedure TTestQvmParity.ISaltiCondizionatiDovrebberoDareLeRisposteDelC;
begin
  CheckGroup('branch.', 16);
end;

procedure TTestQvmParity.LeIstruzioniFloatDovrebberoDareGliStessiBitDelC;
begin
  CheckGroup('float.', 6);
end;

procedure TTestQvmParity.CaricamentiScrittureECopieDovrebberoLasciareLaStessaMemoriaDelC;
begin
  CheckGroup('mem.', 5);
end;

procedure TTestQvmParity.ChiamateRicorsioneETabelleDiSaltoDovrebberoDareLeRisposteDelC;
begin
  CheckGroup('call.', 4);
end;

procedure TTestQvmParity.LeIstruzioniSenzaEffettoELoStackSbilanciatoDovrebberoFareComeIlC;
begin
  CheckGroup('misc.', 5);
end;

procedure TTestQvmParity.LeChiamateDiSistemaDovrebberoArrivareAllHostComeNelC;
begin
  CheckGroup('sys.', 6);
end;

procedure TTestQvmParity.IProgrammiCompostiDovrebberoDareLeRisposteDelC;
begin
  CheckGroup('comp.', 4);
end;

procedure TTestQvmParity.IProgrammiCasualiDovrebberoDareLeRisposteDelC;
begin
  CheckGroup('random.', 60);
end;

procedure TTestQvmParity.IlGoldenNonDovrebbeAvereScenariCheNonEsistonoPiu;
var
  LScenario: TQvmScenario;
  LNames: TStringList;
  LLine: string;
  LGolden: TStringList;
  LCount: Integer;
begin
  LGolden := GoldenBlock('');
  LGolden.Free;
  LNames := TStringList.Create;
  try
    for LScenario in Scenarios do
      LNames.Add('scenario ' + LScenario.Name);
    LCount := 0;
    for LLine in FGolden do
      if LLine.StartsWith('scenario ') then
      begin
        Inc(LCount);
        Assert.IsTrue(LNames.IndexOf(LLine) >= 0, LLine);
      end;
    Assert.AreEqual(LNames.Count, LCount);
  finally
    LNames.Free;
  end;
end;

procedure TTestQvmParity.DovrebbeScrivereImmaginiEScenariSeRichiesto;
var
  LFolder, LFile, LCommand: string;
  LScenario: TQvmScenario;
  LLines: TStringList;
begin
  LFolder := GetEnvironmentVariable(DUMP_VARIABLE);
  if LFolder = '' then
  begin
    Assert.Pass('QVM_DUMP non e'' impostata: niente da scrivere');
    Exit;
  end;
  TDirectory.CreateDirectory(LFolder);
  LLines := TStringList.Create;
  try
    for LScenario in Scenarios do
    begin
      LFile := LScenario.Name.Replace('.', '_');
      TFile.WriteAllBytes(TPath.Combine(LFolder, LFile + '.qvm'), LScenario.Image);
      if LScenario.MapText <> '' then
      begin
        TFile.WriteAllBytes(TPath.Combine(LFolder, LFile + '.map'), BytesOf(LScenario.MapText));
        LLines.Add(Format('scenario %s %s %s.qvm %s.map', [LScenario.Name,
          TQvmScenarioRunner.ProfileName(LScenario.Profile), LFile, LFile]));
      end
      else
        LLines.Add(Format('scenario %s %s %s.qvm -', [LScenario.Name,
          TQvmScenarioRunner.ProfileName(LScenario.Profile), LFile]));
      for LCommand in LScenario.Commands do
        LLines.Add(LCommand);
      LLines.Add('end');
    end;
    LLines.SaveToFile(TPath.Combine(LFolder, 'scenarios.txt'), TEncoding.ASCII);
    // the program of the speed test, for qvmrun bench
    TFile.WriteAllBytes(TPath.Combine(LFolder, 'bench.qvm'), TQvmPrograms.Sieve(BENCH_IMAGE));
  finally
    LLines.Free;
  end;
  Assert.IsTrue(TFile.Exists(TPath.Combine(LFolder, 'scenarios.txt')));
end;

end.
