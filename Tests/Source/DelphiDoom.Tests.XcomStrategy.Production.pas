{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the steps of the      }
{  productions on the real saved games, against what the real OpenXcom         }
{  objects did (simgen production)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Production;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleManufacture,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Production,
  DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.ProductionStepper, DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomProductionStepper = class(TObject)
  strict private
    FSim: TXcomSim;
    FLines: TStringList;
    FRandom: IXcomRandom;
    function Pick(AValue: Integer): Integer;
    procedure RunBase(const AGame: TXcomSavedGame; const ABase: TXcomBase; AVariant, ABaseIndex: Integer);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareLeStesseProduzioniDelVeroOpenXcom;
  end;

implementation

{ TTestXcomProductionStepper }

procedure TTestXcomProductionStepper.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomProductionStepper.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomProductionStepper.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

procedure TTestXcomProductionStepper.RunBase(const AGame: TXcomSavedGame; const ABase: TXcomBase; AVariant,
  ABaseIndex: Integer);
var
  LCount, LK, LItem, LSteps, LIndex: Integer;
  LRule: TXcomRuleManufacture;
  LProduction: TXcomProduction;
  LName: string;
  LProgress: TXcomProductionProgress;
  LStepper: TXcomProductionStepper;
begin
  LStepper := TXcomProductionStepper.Create(FSim.Ruleset);
  try
    LCount := 3 + Pick(5);
    for LK := 0 to LCount - 1 do
    begin
      LRule := FSim.Ruleset.Manufacture.Find(FSim.Ruleset.Manufacture.Index[Pick(Length(FSim.Ruleset.Manufacture.Index))]);
      LProduction := TXcomProduction.Create(LRule, 1 + Pick(6));
      LProduction.AssignedEngineers := 1 + Pick(40);
      LProduction.InfiniteAmount := Pick(8) = 0;
      LProduction.SellItems := Pick(3) = 0;
      for LItem := 0 to LRule.RequiredItems.Count - 1 do
      begin
        LName := LRule.RequiredItems.Key(LItem);
        if Assigned(FSim.Ruleset.Items.Find(LName)) then
          ABase.StorageItems.AddItem(LName, Pick(40))
        else if Assigned(FSim.Ruleset.Crafts.Find(LName)) and (Pick(2) = 0) then
          ABase.Crafts.Add(TXcomCraft.Create(FSim.Ruleset.Crafts.Find(LName), ABase, AGame.GetId(LName)));
      end;
      ABase.AddProduction(LProduction);
    end;
    FLines.Add(Format('base|%d|%d|productions=%d|funds=%d|%s', [AVariant, ABaseIndex, ABase.Productions.Count,
      AGame.Funds, TXcomSim.StorageText(ABase.StorageItems)]));
    for LIndex := 0 to ABase.Productions.Count - 1 do
    begin
      LProduction := ABase.Productions[LIndex];
      LSteps := 0;
      LProgress := ppNotComplete;
      while LSteps < 600 do
      begin
        LProgress := LStepper.Step(LProduction, ABase, AGame);
        Inc(LSteps);
        if LProgress <> ppNotComplete then
          Break;
      end;
      FLines.Add(Format('prod|%d|%d|%d|%s|steps=%d|res=%d|spent=%d|produced=%d|funds=%d|crafts=%d|%s', [AVariant,
        ABaseIndex, LIndex, LProduction.Rules.Name, LSteps, Ord(LProgress), LProduction.TimeSpent,
        LProduction.AmountProduced, AGame.Funds, ABase.Crafts.Count, TXcomSim.StorageText(ABase.StorageItems)]));
    end;
  finally
    LStepper.Free;
  end;
end;

procedure TTestXcomProductionStepper.DovrebbeFareLeStesseProduzioniDelVeroOpenXcom;
var
  LFolder: string;
  LVariant, LBase: Integer;
  LGame: TXcomSavedGame;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if not FSim.Available or (LFolder = '') then
  begin
    Assert.Pass('senza i dati di TFTD o i golden il confronto non si fa');
    Exit;
  end;
  FLines := TStringList.Create;
  try
    for LVariant := 0 to 15 do
    begin
      FLines.Clear;
      FRandom := TXcomRandom.Create(1);
      LGame := FSim.LoadSave(LVariant, FRandom);
      try
        FRandom.SetSeed(5000 + LVariant);
        LGame.SetFunds(1000000 + Pick(3000000));
        for LBase := 0 to LGame.Bases.Count - 1 do
          RunBase(LGame, LGame.Bases[LBase], LVariant, LBase);
        FLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        Assert.AreEqual('', TXcomSim.FirstDifference(string(TXcomSim.GoldenText(LFolder +
          Format('sim%.2d.production.txt', [LVariant]))), FLines.Text), Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.SaveDifference(TXcomSim.GoldenText(LFolder + Format('sim%.2d.production.sav',
          [LVariant])), FSim.SaveText(LGame, FRandom)), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LGame.Free;
      end;
    end;
  finally
    FLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomProductionStepper);

end.
