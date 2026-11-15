{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - the decl_show variable       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.ShowCVar;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Console.CVar.Intf,
  DelphiDoom.Console.CVar.System, DelphiDoom.Console.CVar.Variable, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Intf,
  DelphiDoom.Decl.Source.Memory, DelphiDoom.Decl.Console.ShowCVar, DelphiDoom.Decl.Factory,
  DelphiDoom.Decl.Types, DelphiDoom.Tests.Scanner.IdFakes;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclShowCVar = class
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IDeclSource;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FManager: IDeclManager;
    FCVars: ICVarSystem;
    FShow: TDeclShowCVar;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRegistrareLaVariabileConIlDefaultZeroEIlIntervallo;
    [Test]
    procedure SynchronizeDovrebbeDareIlLivelloAlGestore;
    [Test]
    procedure SynchronizeSenzaModificheNonDovrebbeToccareIlGestore;
    [Test]
    procedure DovrebbeRifiutareArgomentiNulli;
  end;

implementation

procedure TTestDeclShowCVar.Setup;
begin
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
  FSource.Add('def/a.def', 'entityDef monster_a { "health" "100" }' + #10);
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
  FManager := TDeclFactory.CreateStandardManager(FSourceIntf, FLog);
  FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
  FCVars := TCVarSystem.Create(FLog);
  FShow := TDeclShowCVar.Create(FManager, FCVars);
  FShow.Register;
end;

procedure TTestDeclShowCVar.TearDown;
begin
  FShow.Free;
  FCVars := nil;
  FManager := nil;
  FLog := nil;
  FLogObject := nil;
  FSourceIntf := nil;
  FSource := nil;
end;

procedure TTestDeclShowCVar.DovrebbeRegistrareLaVariabileConIlDefaultZeroEIlIntervallo;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Find('decl_show');
  Assert.IsNotNull(LVariable);
  Assert.AreEqual(0, LVariable.GetInteger);
  Assert.AreEqual('set to 1 to print parses, 2 to also print references', string(LVariable.Description));
  Assert.AreEqual(0.0, Double(LVariable.ValueMin), 1E-6);
  Assert.AreEqual(2.0, Double(LVariable.ValueMax), 1E-6);
end;

procedure TTestDeclShowCVar.SynchronizeDovrebbeDareIlLivelloAlGestore;
begin
  FManager.FindType(DECL_ENTITYDEF, 'monster_a');
  FLogObject.Lines.Clear;
  // level 0: nothing is printed
  FManager.FindType(DECL_ENTITYDEF, 'monster_a');
  Assert.AreEqual(0, FLogObject.Lines.Count);
  // level 2 prints the references
  FCVars.SetCVarInteger('decl_show', 2);
  FShow.Synchronize;
  FManager.FindType(DECL_ENTITYDEF, 'monster_a');
  Assert.IsTrue(FLogObject.Lines.Text.Contains('referencing entityDef monster_a'), FLogObject.Lines.Text);
end;

procedure TTestDeclShowCVar.SynchronizeSenzaModificheNonDovrebbeToccareIlGestore;
begin
  FCVars.SetCVarInteger('decl_show', 2);
  FShow.Synchronize;
  FManager.SetShowLevel(0);
  // the variable is not modified since the last call: the manager keeps the level it has
  FShow.Synchronize;
  FLogObject.Lines.Clear;
  FManager.FindType(DECL_ENTITYDEF, 'monster_a');
  FManager.FindType(DECL_ENTITYDEF, 'monster_a');
  Assert.IsFalse(FLogObject.Lines.Text.Contains('referencing'));
end;

procedure TTestDeclShowCVar.DovrebbeRifiutareArgomentiNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TDeclShowCVar.Create(nil, FCVars);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TDeclShowCVar.Create(FManager, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclShowCVar);

end.