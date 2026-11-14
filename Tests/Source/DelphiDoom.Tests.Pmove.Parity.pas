{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pmove library - parity with the player movement    }
{  of Quake III Arena (bg_pmove.c and bg_slidemove.c compiled with gcc)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Pmove.Parity;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.Pmove.Support.Golden;

type
  /// <summary>
  ///   Tests\Data\Pmove\pmove-golden.txt: 192 scenarios of commands (16 kinds of movement) on a made up world,
  ///   with the hash of the state after every command, as the real code of Quake III computes them. The golden
  ///   carries the world and the commands, so nothing is generated here. How it is made: Tools\Verifica\127
  /// </summary>
  [TestFixture]
  [Category('Pmove')]
  [Category('Parity')]
  TTestPmoveParity = class
  strict private
    FLines: TStringList;
    FGolden: TGoldenFile;
    procedure CheckScenario(const AScenario: TGoldenScenario);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TeardownFixture]
    procedure TeardownFixture;
    [Test]
    procedure DovrebbeLeggereTuttiGliScenariDelGolden;
    [TestCase('camminata', '0')]
    [TestCase('salti', '1')]
    [TestCase('accovacciata', '2')]
    [TestCase('gradini', '3')]
    [TestCase('rampe', '4')]
    [TestCase('superfici', '5')]
    [TestCase('acqua', '6')]
    [TestCase('melma e lava', '7')]
    [TestCase('cadute', '8')]
    [TestCase('muri e angoli', '9')]
    [TestCase('noclip spettatore volo', '10')]
    [TestCase('morte e blocchi', '11')]
    [TestCase('rinculo salto dall acqua rampino', '12')]
    [TestCase('armi e oggetti', '13')]
    [TestCase('tempi e passi fissi', '14')]
    [TestCase('stati casuali', '15')]
    procedure DovrebbeDareGliStessiRisultatiDelCPerOgniComando(AMode: Integer);
    [Test]
    procedure DovrebbeUsareLaTabellaDegliOggettiDelC;
    [Test]
    procedure DovrebbeCalcolareIlTempoDiUnPassoComeIlC;
    [Test]
    procedure DovrebbeCalcolareGliAngoliDiVistaComeIlC;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Items, DelphiDoom.Pmove.ViewAngles,
  DelphiDoom.Pmove.Intf, DelphiDoom.Pmove.Factory, DelphiDoom.Logging.Intf, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Fnv, DelphiDoom.Tests.Collision.Q3Support;

procedure TTestPmoveParity.SetupFixture;
begin
  FLines := TTestFiles.Lines(TTestFiles.DataFile('Pmove', 'pmove-golden.txt'), TEncoding.ASCII);
  FGolden := TGoldenFile.Create(FLines);
end;

procedure TTestPmoveParity.TeardownFixture;
begin
  FGolden.Free;
  FLines.Free;
end;

procedure TTestPmoveParity.CheckScenario(const AScenario: TGoldenScenario);
var
  LWorld: IPmoveTrace;
  LMover: IPmove;
  LText: TStringBuilder;
  LDump: TStringList;
  LHashes: TArray<Cardinal>;
  LIndex: Integer;
  LFile: string;
begin
  LText := TStringBuilder.Create;
  LWorld := FGolden.CreateWorld;
  try
    LMover := TPmoveFactory.CreateMover(LWorld, nil, TGoldenLog.Create(LText));
    LHashes := TGoldenRunner.Run(LMover, AScenario, LText, nil);
    Assert.AreEqual<Integer>(Length(AScenario.Hashes), Length(LHashes),
      Format('scenario %d (%s): number of commands', [AScenario.Id, AScenario.Name]));
    for LIndex := 0 to High(LHashes) do
      if LHashes[LIndex] <> AScenario.Hashes[LIndex] then
      begin
        // the state of the scenario, command by command, as "pmgen dump <id>" prints it, to compare
        LMover := nil;
        LMover := TPmoveFactory.CreateMover(LWorld, nil, TGoldenLog.Create(LText));
        LDump := TStringList.Create;
        try
          TGoldenRunner.Run(LMover, AScenario, LText, LDump);
          LFile := TPath.Combine(TPath.GetTempPath, Format('pmove-scenario-%d.txt', [AScenario.Id]));
          LDump.SaveToFile(LFile);
        finally
          LDump.Free;
        end;
        Assert.Fail(Format('scenario %d (%s), command %d: hash %.8x, expected %.8x (state in %s)',
          [AScenario.Id, AScenario.Name, LIndex, LHashes[LIndex], AScenario.Hashes[LIndex], LFile]));
      end;
  finally
    LMover := nil;
    LWorld := nil;
    LText.Free;
  end;
end;

procedure TTestPmoveParity.DovrebbeLeggereTuttiGliScenariDelGolden;
begin
  Assert.AreEqual<Integer>(192, FGolden.Scenarios.Count, 'scenari');
  Assert.IsTrue(Length(FGolden.Scenarios[0].Hashes) > 0, 'comandi del primo scenario');
end;

procedure TTestPmoveParity.DovrebbeDareGliStessiRisultatiDelCPerOgniComando(AMode: Integer);
var
  LScenario: TGoldenScenario;
  LCount: Integer;
begin
  LCount := 0;
  for LScenario in FGolden.Scenarios do
    if LScenario.Id mod 16 = AMode then
    begin
      CheckScenario(LScenario);
      Inc(LCount);
    end;
  Assert.AreEqual(12, LCount, 'scenari del tipo');
end;

procedure TTestPmoveParity.DovrebbeUsareLaTabellaDegliOggettiDelC;
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(Q3_BASE_ITEM_TAGS), Length(FGolden.ItemTags), 'oggetti');
  for LIndex := 0 to High(FGolden.ItemTags) do
    Assert.AreEqual(FGolden.ItemTags[LIndex], Q3_BASE_ITEM_TAGS[LIndex], 'oggetto ' + IntToStr(LIndex));
end;

procedure TTestPmoveParity.DovrebbeCalcolareIlTempoDiUnPassoComeIlC;
var
  LMsec: Integer;
  LValue: Double;
  LFrame: Single;
begin
  Assert.AreEqual<Integer>(200, Length(FGolden.FrameTimes), 'tempi');
  for LMsec := 1 to 200 do
  begin
    LValue := LMsec * Q3_MSEC_TO_SECONDS;
    LFrame := LValue;
    Assert.AreEqual(FGolden.FrameTimes[LMsec - 1], BitsOfFloat(LFrame), 'msec ' + IntToStr(LMsec));
  end;
end;

procedure TTestPmoveParity.DovrebbeCalcolareGliAngoliDiVistaComeIlC;
var
  LHash: Cardinal;
  LValue: Integer;
  LAngle: Single;
  LBits: Cardinal;
begin
  LHash := TTestFnv.OFFSET_32;
  for LValue := -32768 to 32767 do
  begin
    LAngle := TPmoveViewAngles.ShortToAngle(SmallInt(LValue));
    LBits := BitsOfFloat(LAngle);
    TTestFnv.Mix32(LHash, @LBits, 4);
  end;
  Assert.AreEqual(FGolden.AngleHash, LHash);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPmoveParity);

end.
