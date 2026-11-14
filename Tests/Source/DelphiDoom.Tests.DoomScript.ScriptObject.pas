{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptObject       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.ScriptObject;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.Tests.DoomScript.Support,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.ScriptObject, DelphiDoom.DoomScript.SaveStream, DelphiDoom.DoomScript.Machine,
  DelphiDoom.DoomScript.Factory;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptObject = class
  private
    FHost: TDoomScriptFakeHost;
    FHostIntf: IDoomScriptHost;
    FLog: TIdLibLogRecorder;
    FLogIntf: IIdLibLog;
    FFiles: TIdLibMemoryFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FMachine: TDoomScriptMachine;
    FObject: TDoomScriptObject;
    FStream: TMemoryStream;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireSenzaTipo;
    [Test]
    procedure DovrebbeAllocareIDatiDelTipoEDeiSupertipi;
    [Test]
    procedure DovrebbeAvvisareSeIlTipoESconosciuto;
    [Test]
    procedure DovrebbeAvvisareSeIlTipoNonEUnOggetto;
    [Test]
    procedure DovrebbeNonAvereDatiPerUnTipoSenzaCampi;
    [Test]
    procedure DovrebbeAzzerareIDatiSenzaCambiareTipo;
    [Test]
    procedure DovrebbeAzzerareIDatiRidandoLoStessoTipo;
    [Test]
    procedure DovrebbeTrovareICampiPerNomeETipo;
    [Test]
    procedure DovrebbeNonTrovareUnCampoColTipoSbagliatoOSenzaOggetto;
    [Test]
    procedure DovrebbeRifiutareUnAccessoFuoriDaiDati;
    [Test]
    procedure DovrebbeTrovareCostruttoreDistruttoreEMetodi;
    [Test]
    procedure DovrebbeSalvareERipristinareIDati;
    [Test]
    procedure DovrebbeSalvareUnaStringaVuotaSenzaOggetto;
    [Test]
    procedure DovrebbeRifiutareUnTipoSalvatoSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneSalvataDiversa;
    [Test]
    procedure DovrebbeLiberareIDati;
  end;

implementation

const
  SCRIPT: AnsiString =
    'object a { float x; vector v; string s; };'#10 +
    'object b : a { entity e; float y; void init(); void destroy(); void walk(); };'#10 +
    'void b::init() {}'#10 +
    'void b::destroy() {}'#10 +
    'void b::walk() {}'#10 +
    'object empty { void foo(); };'#10 +
    'void empty::foo() {}'#10;
  // a: float 4 + vector 12 + string 128
  SIZE_A = 4 + 12 + DS_MAX_STRING_LEN;
  // b: a + entity 4 + float 4
  SIZE_B = SIZE_A + 8;

procedure TTestDoomScriptObject.Setup;
begin
  FHost := TDoomScriptFakeHost.Create;
  FHostIntf := FHost;
  FLog := TIdLibLogRecorder.Create;
  FLogIntf := FLog;
  FFiles := TIdLibMemoryFileSystem.Create;
  FFilesIntf := FFiles;
  FFiles.SetFile('script/doom_defs.script', '// nothing'#10);
  FMachine := TDoomScriptFactory.CreateMachine(FHostIntf, nil, FLogIntf, FFilesIntf);
  FMachine.ScriptProgram.BeginCompilation;
  FMachine.ScriptProgram.CompileText('objects.script', SCRIPT, False);
  FMachine.ScriptProgram.FinishCompilation;
  FObject := TDoomScriptObject.Create(FMachine.ScriptProgram);
  FStream := TMemoryStream.Create;
  FLog.Entries.Clear;
end;

procedure TTestDoomScriptObject.TearDown;
begin
  FStream.Free;
  FObject.Free;
  FMachine.Free;
  FFilesIntf := nil;
  FLogIntf := nil;
  FHostIntf := nil;
end;

procedure TTestDoomScriptObject.DovrebbePartireSenzaTipo;
begin
  Assert.IsFalse(FObject.HasObject);
  Assert.IsFalse(FObject.HasData);
  Assert.AreEqual(0, FObject.DataSize);
  Assert.AreEqual('object', string(FObject.GetTypeName));
  Assert.AreSame(FMachine.ScriptProgram.TypeObject, FObject.GetTypeDef);
  // nothing to clear
  FObject.ClearObject;
  Assert.IsFalse(FObject.HasObject);
end;

procedure TTestDoomScriptObject.DovrebbeAllocareIDatiDelTipoEDeiSupertipi;
var
  LIndex: Integer;
begin
  Assert.IsTrue(FObject.SetType('a'));
  Assert.IsTrue(FObject.HasObject);
  Assert.IsTrue(FObject.HasData);
  Assert.AreEqual(SIZE_A, FObject.DataSize);
  Assert.AreEqual('a', string(FObject.GetTypeName));
  Assert.IsTrue(FObject.SetType('b'));
  Assert.AreEqual(SIZE_B, FObject.DataSize);
  Assert.AreEqual('b', string(FObject.GetTypeName));
  Assert.AreSame(FMachine.ScriptProgram.FindType('b'), FObject.GetTypeDef);
  for LIndex := 0 to SIZE_B - 1 do
    Assert.AreEqual(0, Integer(FObject.DataPtr(LIndex, 1)^), Format('byte %d', [LIndex]));
  Assert.AreEqual(0, FLog.Entries.Count, FLog.Entries.Text);
end;

procedure TTestDoomScriptObject.DovrebbeAvvisareSeIlTipoESconosciuto;
begin
  FObject.SetType('a');
  Assert.IsFalse(FObject.SetType('nope'));
  Assert.IsTrue(FLog.Entries.IndexOf('W:idScriptObject::SetType: Unknown type ''nope''') >= 0, FLog.Entries.Text);
  // the object it had is gone
  Assert.IsFalse(FObject.HasObject);
  Assert.AreEqual(0, FObject.DataSize);
end;

procedure TTestDoomScriptObject.DovrebbeAvvisareSeIlTipoNonEUnOggetto;
begin
  // the type of the function "walk" is found by its name, but is not an object type
  Assert.IsFalse(FObject.SetType('walk'));
  Assert.IsTrue(FLog.Entries.IndexOf(
    'W:idScriptObject::SetType: Can''t create object of type ''walk''.  Must be an object type.') >= 0,
    FLog.Entries.Text);
  Assert.IsFalse(FObject.HasObject);
end;

procedure TTestDoomScriptObject.DovrebbeNonAvereDatiPerUnTipoSenzaCampi;
begin
  // Mem_Alloc( 0 ) of the original gives NULL: the object has a type but the interpreter sees no object
  Assert.IsTrue(FObject.SetType('empty'));
  Assert.IsTrue(FObject.HasObject);
  Assert.IsFalse(FObject.HasData);
  Assert.AreEqual(0, FObject.DataSize);
  Assert.AreEqual('empty', string(FObject.GetTypeName));
  Assert.IsNotNull(FObject.GetFunction('foo'));
  FObject.ClearObject;
  Assert.IsTrue(FObject.HasObject);
end;

procedure TTestDoomScriptObject.DovrebbeAzzerareIDatiSenzaCambiareTipo;
begin
  FObject.SetType('b');
  FObject.DataPtr(0, 1)^ := 1;
  FObject.DataPtr(SIZE_B - 1, 1)^ := 2;
  FObject.ClearObject;
  Assert.AreEqual(0, Integer(FObject.DataPtr(0, 1)^));
  Assert.AreEqual(0, Integer(FObject.DataPtr(SIZE_B - 1, 1)^));
  Assert.AreEqual('b', string(FObject.GetTypeName));
end;

procedure TTestDoomScriptObject.DovrebbeAzzerareIDatiRidandoLoStessoTipo;
begin
  FObject.SetType('b');
  FObject.DataPtr(10, 1)^ := 99;
  Assert.IsTrue(FObject.SetType('b'));
  Assert.AreEqual(0, Integer(FObject.DataPtr(10, 1)^));
  Assert.AreEqual(SIZE_B, FObject.DataSize);
end;

procedure TTestDoomScriptObject.DovrebbeTrovareICampiPerNomeETipo;
begin
  FObject.SetType('b');
  // the fields of the super type come first
  Assert.AreEqual(0, FObject.GetVariable('x', evFloat));
  Assert.AreEqual(4, FObject.GetVariable('v', evVector));
  Assert.AreEqual(16, FObject.GetVariable('s', evString));
  Assert.AreEqual(SIZE_A, FObject.GetVariable('e', evEntity));
  Assert.AreEqual(SIZE_A + 4, FObject.GetVariable('y', evFloat));
  FObject.SetType('a');
  Assert.AreEqual(16, FObject.GetVariable('s', evString));
  // a field of the derived type is not in the base type
  Assert.AreEqual(-1, FObject.GetVariable('y', evFloat));
end;

procedure TTestDoomScriptObject.DovrebbeNonTrovareUnCampoColTipoSbagliatoOSenzaOggetto;
begin
  Assert.AreEqual(-1, FObject.GetVariable('x', evFloat), 'no object');
  FObject.SetType('b');
  Assert.AreEqual(-1, FObject.GetVariable('y', evString), 'wrong kind');
  Assert.AreEqual(-1, FObject.GetVariable('x', evVector), 'wrong kind in the super type');
  Assert.AreEqual(-1, FObject.GetVariable('zz', evFloat), 'unknown');
  // the names are case sensitive
  Assert.AreEqual(-1, FObject.GetVariable('X', evFloat), 'case');
end;

procedure TTestDoomScriptObject.DovrebbeRifiutareUnAccessoFuoriDaiDati;
begin
  FObject.SetType('b');
  Assert.IsNotNull(FObject.DataPtr(SIZE_B - 4, 4));
  // the end itself, for no bytes
  Assert.IsNotNull(FObject.DataPtr(SIZE_B - 1, 0));
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FObject.DataPtr(SIZE_B - 2, 4);
    end, EDoomScriptMemoryError,
    Format('idScriptObject: access to 4 bytes at %d is outside the object ''b'' (%d bytes)', [SIZE_B - 2, SIZE_B]));
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      FObject.DataPtr(-1, 1);
    end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      FObject.DataPtr(0, -1);
    end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      FObject.DataPtr(High(Integer), 4);
    end, EDoomScriptMemoryError);
  FObject.FreeObject;
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      FObject.DataPtr(0, 1);
    end, EDoomScriptMemoryError);
