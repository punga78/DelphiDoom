{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptEntityTable  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Entities;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.Tests.DoomScript.Support, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.ScriptObject,
  DelphiDoom.DoomScript.Entities, DelphiDoom.DoomScript.Machine, DelphiDoom.DoomScript.Factory;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptEntities = class
  private
    FHost: TDoomScriptFakeHost;
    FHostIntf: IDoomScriptHost;
    FLogIntf: IIdLibLog;
    FFiles: TIdLibMemoryFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FMachine: TDoomScriptMachine;
    FEntities: TDoomScriptEntityTable;
    FFirst: TDoomScriptEventTarget;
    FSecond: TDoomScriptEventTarget;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRegistrareUnEntita;
    [Test]
    procedure DovrebbeRifiutareUnNumeroFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnNumeroOccupato;
    [Test]
    procedure DovrebbeRifiutareUnEntitaSenzaTarget;
    [Test]
    procedure DovrebbeRimuovereUnEntita;
    [Test]
    procedure DovrebbeRispondereNienteFuoriIntervallo;
    [Test]
    procedure DovrebbeTrovareLEntitaDalValoreDelloScript;
    [Test]
    procedure DovrebbeDareLOggettoDiScriptSoloSeHaDati;
    [Test]
    procedure DovrebbeTrovareIlNumeroDiUnTarget;
    [Test]
    procedure DovrebbeLiberareGliOggettiDeiTipiCheSpariscono;
    [Test]
    procedure DovrebbeLiberareGliOggettiQuandoIlProgrammaRiparte;
  end;

implementation

procedure TTestDoomScriptEntities.Setup;
begin
  FHost := TDoomScriptFakeHost.Create;
  FHostIntf := FHost;
  FLogIntf := TIdLibLogRecorder.Create;
  FFiles := TIdLibMemoryFileSystem.Create;
  FFilesIntf := FFiles;
  FFiles.SetFile('script/doom_defs.script', '// nothing'#10);
  FMachine := TDoomScriptFactory.CreateMachine(FHostIntf, nil, FLogIntf, FFilesIntf);
  FMachine.ScriptProgram.BeginCompilation;
  FMachine.ScriptProgram.CompileText('first.script', 'object first_type { float x; };'#10, False);
  FMachine.ScriptProgram.FinishCompilation;
  FEntities := FMachine.Entities;
  FFirst := TDoomScriptEventTarget.Create(FMachine.Classes.GetClass('idClass'));
  FSecond := TDoomScriptEventTarget.Create(FMachine.Classes.GetClass('idClass'));
end;

procedure TTestDoomScriptEntities.TearDown;
begin
  FMachine.Free;
  FSecond.Free;
  FFirst.Free;
  FFilesIntf := nil;
  FLogIntf := nil;
  FHostIntf := nil;
end;

procedure TTestDoomScriptEntities.DovrebbeRegistrareUnEntita;
begin
  Assert.IsFalse(FEntities.Exists(5));
  FEntities.Add(5, FFirst, 'five');
  Assert.IsTrue(FEntities.Exists(5));
  Assert.AreSame(FFirst, FEntities.TargetOf(5));
  Assert.AreEqual('five', string(FEntities.NameOf(5)));
  Assert.IsNotNull(FEntities.ObjectOf(5));
  Assert.IsFalse(FEntities.ObjectOf(5).HasObject);
  // the limits of the table
  FEntities.Add(0, FSecond, 'zero');
  FEntities.Add(DS_MAX_GENTITIES - 1, FSecond, 'last');
  Assert.IsTrue(FEntities.Exists(0));
  Assert.IsTrue(FEntities.Exists(DS_MAX_GENTITIES - 1));
end;

procedure TTestDoomScriptEntities.DovrebbeRifiutareUnNumeroFuoriIntervallo;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FEntities.Add(-1, FFirst, 'x');
    end, EDoomScriptError, 'TDoomScriptEntityTable: entity number -1 out of range');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FEntities.Add(DS_MAX_GENTITIES, FFirst, 'x');
    end, EDoomScriptError, 'TDoomScriptEntityTable: entity number 4096 out of range');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FEntities.Remove(DS_MAX_GENTITIES);
    end, EDoomScriptError, 'TDoomScriptEntityTable: entity number 4096 out of range');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FEntities.Remove(-1);
    end, EDoomScriptError, 'TDoomScriptEntityTable: entity number -1 out of range');
