{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the gatherers with the C   }
{  of the remake                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.GatherParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   gather.*.golden.txt are the output of war_model_ref.exe (Tools\Verifica\194, `gather`): the gathering states of war1
  ///   (gather gold, mining, gather wood, chopping, deliver, the felling of trees, the exhaustion of a mine) compiled as
  ///   they are with gcc. Ten scenarios of 1800 tics (two factions with town hall, mine, forest and three workers) with
  ///   a fingerprint of the whole state per tic, a summary line each and the text of the full state of one tic
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarGatherParity = class(TObject)
  private
    function Golden(const AName: string): TStringList;
    procedure CompareLines(const AExpected, AActual: TStringList);
  public
    [Test]
    procedure DovrebbeDareLeStesseImprontiPerTicDiDieciScenariDiRaccolta;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoAUnTicDiRaccolta;
    [Test]
    procedure DovrebbeDareLeStesseImmaginiDeiTrasportatoriDelC;
    [Test]
    procedure DovrebbeEsercitareOgniParteDellaRaccoltaNegliScenari;
    /// <summary>
    ///   An aid to find a difference, not a test: with DELPHIDOOM_WAR_GATHER_DUMP set to "seed,tic,file" the text of the
    ///   state of that tic is written to the file, to compare with `war_model_ref dump gather seed tic`
    /// </summary>
    [Test]
    procedure DovrebbeScrivereIlTestoDelloStatoSeRichiesto;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.War.Model.WorkerSprites.Data, DelphiDoom.Tests.War.GatherScenario;

{ TTestWarGatherParity }

function TTestWarGatherParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarGatherParity.CompareLines(const AExpected, AActual: TStringList);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AExpected.Count - 1 do
  begin
    Assert.IsTrue(LIndex < AActual.Count, 'Il modello ha meno righe del C: ' + AExpected[LIndex]);
    Assert.AreEqual(AExpected[LIndex], AActual[LIndex], Format('riga %d', [LIndex + 1]));
  end;
  Assert.AreEqual<Integer>(AExpected.Count, AActual.Count);
end;

procedure TTestWarGatherParity.DovrebbeDareLeStesseImprontiPerTicDiDieciScenariDiRaccolta;
var
  LGolden: TStringList;
  LActual: TStringList;
  LSeed: Integer;
  LDump: string;
begin
  LGolden := Golden('gather.golden.txt');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to 10 do
      TGatherScenario.Run(LSeed, -1, LActual, LDump);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarGatherParity.DovrebbeDareLoStessoTestoDelloStatoAUnTicDiRaccolta;
var
  LGolden: TStringList;
  LActual: TStringList;
  LDump: string;
begin
  LGolden := Golden('gather.dump.golden.txt');
  LActual := TStringList.Create;
  try
    TGatherScenario.Run(2, 900, nil, LDump);
    LActual.Text := LDump;
    while (LActual.Count > 0) and (LActual[LActual.Count - 1] = '') do
      LActual.Delete(LActual.Count - 1);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarGatherParity.DovrebbeDareLeStesseImmaginiDeiTrasportatoriDelC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LWorkers: Integer;
begin
  LGolden := Golden('gather.tables.golden.txt');
  try
    LWorkers := 0;
    for LLine in LGolden do
    begin
      LFields := LLine.Split([' ']);
      if LLine.StartsWith('W ') then
      begin
        Assert.AreEqual<Integer>(StrToInt(LFields[1]), WAR_WORKER_SPRITES[LWorkers].UnitType, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[2]), WAR_WORKER_SPRITES[LWorkers].CarryingWood, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[3]), WAR_WORKER_SPRITES[LWorkers].CarryingGold, LLine);
        Inc(LWorkers);
      end;
    end;
    Assert.AreEqual<Integer>(Length(WAR_WORKER_SPRITES), LWorkers);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarGatherParity.DovrebbeScrivereIlTestoDelloStatoSeRichiesto;
var
  LRequest: string;
  LParts: TArray<string>;
  LDump: string;
begin
  LRequest := GetEnvironmentVariable('DELPHIDOOM_WAR_GATHER_DUMP');
  if LRequest = '' then
  begin
    Assert.Pass('DELPHIDOOM_WAR_GATHER_DUMP non e'' impostata');
    Exit;
  end;
  LParts := LRequest.Split([',']);
  TGatherScenario.Run(StrToInt(LParts[0]), StrToInt(LParts[1]), nil, LDump);
  TFile.WriteAllText(LParts[2], LDump.Replace(#10, #13#10), TEncoding.ASCII);
end;

procedure TTestWarGatherParity.DovrebbeEsercitareOgniParteDellaRaccoltaNegliScenari;
var
  LGolden: TStringList;
  LLine: string;
  LSeedsWithTrees: Integer;
  LSeedsWithMineEmpty: Integer;
  LSeedsWithGold: Integer;
  LSeedsWithWood: Integer;
  LFields: TArray<string>;
begin
  // the summary lines of the golden say that the scenarios did something: wood and gold delivered, mines emptied, trees felled
  LGolden := Golden('gather.golden.txt');
  try
    LSeedsWithTrees := 0;
    LSeedsWithMineEmpty := 0;
    LSeedsWithGold := 0;
    LSeedsWithWood := 0;
    for LLine in LGolden do
    begin
      if not LLine.StartsWith('Q ') then
        Continue;
      // Q seed gold=a,b wood=a,b mines=a,b trees=a,b tiles=n
      LFields := LLine.Split([' ']);
      if LFields[6] <> 'tiles=0' then
        Inc(LSeedsWithTrees);
      if LFields[4].EndsWith('=0') or LFields[4].Contains('=0,') or LFields[4].EndsWith(',0') then
        Inc(LSeedsWithMineEmpty);
      if LFields[2] <> 'gold=5000,5000' then
        Inc(LSeedsWithGold);
      if LFields[3] <> 'wood=5000,5000' then
        Inc(LSeedsWithWood);
    end;
    Assert.IsTrue(LSeedsWithTrees >= 5, 'Troppo pochi scenari abbattono alberi');
    Assert.IsTrue(LSeedsWithMineEmpty >= 5, 'Troppo pochi scenari esauriscono una miniera');
    Assert.IsTrue(LSeedsWithGold >= 8, 'Troppo pochi scenari consegnano oro');
    Assert.IsTrue(LSeedsWithWood >= 8, 'Troppo pochi scenari consegnano legna');
  finally
    LGolden.Free;
  end;
end;

end.