end;

procedure TTestDoomScriptObject.DovrebbeTrovareCostruttoreDistruttoreEMetodi;
var
  LFunction: TDoomScriptFunction;
begin
  Assert.IsNull(FObject.GetConstructor, 'no object');
  Assert.IsNull(FObject.GetDestructor, 'no object');
  Assert.IsNull(FObject.GetFunction('walk'), 'no object');
  FObject.SetType('b');
  LFunction := FObject.GetConstructor;
  Assert.IsNotNull(LFunction);
  Assert.AreEqual('b::init', string(LFunction.Name));
  LFunction := FObject.GetDestructor;
  Assert.IsNotNull(LFunction);
  Assert.AreEqual('b::destroy', string(LFunction.Name));
  Assert.AreEqual('b::walk', string(FObject.GetFunction('walk').Name));
  Assert.IsNull(FObject.GetFunction('nothing'));
  // the base type has none of them
  FObject.SetType('a');
  Assert.IsNull(FObject.GetConstructor);
  Assert.IsNull(FObject.GetDestructor);
  Assert.IsNull(FObject.GetFunction('walk'));
end;

procedure TTestDoomScriptObject.DovrebbeSalvareERipristinareIDati;
var
  LOther: TDoomScriptObject;
  LIndex: Integer;
begin
  FObject.SetType('b');
  for LIndex := 0 to SIZE_B - 1 do
    FObject.DataPtr(LIndex, 1)^ := Byte(LIndex * 7 + 1);
  FObject.Save(FStream);
  // the name, the size and the bytes
  Assert.AreEqual<Int64>(4 + 1 + 4 + SIZE_B, FStream.Size);
  FStream.Position := 0;
  LOther := TDoomScriptObject.Create(FMachine.ScriptProgram);
  try
    LOther.Restore(FStream);
    Assert.AreEqual('b', string(LOther.GetTypeName));
    Assert.AreEqual(SIZE_B, LOther.DataSize);
    for LIndex := 0 to SIZE_B - 1 do
      Assert.AreEqual(Integer(Byte(LIndex * 7 + 1)), Integer(LOther.DataPtr(LIndex, 1)^), Format('byte %d', [LIndex]));
    Assert.AreEqual<Int64>(FStream.Size, FStream.Position);
  finally
    LOther.Free;
  end;
