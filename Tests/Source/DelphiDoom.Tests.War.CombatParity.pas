{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the combat with the C      }
{  of the remake                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CombatParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   model.steps, model.combat and model.combat.dump are the output of war_model_ref.exe (Tools\Verifica\194, group
  ///   '194 attacco'): the steps of all the actions, and 16 combat scenarios of 600 tics (two armies, orders to attack,
  ///   follow and patrol, projectiles, splash damage, deaths) with the fingerprint of all the state at every tic
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarCombatParity = class(TObject)
  private
    function Golden(const AName: string): TStringList;
    procedure CompareLines(const AExpected, AActual: TStringList);
  public
    [Test]
    procedure DovrebbeDareIPassiDelleAzioniDelC;
    [Test]
    procedure DovrebbeDareLeStesseImprontiPerTicDiSediciScenariDiCombattimento;
    [Test]
    procedure DovrebbeDareLoStessoTestoDelloStatoDelCombattimentoAUnTic;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.ActionSteps.Data, DelphiDoom.Tests.War.CombatScenario;

{ TTestWarCombatParity }

function TTestWarCombatParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarCombatParity.CompareLines(const AExpected, AActual: TStringList);
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

procedure TTestWarCombatParity.DovrebbeDareIPassiDelleAzioniDelC;
var
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LPair: TArray<string>;
  LType: Integer;
  LAction: Integer;
  LDef: TWarActionDefData;
  LIndex: Integer;
  LCount: Integer;
begin
  LGolden := Golden('model.steps.golden.txt');
  try
    LCount := 0;
    for LLine in LGolden do
    begin
      if not LLine.StartsWith('K ') then
        Continue;
      LFields := LLine.Split([' ']);
      LType := StrToInt(LFields[1]);
      LAction := StrToInt(LFields[2]);
      LDef := WAR_ACTION_DEF_DATA[LType, LAction];
      Assert.AreEqual(LFields[3] = '1', LDef.Present, LLine);
      if LDef.Present then
      begin
        Assert.AreEqual(LFields[4] = '1', LDef.Loop, LLine);
        Assert.AreEqual(LFields[5] = '1', LDef.Directional, LLine);
        Assert.AreEqual<Integer>(StrToInt(LFields[6]), LDef.Count, LLine);
        for LIndex := 0 to LDef.Count - 1 do
        begin
          LPair := LFields[7 + LIndex].Split([',']);
          Assert.AreEqual<Integer>(StrToInt(LPair[0]), WAR_ACTION_STEP_DATA[LDef.Start + LIndex].Kind, LLine);
          Assert.AreEqual<Integer>(StrToInt(LPair[1]), WAR_ACTION_STEP_DATA[LDef.Start + LIndex].Param, LLine);
        end;
      end;
      Inc(LCount);
    end;
    Assert.AreEqual<Integer>(WAR_UNIT_COUNT * 7, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarCombatParity.DovrebbeDareLeStesseImprontiPerTicDiSediciScenariDiCombattimento;
var
  LGolden: TStringList;
  LActual: TStringList;
  LSeed: Integer;
  LDump: string;
begin
  LGolden := Golden('model.combat.golden.txt');
  LActual := TStringList.Create;
  try
    for LSeed := 1 to 16 do
      TCombatScenario.Run(LSeed, -1, LActual, LDump);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarCombatParity.DovrebbeDareLoStessoTestoDelloStatoDelCombattimentoAUnTic;
var
  LGolden: TStringList;
  LActual: TStringList;
  LDump: string;
begin
  LGolden := Golden('model.combat.dump.golden.txt');
  LActual := TStringList.Create;
  try
    TCombatScenario.Run(3, 200, nil, LDump);
    LActual.Text := LDump;
    while (LActual.Count > 0) and (LActual[LActual.Count - 1] = '') do
      LActual.Delete(LActual.Count - 1);
    CompareLines(LGolden, LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
