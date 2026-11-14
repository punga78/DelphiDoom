{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptProgram      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.ScriptProgram;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.Tests.DoomScript.Rig;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptProgram = class
  strict private
    FRig: TDoomScriptTestRig;
    FProgram: TDoomScriptProgram;
    function SavedProgram: TBytes;
    procedure ExpectRestoreError(const AData: TBytes; const AClass: ExceptClass);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAllocareUnaVariabileGlobaleInCodaAlleAltre;
    [Test]
    procedure DovrebbeAllocareLeTreComponentiDiUnVettore;
    [Test]
    procedure DovrebbeTrovareUnDefPerNomeEScope;
    [Test]
    procedure DovrebbeRifiutareLoStessoNomeConUnAltroTipo;
    [Test]
    procedure DovrebbeLiberareUnVettoreConLeSueComponentiERinumerare;
    [Test]
    procedure DovrebbeTrovareUnaFunzioneAncheInUnNamespace;
    [Test]
    procedure DovrebbeNonDareComeFunzioneUnEventoOUnaVariabile;
    [Test]
    procedure DovrebbeTrovareLaFunzioneDiUnTipoOggettoODelSuoSuperTipo;
    [Test]
    procedure DovrebbeRifiutareGliIndiciFuoriDaiLimiti;
    [Test]
    procedure DovrebbeFermarsiAlLimiteDegliStatement;
    [Test]
    procedure DovrebbeFermarsiAlLimiteDelleFunzioni;
    [Test]
    procedure DovrebbeFermarsiAlLimiteDelleVariabiliGlobali;
    [Test]
    procedure DovrebbeDareLoStessoChecksumPerLoStessoProgramma;
    [Test]
    procedure DovrebbeSalvareERipristinareLeVariabiliCambiate;
    [Test]
    procedure DovrebbeDareFalsoSeIlChecksumSalvatoEDiverso;
    [Test]
    procedure DovrebbeDareErroreDedicatoPerUnSalvataggioTronco;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerUnIndiceDiVariabileFuoriIntervallo;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerUnNumeroDiVariabiliFuoriIntervallo;
    [Test]
    procedure DovrebbeTornareAlloStatoFinitoConRestart;
    [Test]
    procedure DovrebbeDareErroreSeSiUsaIlRitornoSenzaProgramma;
    [Test]
    procedure DovrebbeDareErroreSenzaCompilatore;
    [Test]
    procedure DovrebbeDareErroreSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeTenereIlNomeInteroDiUnFileFuoriDallaBase;
    [Test]
    procedure DovrebbeDisassemblareLeFunzioniENonGliEventi;
    [Test]
    procedure DovrebbeScrivereIlDisassemblatoSeLHostLoChiede;
    [Test]
    procedure DovrebbeStampareLeStatisticheConLeRigheDellOriginale;
    [Test]
    procedure DovrebbeStampareIlNomeCheLOriginaleLeggeDalSuoBuffer;
    [Test]
    procedure DovrebbeScrivereIlNumeroDiUnEntitaNellaSuaVariabile;
  end;

implementation

uses
  DelphiDoom.DoomScript.SaveStream, DelphiDoom.Tests.DoomScript.Support;

procedure TTestDoomScriptProgram.Setup;
begin
  FRig := TDoomScriptTestRig.Create;
  FProgram := FRig.Machine.ScriptProgram;
end;

procedure TTestDoomScriptProgram.TearDown;
begin
  FRig.Free;
end;

function TTestDoomScriptProgram.SavedProgram: TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    FProgram.Save(LStream);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptProgram.ExpectRestoreError(const AData: TBytes; const AClass: ExceptClass);
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create(AData);
  try
    TDoomScriptTestSupport.ExpectClass(
      procedure
      begin
        FProgram.Restore(LStream);
      end, AClass);
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptProgram.DovrebbeAllocareUnaVariabileGlobaleInCodaAlleAltre;
var
  LBefore: Integer;
  LDef: TDoomScriptVarDef;
begin
  LBefore := FProgram.NumVariables;
  LDef := FProgram.AllocDef(FProgram.BuiltinType(evFloat), 'one', FProgram.DefNamespace, False);
  Assert.AreEqual(LBefore, LDef.Value);
  Assert.AreEqual(LBefore + 4, FProgram.NumVariables);
  Assert.AreEqual(1, LDef.NumUsers);
  Assert.AreEqual(FProgram.NumDefs - 1, LDef.Num);
  LDef := FProgram.AllocDef(FProgram.BuiltinType(evString), 'text', FProgram.DefNamespace, False);
  Assert.AreEqual(LBefore + 4, LDef.Value);
  Assert.AreEqual(LBefore + 4 + DS_MAX_STRING_LEN, FProgram.NumVariables);
end;

procedure TTestDoomScriptProgram.DovrebbeAllocareLeTreComponentiDiUnVettore;
var
  LDef: TDoomScriptVarDef;
  LX: TDoomScriptVarDef;
  LZ: TDoomScriptVarDef;
begin
  LDef := FProgram.AllocDef(FProgram.BuiltinType(evVector), 'vec', FProgram.DefNamespace, False);
  LX := FProgram.GetDef(nil, 'vec_x', FProgram.DefNamespace);
  LZ := FProgram.GetDef(nil, 'vec_z', FProgram.DefNamespace);
  Assert.IsNotNull(LX);
  Assert.IsNotNull(LZ);
  // the vector points to its x component
  Assert.AreEqual(LX.Value, LDef.Value);
  Assert.AreEqual(LX.Value + 8, LZ.Value);
end;

procedure TTestDoomScriptProgram.DovrebbeTrovareUnDefPerNomeEScope;
var
  LDef: TDoomScriptVarDef;
begin
  FRig.Compile('float outer;'#10'namespace box { float inner; }'#10'void main() { float local; }'#10);
  Assert.IsNotNull(FProgram.GetDef(nil, 'outer', FProgram.DefNamespace));
  Assert.IsNull(FProgram.GetDef(nil, 'inner', FProgram.DefNamespace), 'a name of another namespace');
  LDef := FProgram.GetDef(nil, 'box', FProgram.DefNamespace);
  Assert.IsNotNull(LDef);
  Assert.IsNotNull(FProgram.GetDef(nil, 'inner', LDef));
  // from inside the namespace the outer names are visible
  Assert.IsNotNull(FProgram.GetDef(nil, 'outer', LDef));
  LDef := FProgram.GetDef(nil, 'main', FProgram.DefNamespace);
  Assert.IsNotNull(FProgram.GetDef(nil, 'local', LDef));
  Assert.IsNull(FProgram.GetDef(nil, 'local', FProgram.DefNamespace), 'a local of a function');
  Assert.IsNull(FProgram.GetDef(nil, 'nothing', FProgram.DefNamespace));
  Assert.IsNull(FProgram.GetDefList('nothing'));
end;

procedure TTestDoomScriptProgram.DovrebbeRifiutareLoStessoNomeConUnAltroTipo;
begin
  FProgram.AllocDef(FProgram.BuiltinType(evFloat), 'thing', FProgram.DefNamespace, False);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FProgram.GetDef(FProgram.BuiltinType(evString), 'thing', FProgram.DefNamespace);
    end, EDoomScriptCompileError, 'Type mismatch on redeclaration of thing');
end;

procedure TTestDoomScriptProgram.DovrebbeLiberareUnVettoreConLeSueComponentiERinumerare;
var
  LVector: TDoomScriptVarDef;
  LAfter: TDoomScriptVarDef;
  LCount: Integer;
begin
  LCount := FProgram.NumDefs;
  LVector := FProgram.AllocDef(FProgram.BuiltinType(evVector), 'vec', FProgram.DefNamespace, False);
  LAfter := FProgram.AllocDef(FProgram.BuiltinType(evFloat), 'after', FProgram.DefNamespace, False);
  Assert.AreEqual(LCount + 5, FProgram.NumDefs);
  FProgram.FreeDef(LVector, FProgram.DefNamespace);
  Assert.AreEqual(LCount + 1, FProgram.NumDefs);
  Assert.AreEqual(LCount, LAfter.Num, 'the defs after the freed ones are renumbered');
  Assert.IsNull(FProgram.GetDef(nil, 'vec_y', FProgram.DefNamespace));
  Assert.IsNull(FProgram.GetDef(nil, 'vec', FProgram.DefNamespace));
end;

procedure TTestDoomScriptProgram.DovrebbeTrovareUnaFunzioneAncheInUnNamespace;
begin
  FRig.Compile('void top() { }'#10'namespace box { void inside() { } namespace deep { void far() { } } }'#10);
  Assert.IsNotNull(FProgram.FindFunction('top'));
  Assert.IsNotNull(FProgram.FindFunction('box::inside'));
  Assert.IsNotNull(FProgram.FindFunction('box::deep::far'));
  Assert.AreEqual('box::deep::far', string(FProgram.FindFunction('box::deep::far').Name));
  Assert.IsNull(FProgram.FindFunction('inside'));
  Assert.IsNull(FProgram.FindFunction('nowhere::inside'));
  Assert.IsNull(FProgram.FindFunction('box::nothing'));
  Assert.IsNull(FProgram.FindFunction(''));
end;

procedure TTestDoomScriptProgram.DovrebbeNonDareComeFunzioneUnEventoOUnaVariabile;
begin
  FRig.Compile('float number;'#10);
  Assert.IsNull(FProgram.FindFunction('number'));
  Assert.IsNull(FProgram.FindFunction('println'), 'an event is not a script function');
end;

procedure TTestDoomScriptProgram.DovrebbeTrovareLaFunzioneDiUnTipoOggettoODelSuoSuperTipo;
var
  LBase: TDoomScriptTypeDef;
  LDerived: TDoomScriptTypeDef;
begin
  FRig.Compile(
    'object base { void hello(); };'#10 +
    'void base::hello() { }'#10 +
    'object derived : base { void more(); };'#10 +
    'void derived::more() { }'#10);
  LBase := FProgram.FindType('base');
  LDerived := FProgram.FindType('derived');
  Assert.IsNotNull(LBase);
  Assert.IsNotNull(LDerived);
  Assert.IsNull(FProgram.FindType('nothing'));
  Assert.AreEqual('base::hello', string(FProgram.FindFunction('hello', LBase).Name));
  Assert.AreEqual('base::hello', string(FProgram.FindFunction('hello', LDerived).Name));
  Assert.AreEqual('derived::more', string(FProgram.FindFunction('more', LDerived).Name));
  Assert.IsNull(FProgram.FindFunction('more', LBase));
  Assert.IsTrue(LDerived.Inherits(LBase));
  Assert.IsFalse(LBase.Inherits(LDerived));
end;

procedure TTestDoomScriptProgram.DovrebbeRifiutareGliIndiciFuoriDaiLimiti;
begin
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GlobalPtr(-1, 4); end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GlobalPtr(DS_MAX_GLOBALS - 3, 4); end,
    EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GlobalPtr(0, -1); end, EDoomScriptMemoryError);
  Assert.IsNotNull(FProgram.GlobalPtr(DS_MAX_GLOBALS - 4, 4));
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetStatement(-1); end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetStatement(FProgram.NumStatements); end,
    EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetFunction(-1); end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetFunction(FProgram.NumFunctions); end,
    EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetFilename(FProgram.NumFilenames); end,
    EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetFilename(-1); end, EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetTypeByIndex(FProgram.NumTypes); end,
    EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetDefByIndex(-1); end, EDoomScriptMemoryError);
  Assert.AreEqual(-1, FProgram.GetFunctionIndex(nil));
end;

procedure TTestDoomScriptProgram.DovrebbeFermarsiAlLimiteDegliStatement;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    var
      LIndex: Integer;
    begin
      for LIndex := 0 to DS_MAX_STATEMENTS do
        FProgram.AllocStatement;
    end, EDoomScriptCompileError, Format('Exceeded maximum allowed number of statements (%d)', [DS_MAX_STATEMENTS]));
  Assert.AreEqual(DS_MAX_STATEMENTS, FProgram.NumStatements);
end;

procedure TTestDoomScriptProgram.DovrebbeFermarsiAlLimiteDelleFunzioni;
var
  LDef: TDoomScriptVarDef;
begin
  FRig.Compile('void main() { }'#10);
  LDef := FProgram.GetDef(nil, 'main', FProgram.DefNamespace);
  TDoomScriptTestSupport.ExpectError(
    procedure
    var
      LIndex: Integer;
    begin
      for LIndex := 0 to DS_MAX_FUNCS do
        FProgram.AllocFunction(LDef);
    end, EDoomScriptCompileError, Format('Exceeded maximum allowed number of functions (%d)', [DS_MAX_FUNCS]));
  Assert.AreEqual(DS_MAX_FUNCS, FProgram.NumFunctions);
end;

procedure TTestDoomScriptProgram.DovrebbeFermarsiAlLimiteDelleVariabiliGlobali;
begin
  TDoomScriptTestSupport.ExpectClass(
    procedure
    var
      LIndex: Integer;
    begin
      for LIndex := 0 to DS_MAX_GLOBALS div DS_MAX_STRING_LEN do
        FProgram.AllocDef(FProgram.BuiltinType(evString), AnsiString('s' + IntToStr(LIndex)), FProgram.DefNamespace,
          False);
    end, EDoomScriptCompileError);
end;

procedure TTestDoomScriptProgram.DovrebbeDareLoStessoChecksumPerLoStessoProgramma;
var
  LOther: TDoomScriptTestRig;
  LFirst: Integer;
begin
  FRig.Compile('float a; void main() { a = a + 1; }'#10);
  LFirst := FProgram.CalculateChecksum;
  Assert.AreEqual(LFirst, FProgram.CalculateChecksum);
  LOther := TDoomScriptTestRig.Create;
  try
    LOther.Compile('float a; void main() { a = a + 1; }'#10);
    Assert.AreEqual(LFirst, LOther.Machine.ScriptProgram.CalculateChecksum, 'the same program in another machine');
    LOther.Compile('void more() { a = a - 1; }'#10);
    Assert.AreNotEqual(LFirst, LOther.Machine.ScriptProgram.CalculateChecksum);
  finally
    LOther.Free;
  end;
end;

procedure TTestDoomScriptProgram.DovrebbeSalvareERipristinareLeVariabiliCambiate;
var
  LData: TBytes;
  LStream: TBytesStream;
  LDef: TDoomScriptVarDef;
begin
  FRig.Compile('float a = 3; string s = "start"; void change() { a = 7; s = "changed"; }'#10);
  FProgram.FinishCompilation;
  Assert.IsTrue(FRig.Run('change'));
  LData := SavedProgram;
  FProgram.Restart;
  LDef := FProgram.GetDef(nil, 'a', FProgram.DefNamespace);
  Assert.AreEqual(Single(3), PSingle(FProgram.GlobalPtr(LDef.Value, 4))^, 'a restart gives the first values back');
  LStream := TBytesStream.Create(LData);
  try
    Assert.IsTrue(FProgram.Restore(LStream));
    Assert.AreEqual(LStream.Size, LStream.Position, 'the whole save is read');
  finally
    LStream.Free;
  end;
  Assert.AreEqual(Single(7), PSingle(FProgram.GlobalPtr(LDef.Value, 4))^);
  LDef := FProgram.GetDef(nil, 's', FProgram.DefNamespace);
  Assert.AreEqual('changed', string(TDoomScriptMemory.ReadString(FProgram.GlobalPtr(LDef.Value, DS_MAX_STRING_LEN))));
end;

procedure TTestDoomScriptProgram.DovrebbeDareFalsoSeIlChecksumSalvatoEDiverso;
var
  LData: TBytes;
  LStream: TBytesStream;
begin
  FRig.Compile('float a = 3;'#10);
  FProgram.FinishCompilation;
  LData := SavedProgram;
  // the checksum is the last integer
  LData[Length(LData) - 1] := LData[Length(LData) - 1] xor $55;
  LStream := TBytesStream.Create(LData);
  try
    Assert.IsFalse(FProgram.Restore(LStream));
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptProgram.DovrebbeDareErroreDedicatoPerUnSalvataggioTronco;
var
  LData: TBytes;
  LLength: Integer;
begin
  FRig.Compile('float a = 3; void change() { a = 7; }'#10);
  FProgram.FinishCompilation;
  FRig.Run('change');
  LData := SavedProgram;
  for LLength := 0 to Length(LData) - 1 do
    ExpectRestoreError(Copy(LData, 0, LLength), EDoomScriptError);
end;

procedure TTestDoomScriptProgram.DovrebbeDareErroreDiMemoriaPerUnIndiceDiVariabileFuoriIntervallo;
var
  LStream: TBytesStream;
begin
  FProgram.FinishCompilation;
  LStream := TBytesStream.Create;
  try
    // no file, then a changed byte at an index past the globals: the original writes outside its array
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    TDoomScriptSaveStream.WriteInt(LStream, DS_MAX_GLOBALS);
    TDoomScriptSaveStream.WriteByte(LStream, 1);
    TDoomScriptSaveStream.WriteInt(LStream, -1);
    ExpectRestoreError(Copy(LStream.Bytes, 0, LStream.Size), EDoomScriptMemoryError);
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptProgram.DovrebbeDareErroreDiMemoriaPerUnNumeroDiVariabiliFuoriIntervallo;
var
  LStream: TBytesStream;
begin
  FProgram.FinishCompilation;
  LStream := TBytesStream.Create;
  try
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    TDoomScriptSaveStream.WriteInt(LStream, -1);
    TDoomScriptSaveStream.WriteInt(LStream, DS_MAX_GLOBALS + 1);
    ExpectRestoreError(Copy(LStream.Bytes, 0, LStream.Size), EDoomScriptMemoryError);
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptProgram.DovrebbeTornareAlloStatoFinitoConRestart;
var
  LFunctions: Integer;
  LStatements: Integer;
  LTypes: Integer;
  LDefs: Integer;
  LFiles: Integer;
  LVariables: Integer;
begin
  FRig.Compile('float a = 3; void main() { a = a + 1; }'#10);
  FProgram.FinishCompilation;
  LFunctions := FProgram.NumFunctions;
  LStatements := FProgram.NumStatements;
  LTypes := FProgram.NumTypes;
  LDefs := FProgram.NumDefs;
  LFiles := FProgram.NumFilenames;
  LVariables := FProgram.NumVariables;
  Assert.AreEqual(LFunctions, FProgram.TopFunctions);
  Assert.AreEqual(LStatements, FProgram.TopStatements);
  Assert.AreEqual(LTypes, FProgram.TopTypes);
  Assert.AreEqual(LDefs, FProgram.TopDefs);
  Assert.AreEqual(LFiles, FProgram.TopFiles);
  FProgram.CompileText('extra.script', 'object extra { float x; }; float b; void more() { b = 1; }'#10, False);
  FRig.Run('main');
  FRig.Machine.CreateThread(FRig.FindFunction('more'));
  Assert.IsTrue(FProgram.NumFunctions > LFunctions);
  Assert.AreEqual(2, FRig.Machine.NumThreads);
  FProgram.Restart;
  Assert.AreEqual(LFunctions, FProgram.NumFunctions);
  Assert.AreEqual(LStatements, FProgram.NumStatements);
  Assert.AreEqual(LTypes, FProgram.NumTypes);
  Assert.AreEqual(LDefs, FProgram.NumDefs);
  Assert.AreEqual(LFiles, FProgram.NumFilenames);
  Assert.AreEqual(LVariables, FProgram.NumVariables);
  Assert.AreEqual(0, FRig.Machine.NumThreads, 'a restart ends the threads');
  Assert.IsNull(FProgram.FindFunction('more'));
  Assert.IsNull(FProgram.FindType('extra'));
  Assert.AreEqual(Single(3), PSingle(FProgram.GlobalPtr(FProgram.GetDef(nil, 'a', FProgram.DefNamespace).Value, 4))^);
end;

procedure TTestDoomScriptProgram.DovrebbeDareErroreSeSiUsaIlRitornoSenzaProgramma;
begin
  FProgram.FreeData;
  Assert.IsNull(FProgram.ReturnDef);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.ReturnFloat(1); end, EDoomScriptError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.ReturnString('x'); end, EDoomScriptError);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.GetReturnedInteger; end, EDoomScriptError);
end;

procedure TTestDoomScriptProgram.DovrebbeDareErroreSenzaCompilatore;
begin
  FProgram.SetCompiler(nil);
  TDoomScriptTestSupport.ExpectClass(procedure begin FProgram.CompileText('x', 'float a;', False); end,
    EDoomScriptError);
end;

procedure TTestDoomScriptProgram.DovrebbeDareErroreSeIlFileNonEsiste;
begin
  TDoomScriptTestSupport.ExpectError(procedure begin FProgram.CompileFile('script/missing.script'); end,
    EDoomScriptError, 'Couldn''t load script/missing.script'#10);
end;

procedure TTestDoomScriptProgram.DovrebbeTenereIlNomeInteroDiUnFileFuoriDallaBase;
begin
  FRig.Host.BasePath := '/base/';
  Assert.AreEqual('inside.script', string(FProgram.GetFilename(FProgram.GetFilenum('/base/inside.script'))));
  // not off the base path: the full path is the name
  Assert.AreEqual('/elsewhere/out.script', string(FProgram.GetFilename(FProgram.GetFilenum('/elsewhere/out.script'))));
  // the same name again gives the same number
  Assert.AreEqual(FProgram.GetFilenum('/base/inside.script'), FProgram.GetFilenum('/base/inside.script'));
end;

procedure TTestDoomScriptProgram.DovrebbeDisassemblareLeFunzioniENonGliEventi;
var
  LText: string;
begin
  FRig.Compile(
    'float g = 2.5; vector v = ''1 2 3'';'#10 +
    'void main() { float a; a = g + 1; if ( a ) { sys.print( "two' + '\n' + 'lines" ); } v = v + ''1 0 0''; }'#10);
  LText := string(FProgram.DisassembleText);
  Assert.Contains(LText, 'function main() ');
  Assert.IsFalse(LText.Contains('function println()'), 'events are skipped');
  Assert.Contains(LText, 'ADD_F');
  Assert.Contains(LText, 'const float 1.000000');
  Assert.Contains(LText, 'event print');
  Assert.Contains(LText, 'const string "two\nlines"');
  Assert.Contains(LText, 'const vector ''1 0 0''');
  Assert.Contains(LText, 'stack[');
  Assert.Contains(LText, 'global[');
  Assert.Contains(LText, 'address ');
  Assert.Contains(LText, 'args ');
end;

procedure TTestDoomScriptProgram.DovrebbeScrivereIlDisassemblatoSeLHostLoChiede;
begin
  FRig.Host.DisassembleOn := True;
  FRig.Compile('void main() { }'#10);
  Assert.AreEqual('', string(FRig.Files.GetFile('script/disasm.txt')), 'CompileText alone does not disassemble');
  FRig.Files.SetFile('script/one.script', 'void one() { }'#10);
  FProgram.CompileFile('script/one.script');
  Assert.Contains(string(FRig.Files.GetFile('script/disasm.txt')), 'function one() ');
  Assert.IsNotNull(FProgram.CompileFunction('two', 'void two() { }'#10));
  Assert.Contains(string(FRig.Files.GetFile('script/disasm.txt')), 'function two() ');
end;

procedure TTestDoomScriptProgram.DovrebbeStampareLeStatisticheConLeRigheDellOriginale;
var
  LPrinted: string;
begin
  FRig.Compile('float a; void main() { a = 1; }'#10);
  LPrinted := FRig.Printed;
  Assert.Contains(LPrinted, '---------- Compile stats ----------'#10);
  Assert.Contains(LPrinted, #10'Memory usage:'#10);
  Assert.Contains(LPrinted, Format('     Strings: %d, ', [FProgram.NumFilenames]));
  Assert.Contains(LPrinted, Format('  Statements: %d, ', [FProgram.NumStatements]));
  Assert.Contains(LPrinted, Format('   Functions: %d, ', [FProgram.NumFunctions]));
  Assert.Contains(LPrinted, Format('   Variables: %d bytes'#10, [FProgram.NumVariables]));
  Assert.Contains(LPrinted, '    Mem used: ');
  Assert.Contains(LPrinted, ' Static data: ');
  Assert.Contains(LPrinted, '   Allocated: ');
  Assert.Contains(LPrinted, ' Thread size: ');
  // the list of the files goes to the developer channel of the host
  Assert.IsTrue(FRig.Host.Calls.IndexOf('DPRINT Files loaded:'#10) >= 0, FRig.Host.Calls.Text);
  Assert.IsTrue(FRig.Host.Calls.IndexOf('DPRINT    test.script'#10) >= 0, FRig.Host.Calls.Text);
  Assert.IsFalse(LPrinted.Contains('Files loaded'), 'not in the normal channel');
end;

procedure TTestDoomScriptProgram.DovrebbeStampareIlNomeCheLOriginaleLeggeDalSuoBuffer;
begin
  // A defect of the original kept for parity: the compiler receives the buffer of the string "filename" of the
  // program, which changes while it compiles. A normal script ends with a token of its own file:
  FProgram.CompileText('a_name_of_twenty_five_chr', 'float one;'#10, False);
  Assert.Contains(FRig.Printed, 'Compiled ''a_name_of_twenty_five_chr''');
  // a text without tokens after the include of the default script: the last file a token came from is that
  // script, and its name (shorter than 32) took the place of a name of 20 to 31 characters in the buffer
  FProgram.CompileText('only_comments_long_name', '// nothing'#10, False);
  Assert.Contains(FRig.Printed, 'Compiled ''script/doom_defs.script''');
  Assert.IsFalse(FRig.Printed.Contains('Compiled ''only_comments_long_name'''), FRig.Printed);
  // a name shorter than 20 characters lives in the buffer inside the string: the longer name of the default
  // script goes to a new block and the first buffer keeps the first name
  FProgram.Restart;
  FProgram.CompileText('short_name', '// nothing'#10, False);
  Assert.Contains(FRig.Printed, 'Compiled ''short_name''');
end;

procedure TTestDoomScriptProgram.DovrebbeScrivereIlNumeroDiUnEntitaNellaSuaVariabile;
var
  LDef: TDoomScriptVarDef;
begin
  // a script that names the entity "door" declares the variable $door
  FRig.Compile('void main() { entity e = $door; }'#10);
  LDef := FProgram.GetDef(nil, '$door', FProgram.DefNamespace);
  Assert.IsNotNull(LDef);
  FProgram.SetEntity('door', 7);
  // 0 is no entity: the script holds the number plus one
  Assert.AreEqual(8, PInteger(FProgram.GlobalPtr(LDef.Value, 4))^);
  FProgram.SetEntity('door', -1);
  Assert.AreEqual(0, PInteger(FProgram.GlobalPtr(LDef.Value, 4))^);
  // an entity no script names: nothing happens
  FProgram.SetEntity('unknown', 3);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptProgram);

end.
