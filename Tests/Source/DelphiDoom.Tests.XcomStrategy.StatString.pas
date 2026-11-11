{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the stat string of a  }
{  soldier on random stats, against StatString::calcStatString of the real     }
{  OpenXcom objects (simgen statstring)                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.StatString;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.UnitStats,
  DelphiDoom.XcomMod.StatString, DelphiDoom.XcomMod.StatStringCalculator, DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomStatStringCalculator = class(TObject)
  strict private
    FRandom: IXcomRandom;
    function Pick(AValue: Integer): Integer;
    function Strings: TObjectList<TXcomStatString>;
  public
    [Test]
    procedure DovrebbeDareLeStesseStringheDelVeroOpenXcom;
    [Test]
    procedure DovrebbeDareStringaVuotaSenzaRegole;
    [Test]
    procedure DovrebbeTrattareUnaCondizioneSuPsiTrainingComeNonSoddisfattaSeNonInAddestramento;
  end;

implementation

const
  STAT_STRINGS_YAML =
    '- {string: "P", psiStrength: [60, 100], psiSkill: [1, 100]}' + #10 +
    '- {string: "!", psiTraining: [1, 1]}' + #10 +
    '- {string: "+", tu: [70, 100], strength: [40, 100]}' + #10 +
    '- {string: "--", health: [0, 25], bravery: [0, 30]}' + #10 +
    '- {string: "-", reactions: [0, 20]}' + #10 +
    '- {string: "b", bravery: [60, 100]}' + #10 +
    '- {string: "s", stamina: [70, 100]}' + #10 +
    '- {string: "f", firing: [70, 100], throwing: [50, 100]}' + #10 +
    '- {string: "m", melee: [80, 100]}' + #10 +
    '- {string: "x", psiSkill: [1, 100]}' + #10 +
    '- {string: "ab", tu: [0, 100]}';

{ TTestXcomStatStringCalculator }

function TTestXcomStatStringCalculator.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

function TTestXcomStatStringCalculator.Strings: TObjectList<TXcomStatString>;
var
  LDocument, LItem: IYamlNode;
  LString: TXcomStatString;
begin
  Result := TObjectList<TXcomStatString>.Create(True);
  LDocument := TYamlFactory.CreateParser.LoadAll(YamlStringToText(STAT_STRINGS_YAML))[0];
  for LItem in LDocument.Items do
  begin
    LString := TXcomStatString.Create;
    Result.Add(LString);
    LString.Load(LItem);
  end;
end;

procedure TTestXcomStatStringCalculator.DovrebbeDareLeStesseStringheDelVeroOpenXcom;
var
  LFolder: string;
  LVariant, LIndex: Integer;
  LStrings: TObjectList<TXcomStatString>;
  LStats: TXcomUnitStats;
  LEval, LTraining: Boolean;
  LLines: TStringList;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if LFolder = '' then
  begin
    Assert.Pass('senza i golden il confronto non si fa');
    Exit;
  end;
  LStrings := Strings;
  LLines := TStringList.Create;
  try
    for LVariant := 0 to 15 do
    begin
      LLines.Clear;
      FRandom := TXcomRandom.Create(5000 + LVariant);
      LLines.Add(Format('count|%d|%d', [LVariant, LStrings.Count]));
      for LIndex := 0 to 149 do
      begin
        LStats.TimeUnits := Pick(90);
        LStats.Stamina := Pick(90);
        LStats.Health := Pick(60);
        LStats.Bravery := Pick(10) * 10;
        LStats.Reactions := Pick(80);
        LStats.Firing := Pick(90);
        LStats.Throwing := Pick(90);
        LStats.Strength := Pick(60);
        LStats.PsiStrength := Pick(100);
        if Pick(3) = 0 then
          LStats.PsiSkill := 0
        else
          LStats.PsiSkill := Pick(70);
        LStats.Melee := Pick(90);
        LEval := Pick(2) = 0;
        LTraining := Pick(3) = 0;
        LLines.Add(Format('stat|%d|%d|%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d|%d|%d|%s', [LVariant, LIndex, LStats.TimeUnits,
          LStats.Stamina, LStats.Health, LStats.Bravery, LStats.Reactions, LStats.Firing, LStats.Throwing,
          LStats.Strength, LStats.PsiStrength, LStats.PsiSkill, LStats.Melee, Ord(LEval), Ord(LTraining),
          TXcomStatStringCalculator.Calculate(LStats, LStrings, LEval, LTraining)]));
      end;
      LLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
      Assert.AreEqual('', TXcomSim.FirstDifference(string(TXcomSim.GoldenText(LFolder +
        Format('sim%.2d.statstring.txt', [LVariant]))), LLines.Text), Format('salvataggio %d', [LVariant]));
    end;
  finally
    LLines.Free;
    LStrings.Free;
  end;
end;

procedure TTestXcomStatStringCalculator.DovrebbeDareStringaVuotaSenzaRegole;
var
  LStrings: TObjectList<TXcomStatString>;
  LStats: TXcomUnitStats;
begin
  LStrings := TObjectList<TXcomStatString>.Create(True);
  try
    FillChar(LStats, SizeOf(LStats), 0);
    Assert.AreEqual('', TXcomStatStringCalculator.Calculate(LStats, LStrings, True, True));
  finally
    LStrings.Free;
  end;
end;

procedure TTestXcomStatStringCalculator.DovrebbeTrattareUnaCondizioneSuPsiTrainingComeNonSoddisfattaSeNonInAddestramento;
var
  LStrings: TObjectList<TXcomStatString>;
  LStats: TXcomUnitStats;
begin
  LStrings := Strings;
  try
    FillChar(LStats, SizeOf(LStats), 0);
    // the second string of the rules needs psiTraining; these stats meet only the last one (tu between 0 and 100)
    LStats.TimeUnits := 50;
    LStats.Stamina := 50;
    LStats.Health := 40;
    LStats.Bravery := 40;
    LStats.Reactions := 50;
    LStats.Firing := 50;
    Assert.AreEqual('ab', TXcomStatStringCalculator.Calculate(LStats, LStrings, False, False), 'senza addestramento');
    Assert.AreEqual('!ab', TXcomStatStringCalculator.Calculate(LStats, LStrings, False, True), 'in addestramento');
  finally
    LStrings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomStatStringCalculator);

end.