end;

procedure TTestDoomScriptEntities.DovrebbeRifiutareUnNumeroOccupato;
begin
  FEntities.Add(5, FFirst, 'five');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FEntities.Add(5, FSecond, 'again');
    end, EDoomScriptError, 'TDoomScriptEntityTable: entity number 5 is already in use');
  Assert.AreSame(FFirst, FEntities.TargetOf(5));
  Assert.AreEqual('five', string(FEntities.NameOf(5)));
end;

procedure TTestDoomScriptEntities.DovrebbeRifiutareUnEntitaSenzaTarget;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FEntities.Add(5, nil, 'x');
    end, EDoomScriptError, 'TDoomScriptEntityTable: an entity needs a target');
  Assert.IsFalse(FEntities.Exists(5));
end;

procedure TTestDoomScriptEntities.DovrebbeRimuovereUnEntita;
begin
  FEntities.Add(5, FFirst, 'five');
  FEntities.ObjectOf(5).SetType('first_type');
  FEntities.Remove(5);
  Assert.IsFalse(FEntities.Exists(5));
  Assert.IsNull(FEntities.TargetOf(5));
  Assert.AreEqual('', string(FEntities.NameOf(5)));
  Assert.IsNull(FEntities.ObjectOf(5));
  Assert.IsNull(FEntities.GetScriptObject(6));
  // a free number is removed without an error, and can be taken again
  FEntities.Remove(5);
  FEntities.Add(5, FSecond, 'new');
  Assert.AreSame(FSecond, FEntities.TargetOf(5));
  Assert.IsFalse(FEntities.ObjectOf(5).HasObject);
end;

procedure TTestDoomScriptEntities.DovrebbeRispondereNienteFuoriIntervallo;
begin
  Assert.IsFalse(FEntities.Exists(-1));
  Assert.IsFalse(FEntities.Exists(DS_MAX_GENTITIES));
  Assert.IsNull(FEntities.TargetOf(-1));
  Assert.IsNull(FEntities.TargetOf(DS_MAX_GENTITIES));
  Assert.AreEqual('', string(FEntities.NameOf(-1)));
  Assert.AreEqual('', string(FEntities.NameOf(DS_MAX_GENTITIES)));
  Assert.IsNull(FEntities.ObjectOf(-1));
  Assert.IsNull(FEntities.ObjectOf(DS_MAX_GENTITIES));
end;

procedure TTestDoomScriptEntities.DovrebbeTrovareLEntitaDalValoreDelloScript;
begin
  FEntities.Add(0, FFirst, 'zero');
  FEntities.Add(DS_MAX_GENTITIES - 1, FSecond, 'last');
  // a script holds the handle plus one; zero is no entity
  Assert.IsNull(FEntities.GetEntity(0));
  Assert.AreSame(FFirst, FEntities.GetEntity(1));
  Assert.IsNull(FEntities.GetEntity(2));
  Assert.AreSame(FSecond, FEntities.GetEntity(DS_MAX_GENTITIES));
  Assert.IsNull(FEntities.GetEntity(DS_MAX_GENTITIES + 1));
  Assert.IsNull(FEntities.GetEntity(-1));
  Assert.IsNull(FEntities.GetEntity(Low(Integer)));
  Assert.IsNull(FEntities.GetEntity(High(Integer)));
end;