end;

procedure TTestDoomScriptObject.DovrebbeSalvareUnaStringaVuotaSenzaOggetto;
var
  LOther: TDoomScriptObject;
begin
  FObject.Save(FStream);
  Assert.AreEqual<Int64>(4, FStream.Size);
  FStream.Position := 0;
  LOther := TDoomScriptObject.Create(FMachine.ScriptProgram);
  try
    // as in the original, an object that already has a type keeps it
    LOther.SetType('a');
    LOther.Restore(FStream);
    Assert.AreEqual('a', string(LOther.GetTypeName));
  finally
    LOther.Free;
  end;
end;

procedure TTestDoomScriptObject.DovrebbeRifiutareUnTipoSalvatoSconosciuto;
begin
  TDoomScriptSaveStream.WriteString(FStream, 'zzz');
  TDoomScriptSaveStream.WriteInt(FStream, 4);
  FStream.Position := 0;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FObject.Restore(FStream);
    end, EDoomScriptError, 'idScriptObject::Restore: failed to restore object of type ''zzz''.');
  Assert.IsFalse(FObject.HasObject);
end;

procedure TTestDoomScriptObject.DovrebbeRifiutareUnaDimensioneSalvataDiversa;
begin
  TDoomScriptSaveStream.WriteString(FStream, 'b');
  TDoomScriptSaveStream.WriteInt(FStream, 7);
  FStream.Position := 0;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FObject.Restore(FStream);
    end, EDoomScriptError, 'idScriptObject::Restore: size of object ''b'' doesn''t match size in save game.');
  // a stream that ends inside the data
  FStream.Clear;
  TDoomScriptSaveStream.WriteString(FStream, 'b');
  TDoomScriptSaveStream.WriteInt(FStream, SIZE_B);
  TDoomScriptSaveStream.WriteInt(FStream, 1);
  FStream.Position := 0;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FObject.Restore(FStream);
    end, EDoomScriptError, 'idRestoreGame: read past the end of the save data');
end;

procedure TTestDoomScriptObject.DovrebbeLiberareIDati;
begin
  FObject.SetType('b');
  FObject.FreeObject;
  Assert.IsFalse(FObject.HasObject);
  Assert.IsFalse(FObject.HasData);
  Assert.AreEqual(0, FObject.DataSize);
  Assert.AreEqual('object', string(FObject.GetTypeName));
  Assert.AreEqual(-1, FObject.GetVariable('x', evFloat));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptObject);

end.
