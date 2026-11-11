{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the constants of the generalized linedef types         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.ConstantsGeneralized;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.Tests.ScriptHost.ConstantFakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostConstantsGeneralized = class(TObject)
  private
    FTable: TRecordingConstantTable;
    FInterface: IScriptConstantTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareOttantunoCostanti;
    [Test]
    procedure DovrebbeDareTutteLeCostantiComeInteri;
    [Test]
    procedure DovrebbeDareNomiSenzaDoppioni;
    [Test]
    procedure DovrebbeDareLeCostantiNellOrdineDelVecchioCodice;
    [Test]
    [TestCase('DamageMask', 'DAMAGE_MASK,96')]
    [TestCase('SecretShift', 'SECRET_SHIFT,7')]
    [TestCase('CGenFloorBase', 'CGENFLOORBASE,24576')]
    [TestCase('CGenCrusherBase', 'CGENCRUSHERBASE,12160')]
    [TestCase('TriggerType', 'TriggerType,7')]
    [TestCase('GenFloorTarget', 'gen_FloorTarget,896')]
    [TestCase('CeilingSpeedShift', 'CeilingSpeedShift,3')]
    [TestCase('LiftDelay', 'LiftDelay,192')]
    [TestCase('StairStep', 'StairStep,192')]
    [TestCase('CrusherSilent', 'CrusherSilent,64')]
    [TestCase('DoorKind', 'DoorKind,96')]
    [TestCase('LockedKey', 'LockedKey,448')]
    procedure DovrebbeDareIlValoreNoto(const AName: string; const AValue: Integer);
    [Test]
    procedure DovrebbeDireQuanteCostantiHa;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Constants.Generalized;

procedure TTestScriptHostConstantsGeneralized.Setup;
begin
  FTable := TRecordingConstantTable.Create;
  FInterface := FTable;
  TScriptGeneralizedConstants.Create.Describe(FInterface);
end;

procedure TTestScriptHostConstantsGeneralized.TearDown;
begin
  FInterface := nil;
  FTable := nil;
end;

procedure TTestScriptHostConstantsGeneralized.DovrebbeDareOttantunoCostanti;
begin
  Assert.AreEqual(81, FTable.Entries.Count);
end;

procedure TTestScriptHostConstantsGeneralized.DovrebbeDareTutteLeCostantiComeInteri;
var
  LEntry: string;
begin
  for LEntry in FTable.Entries do
    Assert.IsTrue(LEntry.Contains(':integer='), LEntry);
end;

procedure TTestScriptHostConstantsGeneralized.DovrebbeDareNomiSenzaDoppioni;
var
  LEntry: string;
  LNames: TDictionary<string, Boolean>;
begin
  LNames := TDictionary<string, Boolean>.Create;
  try
    for LEntry in FTable.Entries do
      // the compiler does not tell the upper case from the lower case
      Assert.IsTrue(LNames.TryAdd(UpperCase(Copy(LEntry, 1, Pos(':', LEntry) - 1)), True), LEntry);
  finally
    LNames.Free;
  end;
end;

procedure TTestScriptHostConstantsGeneralized.DovrebbeDareLeCostantiNellOrdineDelVecchioCodice;
begin
  Assert.AreEqual('DAMAGE_MASK:integer=96', FTable.Entries[0]);
  Assert.AreEqual('PUSH_SHIFT:integer=9', FTable.Entries[7]);
  Assert.IsTrue(FTable.Entries[8].StartsWith('CGENFLOORBASE:'));
  Assert.IsTrue(FTable.Entries[FTable.Entries.Count - 1].StartsWith('LockedSpeedShift:'));
end;

procedure TTestScriptHostConstantsGeneralized.DovrebbeDareIlValoreNoto(const AName: string;
  const AValue: Integer);
var
  LEntry: string;
begin
  for LEntry in FTable.Entries do
    if LEntry = Format('%s:integer=%d', [AName, AValue]) then
      Exit;
  Assert.Fail(Format('%s=%d not found', [AName, AValue]));
end;

procedure TTestScriptHostConstantsGeneralized.DovrebbeDireQuanteCostantiHa;
begin
  Assert.AreEqual(81, TScriptGeneralizedConstants.Count);
end;

end.