procedure TTestDoomScriptEntities.DovrebbeDareLOggettoDiScriptSoloSeHaDati;
begin
  FEntities.Add(4, FFirst, 'four');
  Assert.IsNull(FEntities.GetScriptObject(5), 'no data yet');
  Assert.IsTrue(FEntities.ObjectOf(4).SetType('first_type'));
  Assert.AreSame(FEntities.ObjectOf(4), FEntities.GetScriptObject(5));
  Assert.IsNull(FEntities.GetScriptObject(4));
  Assert.IsNull(FEntities.GetScriptObject(0));
  Assert.IsNull(FEntities.GetScriptObject(-1));
  Assert.IsNull(FEntities.GetScriptObject(DS_MAX_GENTITIES + 1));
  Assert.IsNull(FEntities.GetScriptObject(DS_MAX_GENTITIES), 'no entity');
  FEntities.ObjectOf(4).FreeObject;
  Assert.IsNull(FEntities.GetScriptObject(5));
end;

procedure TTestDoomScriptEntities.DovrebbeTrovareIlNumeroDiUnTarget;
begin
  FEntities.Add(9, FFirst, 'nine');
  Assert.AreEqual(9, FEntities.NumberOf(FFirst));
  Assert.AreEqual(-1, FEntities.NumberOf(FSecond));
  Assert.AreEqual(-1, FEntities.NumberOf(nil));
  FEntities.Add(3, FSecond, 'three');
  Assert.AreEqual(3, FEntities.NumberOf(FSecond));
end;

procedure TTestDoomScriptEntities.DovrebbeLiberareGliOggettiDeiTipiCheSpariscono;
var
  LTypes: Integer;
begin
  LTypes := FMachine.ScriptProgram.NumTypes;
  FMachine.ScriptProgram.CompileText('second.script', 'object second_type { float y; vector v; };'#10, False);
  FEntities.Add(1, FFirst, 'old type');
  FEntities.Add(2, FSecond, 'new type');
  FEntities.Add(3, FSecond, 'no object');
  Assert.IsTrue(FEntities.ObjectOf(1).SetType('first_type'));
  Assert.IsTrue(FEntities.ObjectOf(2).SetType('second_type'));
  // all the types stay: nothing changes
  FEntities.ReleaseObjects(FMachine.ScriptProgram.NumTypes);
  Assert.IsTrue(FEntities.ObjectOf(2).HasObject);
  // only the types that were there before the second compilation stay
  FEntities.ReleaseObjects(LTypes);
  Assert.IsTrue(FEntities.ObjectOf(1).HasObject);
  Assert.IsFalse(FEntities.ObjectOf(2).HasObject);
  Assert.IsFalse(FEntities.ObjectOf(2).HasData);
  Assert.IsFalse(FEntities.ObjectOf(3).HasObject);
  // no type stays
  FEntities.ReleaseObjects(0);
  Assert.IsFalse(FEntities.ObjectOf(1).HasObject);
end;

procedure TTestDoomScriptEntities.DovrebbeLiberareGliOggettiQuandoIlProgrammaRiparte;
begin
  FMachine.ScriptProgram.CompileText('second.script', 'object second_type { float y; vector v; };'#10, False);
  FEntities.Add(1, FFirst, 'old type');
  FEntities.Add(2, FSecond, 'new type');
  FEntities.ObjectOf(1).SetType('first_type');
  FEntities.ObjectOf(2).SetType('second_type');
  // the restart drops what was compiled after FinishCompilation: the object of that type goes with it
  FMachine.ScriptProgram.Restart;
  Assert.IsTrue(FEntities.ObjectOf(1).HasObject);
  Assert.IsFalse(FEntities.ObjectOf(2).HasObject);
  Assert.AreEqual('object', string(FEntities.ObjectOf(2).GetTypeName));
  // a new compilation from scratch frees every type
  FMachine.ScriptProgram.BeginCompilation;
  Assert.IsFalse(FEntities.ObjectOf(1).HasObject);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptEntities);

end.
