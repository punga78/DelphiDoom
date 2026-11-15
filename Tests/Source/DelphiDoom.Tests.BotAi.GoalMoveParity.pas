{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity test of the goals, the movement, the elementary          }
{  actions and the genetic selection of the bots with the real code of        }
{  Quake III Arena (be_ai_goal.c, be_ai_move.c, be_ai_gen.c, be_ea.c on the   }
{  real be_aas_*.c): Tests\Data\BotAi\goal\goalmove.golden.txt is the answer   }
{  of Tools\Verifica\123\ai (see LEGGIMI.md)                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.GoalMoveParity;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi.Parity')]
  TTestBotGoalMoveParity = class
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCSulloScenarioIntero;
    [Test]
    procedure DovrebbeDareLeStesseRisposteSeLoScenarioSiRipete;
    [Test]
    procedure DovrebbeAvereNelloScenarioOgniTipoDiViaggio;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Tests.BotAi.Support,
  DelphiDoom.Tests.BotAi.GoalMoveScenario;

function GoalFolder: string;
begin
  Result := TPath.Combine(BotDataFolder, 'goal');
end;

function RunScenario: TStringList;
var
  LScenario: TStringList;
  LRunner: TGoalMoveScenario;
begin
  LScenario := TStringList.Create;
  LRunner := TGoalMoveScenario.Create(GoalFolder);
  try
    LScenario.LoadFromFile(TPath.Combine(GoalFolder, 'goalmove.txt'));
    LRunner.Run(LScenario);
    Result := TStringList.Create;
    Result.AddStrings(LRunner.Output);
  finally
    LRunner.Free;
    LScenario.Free;
  end;
end;

{ TTestBotGoalMoveParity }

procedure TTestBotGoalMoveParity.DovrebbeDareLeStesseRisposteDelCSulloScenarioIntero;
var
  LGolden: TStringList;
  LActual: TStringList;
  LIndex: Integer;
begin
  LGolden := TStringList.Create;
  LActual := RunScenario;
  try
    LGolden.LoadFromFile(TPath.Combine(GoalFolder, 'goalmove.golden.txt'));
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LActual.Count then
        Assert.Fail(Format('Manca la riga %d: %s', [LIndex + 1, LGolden[LIndex]]));
      if LGolden[LIndex] <> LActual[LIndex] then
        Assert.Fail(Format('Riga %d: il C da''%s'' e Delphi ''%s''', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]));
    end;
    Assert.AreEqual(LGolden.Count, LActual.Count, 'Righe in piu'' di Delphi');
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestBotGoalMoveParity.DovrebbeDareLeStesseRisposteSeLoScenarioSiRipete;
var
  LFirst: TStringList;
  LSecond: TStringList;
  LIndex: Integer;
begin
  LFirst := RunScenario;
  LSecond := RunScenario;
  try
    Assert.AreEqual(LFirst.Count, LSecond.Count);
    for LIndex := 0 to LFirst.Count - 1 do
      if LFirst[LIndex] <> LSecond[LIndex] then
        Assert.Fail(Format('Riga %d: ''%s'' e ''%s''', [LIndex + 1, LFirst[LIndex], LSecond[LIndex]]));
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestBotGoalMoveParity.DovrebbeAvereNelloScenarioOgniTipoDiViaggio;
var
  LActual: TStringList;
  LKinds: array[0..31] of Boolean;
  LLine: string;
  LText: string;
  LValue: Integer;
  LIndex: Integer;
begin
  LActual := RunScenario;
  try
    for LIndex := 0 to High(LKinds) do
      LKinds[LIndex] := False;
    for LLine in LActual do
    begin
      // the results of the movement: "RES F 0 T 0 B 0 BE 0 TT 2 FL 0 ..." and, in a simulation, " R F 0 ..."
      if LLine.StartsWith('RES F') or LLine.StartsWith(' R F') then
      begin
        LText := Copy(LLine, Pos(' TT ', LLine) + 4, MaxInt);
        LValue := StrToIntDef(Copy(LText, 1, Pos(' ', LText) - 1), -1);
        if (LValue >= 0) and (LValue <= High(LKinds)) then
          LKinds[LValue] := True;
      end;
    end;
    // walk, crouch, barrier jump, jump, ladder, walk off ledge, swim, water jump, teleport, elevator, rocket jump,
    // BFG jump, grapple hook, jump pad, func bobbing
    for LIndex in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 18, 19] do
      Assert.IsTrue(LKinds[LIndex], 'Il tipo di viaggio ' + IntToStr(LIndex) + ' non e'' nello scenario');
  finally
    LActual.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBotGoalMoveParity);

end.
