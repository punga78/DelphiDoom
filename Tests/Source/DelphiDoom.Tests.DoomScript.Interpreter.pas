{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptInterpreter  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Interpreter;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.Thread, DelphiDoom.Tests.DoomScript.Rig;

type
  /// <summary>The state of a thread as a save game holds it, to build damaged or hostile saves</summary>
  TSavedThread = record
    Depth: Integer;
    FrameStatement: array[0..1] of Integer;
    FrameFunction: array[0..1] of Integer;
    FrameBase: array[0..1] of Integer;
    Stack: TBytes;
    /// <summary>What the save says of the size of the stack; -2 = the real size</summary>
    Used: Integer;
    Base: Integer;
    Func: Integer;
    InstructionPointer: Integer;
    PopParms: Integer;
    WaitingFor: Integer;
    class function Create: TSavedThread; static;
  end;

  /// <summary>
  ///   The safety of the interpreter: no state a damaged save game or a damaged program can put it in may
  ///   read or write outside the memory of the machine. Where the original has undefined behaviour or a
  ///   crash the port raises EDoomScriptError (EDoomScriptMemoryError for the accesses).
  /// </summary>
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptInterpreter = class
  strict private
    FRig: TDoomScriptTestRig;
    function RestoreThread(const ASaved: TSavedThread): TDoomScriptThread;
    procedure ExpectRestoreError(const ASaved: TSavedThread; const AWhat: string);
    function ExecuteError(const AThread: TDoomScriptThread): string;
    function FindStatement(const AFunction: AnsiString; const AOp: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRipristinareUnoStatoValidoEProseguire;
    [Test]
    procedure DovrebbeRifiutareUnaProfonditaDiChiamataFuoriLimite;
    [Test]
    procedure DovrebbeRifiutareUnaPilaLocaleFuoriLimite;
    [Test]
    procedure DovrebbeRifiutareUnaBaseDellaPilaFuoriLimite;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiFunzioneFuoriLimite;
    [Test]
    procedure DovrebbeRifiutarePopParmsOltreLaPila;
    [Test]
    procedure DovrebbeRifiutareUnEntitaAttesaFuoriLimite;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerUnPuntatoreDiIstruzioneFuoriDalProgramma;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerLocaliOltreLaPila;
    [Test]
    procedure DovrebbeDareErroreSeIlRitornoPortaAUnaFunzioneNulla;
    [Test]
    procedure DovrebbeDareProgStackUnderflowSeNonCiSonoChiamate;
    [Test]
    procedure DovrebbeDareLocalsStackUnderflowSeLaPilaEPiuCortaDeiLocali;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerUnPuntatoreFalso;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerUnPuntatoreAUnOggettoRimosso;
    [Test]
    procedure DovrebbeDareErroreDiMemoriaPerUnPuntatoreOltreLOggetto;
    [Test]
    procedure DovrebbeSopravvivereAOgniOperandoMancante;
    [Test]
    procedure DovrebbeDareBadOpcodePerUnCodiceNonValido;
    [Test]
    procedure DovrebbeFermareUnCicloSenzaFine;
    [Test]
    procedure DovrebbeDareErrorePerTroppeChiamateAnnidate;
    [Test]
    procedure DovrebbeDareErrorePerTroppeVariabiliLocali;
    [Test]
    procedure DovrebbeDareErrorePerTroppiArgomentiInPila;
    [Test]
    procedure DovrebbeDareErrorePerIlModuloConDivisoreFraMenoUnoEUnoCheNellOriginaleEUnCrash;
    [Test]
    procedure DovrebbeAvvisareEDareZeroPerIlModuloPerZero;
    [Test]
    procedure DovrebbeDareZeroPerIlModuloPerMenoUno;
    [Test]
    procedure DovrebbeDareErrorePerUnaFunzioneNulla;
    [Test]
    procedure DovrebbeDareErroreControllatoPerUnaFunzioneConParametriAvviataSenzaArgomenti;
    [Test]
    procedure DovrebbeLeggereLeVariabiliDiUnThreadFermo;
    [Test]
    procedure DovrebbeNonLeggereUnCampoCheNellOriginaleEUnAccessoIndefinito;
    [Test]
    procedure DovrebbeScrivereIFloatComeIlPercentoGDelC;
    [Test]
    procedure DovrebbeMostrareUnThreadSenzaPila;
    [Test]
    procedure DovrebbeRifiutareUnEventoSuPiuFotogrammiSenzaLaSuaEntita;
    [Test]
    procedure DovrebbeTerminareIlThreadPerUnEntitaNullaInUnArgomentoObbligatorio;
    [Test]
    procedure DovrebbeDareUnValoreSicuroSeLEntitaNonRispondeAllEvento;
    [Test]
    procedure DovrebbeTracciareLeChiamateConIlDebug;
  end;

implementation

uses
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.Opcodes,
  DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.ScriptObject, DelphiDoom.DoomScript.SaveStream,
  DelphiDoom.Tests.DoomScript.Support;

const
  POINTER_FLAG = Cardinal($80000000);
  POINTER_ENTITY_SHIFT = 18;

class function TSavedThread.Create: TSavedThread;
begin
  Result := Default(TSavedThread);
  Result.Depth := 1;
  Result.FrameFunction[0] := -1;
  Result.FrameFunction[1] := -1;
  Result.Used := -2;
  Result.Func := -1;
  Result.WaitingFor := DS_ENTITYNUM_NONE;
end;

procedure TTestDoomScriptInterpreter.Setup;
begin
  FRig := TDoomScriptTestRig.Create;
end;

procedure TTestDoomScriptInterpreter.TearDown;
begin
  FRig.Free;
end;

function TTestDoomScriptInterpreter.RestoreThread(const ASaved: TSavedThread): TDoomScriptThread;
var
  LStream: TBytesStream;
  LIndex: Integer;
begin
  Result := FRig.Machine.CreateThread;
  LStream := TBytesStream.Create;
  try
    // idThread::Save
    TDoomScriptSaveStream.WriteInt(LStream, Result.ThreadNum);
    TDoomScriptSaveStream.WriteInt(LStream, -1);
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.WaitingFor);
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    // idInterpreter::Save
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.Depth);
    for LIndex := 0 to ASaved.Depth - 1 do
      if LIndex <= High(ASaved.FrameStatement) then
      begin
        TDoomScriptSaveStream.WriteInt(LStream, ASaved.FrameStatement[LIndex]);
        TDoomScriptSaveStream.WriteInt(LStream, ASaved.FrameFunction[LIndex]);
        TDoomScriptSaveStream.WriteInt(LStream, ASaved.FrameBase[LIndex]);
      end;
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.Depth);
    if ASaved.Used = -2 then
      TDoomScriptSaveStream.WriteInt(LStream, Length(ASaved.Stack))
    else
      TDoomScriptSaveStream.WriteInt(LStream, ASaved.Used);
    if Length(ASaved.Stack) > 0 then
      LStream.WriteBuffer(ASaved.Stack[0], Length(ASaved.Stack));
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.Base);
    TDoomScriptSaveStream.WriteInt(LStream, Length(ASaved.Stack));
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.Func);
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.InstructionPointer);
    TDoomScriptSaveStream.WriteInt(LStream, ASaved.PopParms);
    TDoomScriptSaveStream.WriteString(LStream, '');
    TDoomScriptSaveStream.WriteInt(LStream, -1);
    TDoomScriptSaveStream.WriteInt(LStream, -1);
    TDoomScriptSaveStream.WriteBool(LStream, False);
    TDoomScriptSaveStream.WriteBool(LStream, False);
    TDoomScriptSaveStream.WriteBool(LStream, True);
    TDoomScriptSaveStream.WriteBool(LStream, False);
    // the rest of idThread::Save
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    TDoomScriptSaveStream.WriteString(LStream, 'restored');
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    TDoomScriptSaveStream.WriteInt(LStream, 0);
    TDoomScriptSaveStream.WriteBool(LStream, False);
    LStream.Position := 0;
    Result.Restore(LStream, FRig.Machine.ReadObject);
  finally
    LStream.Free;
  end;
end;

procedure TTestDoomScriptInterpreter.ExpectRestoreError(const ASaved: TSavedThread; const AWhat: string);
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    RestoreThread(ASaved);
  except
    on E: EDoomScriptMemoryError do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'no EDoomScriptMemoryError for ' + AWhat);
end;

function TTestDoomScriptInterpreter.ExecuteError(const AThread: TDoomScriptThread): string;
begin
  Result := '';
  try
    AThread.Execute;
  except
    on E: EDoomScriptError do
      Result := E.ClassName + ': ' + E.Message;
  end;
end;

function TTestDoomScriptInterpreter.FindStatement(const AFunction: AnsiString; const AOp: Integer): Integer;
var
  LFunction: TDoomScriptFunction;
  LIndex: Integer;
begin
  LFunction := FRig.FindFunction(AFunction);
  for LIndex := LFunction.FirstStatement to LFunction.FirstStatement + LFunction.NumStatements - 1 do
    if FRig.Machine.ScriptProgram.GetStatement(LIndex).Op = AOp then
      Exit(LIndex);
  Assert.Fail(Format('no opcode %s in %s', [string(DoomScriptOpcodes[AOp].OpName), string(AFunction)]));
  Result := -1;
end;

procedure TTestDoomScriptInterpreter.DovrebbeRipristinareUnoStatoValidoEProseguire;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
  LThread: TDoomScriptThread;
begin
  FRig.Compile('void main() { float a; a = 5; sys.print( "a is " + a ); }'#10);
  LFunction := FRig.FindFunction('main');
  LSaved := TSavedThread.Create;
  SetLength(LSaved.Stack, LFunction.Locals);
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LFunction.FirstStatement - 1;
  LThread := RestoreThread(LSaved);
  Assert.AreEqual('restored', string(LThread.GetThreadName));
  Assert.AreEqual('', ExecuteError(LThread));
  Assert.Contains(FRig.Printed, 'a is 5');
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutareUnaProfonditaDiChiamataFuoriLimite;
var
  LSaved: TSavedThread;
begin
  LSaved := TSavedThread.Create;
  LSaved.Depth := -1;
  ExpectRestoreError(LSaved, 'callStackDepth -1');
  LSaved.Depth := DS_MAX_STACK_DEPTH + 1;
  ExpectRestoreError(LSaved, 'callStackDepth 65');
  LSaved.Depth := MaxInt;
  ExpectRestoreError(LSaved, 'callStackDepth MaxInt');
  LSaved := TSavedThread.Create;
  LSaved.FrameBase[0] := -4;
  ExpectRestoreError(LSaved, 'stackbase -4');
  LSaved.FrameBase[0] := DS_LOCALSTACK_SIZE + 1;
  ExpectRestoreError(LSaved, 'stackbase past the stack');
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutareUnaPilaLocaleFuoriLimite;
var
  LSaved: TSavedThread;
begin
  LSaved := TSavedThread.Create;
  LSaved.Used := -1;
  ExpectRestoreError(LSaved, 'localstackUsed -1');
  LSaved.Used := DS_LOCALSTACK_SIZE + 1;
  ExpectRestoreError(LSaved, 'localstackUsed 6145');
  LSaved.Used := MaxInt;
  ExpectRestoreError(LSaved, 'localstackUsed MaxInt');
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutareUnaBaseDellaPilaFuoriLimite;
var
  LSaved: TSavedThread;
begin
  LSaved := TSavedThread.Create;
  LSaved.Base := -4;
  ExpectRestoreError(LSaved, 'localstackBase -4');
  LSaved.Base := DS_LOCALSTACK_SIZE + 4;
  ExpectRestoreError(LSaved, 'localstackBase past the stack');
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutareUnIndiceDiFunzioneFuoriLimite;
var
  LSaved: TSavedThread;
begin
  LSaved := TSavedThread.Create;
  LSaved.Func := FRig.Machine.ScriptProgram.NumFunctions;
  ExpectRestoreError(LSaved, 'currentFunction past the functions');
  LSaved := TSavedThread.Create;
  LSaved.FrameFunction[0] := 100000;
  ExpectRestoreError(LSaved, 'a function of the call stack past the functions');
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutarePopParmsOltreLaPila;
var
  LSaved: TSavedThread;
begin
  LSaved := TSavedThread.Create;
  SetLength(LSaved.Stack, 8);
  LSaved.PopParms := 12;
  ExpectRestoreError(LSaved, 'popParms 12 of 8');
  LSaved.PopParms := -4;
  ExpectRestoreError(LSaved, 'popParms -4');
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutareUnEntitaAttesaFuoriLimite;
var
  LSaved: TSavedThread;
begin
  LSaved := TSavedThread.Create;
  LSaved.WaitingFor := DS_MAX_GENTITIES;
  ExpectRestoreError(LSaved, 'waitingFor 4096');
  LSaved.WaitingFor := -1;
  ExpectRestoreError(LSaved, 'waitingFor -1');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreDiMemoriaPerUnPuntatoreDiIstruzioneFuoriDalProgramma;
var
  LSaved: TSavedThread;
  LValue: Integer;
begin
  FRig.Compile('void main() { }'#10);
  for LValue in TArray<Integer>.Create(FRig.Machine.ScriptProgram.NumStatements, MaxInt - 1, -5, Low(Integer)) do
  begin
    LSaved := TSavedThread.Create;
    LSaved.Func := FRig.FindFunction('main').Index;
    LSaved.InstructionPointer := LValue;
    Assert.StartsWith('EDoomScriptMemoryError', ExecuteError(RestoreThread(LSaved)), IntToStr(LValue));
  end;
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreDiMemoriaPerLocaliOltreLaPila;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
begin
  FRig.Compile('void main() { float a; string s; a = 5; s = "text"; }'#10);
  LFunction := FRig.FindFunction('main');
  LSaved := TSavedThread.Create;
  // the base is inside the stack, the locals of the function are not
  SetLength(LSaved.Stack, DS_LOCALSTACK_SIZE);
  LSaved.Base := DS_LOCALSTACK_SIZE - 4;
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LFunction.FirstStatement - 1;
  Assert.StartsWith('EDoomScriptMemoryError', ExecuteError(RestoreThread(LSaved)));
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreSeIlRitornoPortaAUnaFunzioneNulla;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
  LError: string;
begin
  // two frames, the one to return to has no function: the original would go on with a NULL function
  FRig.Compile('void main() { }'#10);
  LFunction := FRig.FindFunction('main');
  LSaved := TSavedThread.Create;
  LSaved.Depth := 2;
  LSaved.FrameStatement[1] := LFunction.FirstStatement;
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LFunction.FirstStatement - 1;
  LError := ExecuteError(RestoreThread(LSaved));
  Assert.StartsWith('EDoomScript', LError);
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareProgStackUnderflowSeNonCiSonoChiamate;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
begin
  // a function is running and the call stack is empty: its return has nowhere to go
  FRig.Compile('void main() { }'#10);
  LFunction := FRig.FindFunction('main');
  LSaved := TSavedThread.Create;
  LSaved.Depth := 0;
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LFunction.FirstStatement - 1;
  Assert.Contains(ExecuteError(RestoreThread(LSaved)), 'prog stack underflow');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareLocalsStackUnderflowSeLaPilaEPiuCortaDeiLocali;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
begin
  // the function has 8 bytes of locals and the stack of the save has 4: the return would pop below zero
  FRig.Compile('void main() { float a; float b; }'#10);
  LFunction := FRig.FindFunction('main');
  Assert.AreEqual(8, LFunction.Locals);
  LSaved := TSavedThread.Create;
  SetLength(LSaved.Stack, 4);
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LFunction.FirstStatement - 1;
  Assert.Contains(ExecuteError(RestoreThread(LSaved)), 'locals stack underflow');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreDiMemoriaPerUnPuntatoreFalso;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
  LStore: Integer;
  LIndex: Integer;
  LValue: Cardinal;
begin
  FRig.Compile(
    'object thing { float x; void setx(); };'#10 +
    'void thing::setx() { x = 5; }'#10);
  LFunction := FRig.FindFunction('thing::setx');
  LStore := FindStatement('thing::setx', OP_STOREP_F);
  // every word of the stack is the false pointer: whatever the temporary of the address is, it reads it
  for LValue in TArray<Cardinal>.Create($12345678, $7FFFFFFF, 1) do
  begin
    LSaved := TSavedThread.Create;
    SetLength(LSaved.Stack, LFunction.Locals);
    for LIndex := 0 to Length(LSaved.Stack) div 4 - 1 do
      PCardinal(@LSaved.Stack[LIndex * 4])^ := LValue;
    LSaved.Func := LFunction.Index;
    LSaved.InstructionPointer := LStore - 1;
    Assert.StartsWith('EDoomScriptMemoryError', ExecuteError(RestoreThread(LSaved)), IntToHex(LValue, 8));
  end;
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreDiMemoriaPerUnPuntatoreAUnOggettoRimosso;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
  LStore: Integer;
  LIndex: Integer;
  LThread: TDoomScriptThread;
begin
  FRig.Compile(
    'object thing { float x; void setx(); };'#10 +
    'void thing::setx() { x = 5; }'#10);
  FRig.AddEntity(9, 'nine');
  Assert.IsTrue(FRig.Machine.Entities.ObjectOf(9).SetType('thing'));
  LFunction := FRig.FindFunction('thing::setx');
  LStore := FindStatement('thing::setx', OP_STOREP_F);
  LSaved := TSavedThread.Create;
  SetLength(LSaved.Stack, LFunction.Locals);
  // a handle to the field 0 of the object of the entity 9
  for LIndex := 0 to Length(LSaved.Stack) div 4 - 1 do
    PCardinal(@LSaved.Stack[LIndex * 4])^ := POINTER_FLAG or (9 shl POINTER_ENTITY_SHIFT);
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LStore - 1;
  // with the object in place the store works
  LThread := RestoreThread(LSaved);
  Assert.AreEqual('', ExecuteError(LThread));
  Assert.AreEqual(Single(5), PSingle(FRig.Machine.Entities.ObjectOf(9).DataPtr(0, 4))^);
  // the entity goes away: the original would write into freed memory
  FRig.Machine.Entities.Remove(9);
  Assert.StartsWith('EDoomScriptMemoryError', ExecuteError(RestoreThread(LSaved)));
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreDiMemoriaPerUnPuntatoreOltreLOggetto;
var
  LSaved: TSavedThread;
  LFunction: TDoomScriptFunction;
  LStore: Integer;
  LIndex: Integer;
begin
  FRig.Compile(
    'object thing { float x; void setx(); };'#10 +
    'void thing::setx() { x = 5; }'#10);
  FRig.AddEntity(9, 'nine');
  Assert.IsTrue(FRig.Machine.Entities.ObjectOf(9).SetType('thing'));
  LFunction := FRig.FindFunction('thing::setx');
  LStore := FindStatement('thing::setx', OP_STOREP_F);
  LSaved := TSavedThread.Create;
  SetLength(LSaved.Stack, LFunction.Locals);
  // the object has 4 bytes: the offsets 1 and 4096 are outside it
  for LIndex := 0 to Length(LSaved.Stack) div 4 - 1 do
    PCardinal(@LSaved.Stack[LIndex * 4])^ := POINTER_FLAG or (9 shl POINTER_ENTITY_SHIFT) or 1;
  LSaved.Func := LFunction.Index;
  LSaved.InstructionPointer := LStore - 1;
  Assert.StartsWith('EDoomScriptMemoryError', ExecuteError(RestoreThread(LSaved)));
  for LIndex := 0 to Length(LSaved.Stack) div 4 - 1 do
    PCardinal(@LSaved.Stack[LIndex * 4])^ := POINTER_FLAG or (9 shl POINTER_ENTITY_SHIFT) or 4096;
  Assert.StartsWith('EDoomScriptMemoryError', ExecuteError(RestoreThread(LSaved)));
end;

procedure TTestDoomScriptInterpreter.DovrebbeSopravvivereAOgniOperandoMancante;
var
  LProgram: TDoomScriptProgram;
  LFunction: TDoomScriptFunction;
  LIndex: Integer;
  LOperand: Integer;
  LStatement: PDoomScriptStatement;
  LSaved: TDoomScriptStatement;
  LErrors: Integer;
  LThread: TDoomScriptThread;
begin
  // A program whose statements lost an operand (damaged memory in the original, where every operand is
  // read without a check): each one, in turn, in a function that uses most of the opcodes. Any outcome but
  // an error of the script machine is a failure of the test (an access violation would end it).
  FRig.AddEntity(3, 'three');
  FRig.Compile(
    'object thing { float x; vector v; string s; entity e; boolean b; void touch(); float get(); };'#10 +
    'void thing::touch() { x = 1; x = x + 2; v = ''1 2 3''; s = "t"; s = x; b = x; x = b; e = $null_entity; }'#10 +
    'float thing::get() { return x; }'#10 +
    'float helper( float p, string t, vector q ) { return p + 1; }'#10 +
    'void spin() { sys.pause(); }'#10 +
    'void main() {'#10 +
    '  float a; float b; vector v; vector w; string s; string t; entity e; boolean flag; thing o;'#10 +
    '  a = 5; b = a * 2 + 1; b = b / a; b = a % 3; b = a & 3; b = a | 4; b = -a; b = ~a; b = !a;'#10 +
    '  a += 1; a -= 1; a *= 2; a /= 2; a %= 3; a |= 1; a &= 3; a++; a--;'#10 +
    '  v = ''1 2 3''; w = v + v; w = v - w; w = v * 2; w = 2 * v; a = v * w; w *= 2; w /= 2; w += v; w -= v; w = -v;'#10 +
    '  flag = ( a == b ); flag = ( a != b ); flag = ( a < b ) || ( a > b ); flag = ( a <= b ) && ( a >= b );'#10 +
    '  flag = ( v == w ); flag = ( v != w ); flag = !v; flag = !flag; a = flag; flag = a;'#10 +
    '  s = "one"; t = s + "two"; t = s + a; t = a + s; t = s + v; t = v + s; s = a; s = v; s = flag;'#10 +
    '  flag = ( s == t ); flag = ( s != t ); flag = !s;'#10 +
    '  e = $three; flag = ( e == $three ); flag = ( e != $null_entity ); flag = !e;'#10 +
    '  e.ping( a ); a = e.twice( b ); sys.print( t ); a = sys.strLength( s );'#10 +
    '  a = helper( b, s, v ); thread spin();'#10 +
    '  o = e; o.touch(); a = o.get(); thread o.touch(); e = o; flag = ( o == e ); flag = ( e != o );'#10 +
    '  if ( a ) { b = 1; } else { b = 2; }'#10 +
    '  while ( a > 0 ) { a = a - 1; if ( a == 2 ) { continue; } if ( a == 1 ) { break; } }'#10 +
    '  for ( a = 0; a < 2; a++ ) { b = b + a; }'#10 +
    '  do { a--; } while ( a > 0 );'#10 +
    '}'#10);
  Assert.IsTrue(FRig.Machine.Entities.ObjectOf(3).SetType('thing'));
  LProgram := FRig.Machine.ScriptProgram;
  // the whole function runs when nothing is damaged
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.AreEqual('', ExecuteError(LThread));
  LErrors := 0;
  for LFunction in TArray<TDoomScriptFunction>.Create(FRig.FindFunction('main'), FRig.FindFunction('thing::touch'),
    FRig.FindFunction('thing::get'), FRig.FindFunction('helper')) do
    for LIndex := LFunction.FirstStatement to LFunction.FirstStatement + LFunction.NumStatements - 1 do
      for LOperand := 0 to 2 do
      begin
        LStatement := LProgram.GetStatement(LIndex);
        LSaved := LStatement^;
        case LOperand of
          0: LStatement.A := nil;
          1: LStatement.B := nil;
          2: LStatement.C := nil;
        end;
        try
          LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
          if ExecuteError(LThread) <> '' then
            Inc(LErrors);
        finally
          LProgram.GetStatement(LIndex)^ := LSaved;
        end;
        FRig.Machine.RestartThreads;
        FRig.Machine.Queue.Clear;
      end;
  Assert.IsTrue(LErrors > 100, Format('only %d damaged statements gave an error', [LErrors]));
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareBadOpcodePerUnCodiceNonValido;
var
  LStatement: PDoomScriptStatement;
  LOp: Word;
begin
  FRig.Compile('float a; void main() { a = a + 1; }'#10);
  for LOp in TArray<Word>.Create(NUM_OPCODES, 200, $FFFF) do
  begin
    LStatement := FRig.Machine.ScriptProgram.GetStatement(FRig.FindFunction('main').FirstStatement);
    LStatement.Op := LOp;
    Assert.Contains(FRig.RunError('main'), Format('Bad opcode %d', [LOp]));
  end;
  // the disassembler does not read the table of the opcodes past its end either
  Assert.Contains(string(FRig.Machine.ScriptProgram.DisassembleText), 'function main()');
end;

procedure TTestDoomScriptInterpreter.DovrebbeFermareUnCicloSenzaFine;
begin
  FRig.Compile('void main() { float a; while ( 1 ) { a = a + 1; } }'#10);
  Assert.Contains(FRig.RunError('main'), 'runaway loop error');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErrorePerTroppeChiamateAnnidate;
begin
  FRig.Compile('void down();'#10'void down() { down(); }'#10);
  Assert.Contains(FRig.RunError('down'), 'call stack overflow');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErrorePerTroppeVariabiliLocali;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  // 49 strings of 128 bytes are more than the 6144 bytes of the local stack
  LText := 'void main() {';
  for LIndex := 0 to 48 do
    LText := LText + AnsiString(Format(' string s%d;', [LIndex]));
  LText := LText + ' }'#10;
  FRig.Compile(LText);
  Assert.Contains(FRig.RunError('main'), 'EnterFuncton: locals stack overflow');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErrorePerTroppiArgomentiInPila;
var
  LText: AnsiString;
  LIndex: Integer;
  LError: string;
begin
  // 47 string locals leave 128 bytes: the second string argument of the call does not fit
  LText := 'void two( string a, string b ) { }'#10'void main() {';
  for LIndex := 0 to 46 do
    LText := LText + AnsiString(Format(' string s%d;', [LIndex]));
  LText := LText + ' two( "a", "b" ); }'#10;
  FRig.Compile(LText);
  LError := FRig.RunError('main');
  Assert.Contains(LError, 'PushString: locals stack overflow');
  // and with floats
  FRig.Machine.RestartThreads;
  LText := 'void three( float a, float b, float c ) { }'#10'void second() {';
  for LIndex := 0 to 47 do
    LText := LText + AnsiString(Format(' string s%d;', [LIndex]));
  LText := LText + ' three( 1, 2, 3 ); }'#10;
  FRig.Compile(LText);
  Assert.Contains(FRig.RunError('second'), 'Push: locals stack overflow');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErrorePerIlModuloConDivisoreFraMenoUnoEUnoCheNellOriginaleEUnCrash;
begin
  // the original tests the float against zero and then divides the integers: 0.5 is not zero, (int)0.5 is
  FRig.Compile(
    'float out;'#10 +
    'void main() { float a = 7; float b = 0.5; out = a % b; }'#10 +
    'void compound() { float a = 7; float b = -0.25; a %= b; }'#10);
  Assert.Contains(FRig.RunError('main'), 'Divide by zero');
  Assert.Contains(FRig.RunError('compound'), 'Divide by zero');
end;

procedure TTestDoomScriptInterpreter.DovrebbeAvvisareEDareZeroPerIlModuloPerZero;
begin
  FRig.Compile('float out = 9; void main() { float a = 7; float b = 0; out = a % b; sys.print( "out " + out ); }'#10);
  Assert.IsTrue(FRig.Run('main'));
  Assert.Contains(FRig.Warnings, 'Divide by zero');
  Assert.Contains(FRig.Printed, 'out 7');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareZeroPerIlModuloPerMenoUno;
begin
  // INT_MIN % -1 traps on the x86; any value modulo -1 is 0
  FRig.Compile('void main() { float a = 7; float b = -1; sys.print( "mod " + ( a % b ) ); }'#10);
  Assert.IsTrue(FRig.Run('main'));
  Assert.Contains(FRig.Printed, 'mod 0');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErrorePerUnaFunzioneNulla;
var
  LMessage: string;
begin
  LMessage := '';
  try
    FRig.Machine.CreateThread(nil);
  except
    on E: EDoomScriptError do
      LMessage := E.Message;
  end;
  Assert.Contains(LMessage, 'NULL function');
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareErroreControllatoPerUnaFunzioneConParametriAvviataSenzaArgomenti;
var
  LError: string;
begin
  // The host starts a function that takes parameters without putting them on the stack: in the original the
  // base of the locals goes below the stack and the function reads and writes before it.
  FRig.Compile('float out; void needs( float a, string s ) { out = a; a = 3; s = "x"; }'#10);
  LError := FRig.RunError('needs');
  Assert.StartsWith('EDoomScript', LError);
end;

procedure TTestDoomScriptInterpreter.DovrebbeLeggereLeVariabiliDiUnThreadFermo;
var
  LThread: TDoomScriptThread;
  LValue: AnsiString;
begin
  FRig.Compile(
    'float shared = 2.5;'#10 +
    'void main() { float a = 1.5; vector v = ''1 2 3''; string s = "text"; boolean b; b = 1; sys.pause(); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsFalse(LThread.Start);
  Assert.IsTrue(LThread.Interpreter.GetRegisterValue('a', LValue, -1));
  Assert.AreEqual('1.5', string(LValue));
  Assert.IsTrue(LThread.Interpreter.GetRegisterValue('v', LValue, -1));
  Assert.AreEqual('1,2,3', string(LValue));
  Assert.IsTrue(LThread.Interpreter.GetRegisterValue('s', LValue, -1));
  Assert.AreEqual('"text"', string(LValue));
  Assert.IsTrue(LThread.Interpreter.GetRegisterValue('b', LValue, -1));
  Assert.AreEqual('1', string(LValue));
  Assert.IsFalse(LThread.Interpreter.GetRegisterValue('nothing', LValue, -1));
  Assert.AreEqual('', string(LValue));
  // a scope depth with no function
  Assert.IsFalse(LThread.Interpreter.GetRegisterValue('a', LValue, 0));
  Assert.IsFalse(LThread.Interpreter.GetRegisterValue('a', LValue, DS_MAX_STACK_DEPTH + 5));
  Assert.IsFalse(LThread.Interpreter.GetRegisterValue('a', LValue, -7));
end;

procedure TTestDoomScriptInterpreter.DovrebbeNonLeggereUnCampoCheNellOriginaleEUnAccessoIndefinito;
var
  LThread: TDoomScriptThread;
  LValue: AnsiString;
begin
  // idInterpreter::GetRegisterValue takes the entity number on the stack for a pointer to the object when
  // the name is a field: undefined in the original, "not found" here. The other names of the object and of
  // the global namespace are found from a method.
  FRig.Compile(
    'float shared = 2.5;'#10 +
    'object thing { float x; void hold(); };'#10 +
    'void thing::hold() { float inner = 4; x = 3; sys.pause(); }'#10);
  FRig.AddEntity(4, 'four');
  Assert.IsTrue(FRig.Machine.Entities.ObjectOf(4).SetType('thing'));
  LThread := FRig.Machine.CreateObjectThread(4, FRig.Machine.Entities.ObjectOf(4).GetFunction('hold'));
  Assert.AreEqual('four', string(LThread.GetThreadName));
  Assert.IsFalse(LThread.Start);
  Assert.IsTrue(LThread.Interpreter.GetRegisterValue('inner', LValue, -1));
  Assert.AreEqual('4', string(LValue));
  Assert.IsTrue(LThread.Interpreter.GetRegisterValue('shared', LValue, -1));
  Assert.AreEqual('2.5', string(LValue));
  Assert.IsFalse(LThread.Interpreter.GetRegisterValue('x', LValue, -1));
  Assert.IsFalse(LThread.Interpreter.GetRegisterValue('nothing', LValue, -1));
end;

procedure TTestDoomScriptInterpreter.DovrebbeScrivereIFloatComeIlPercentoGDelC;
var
  LThread: TDoomScriptThread;
  LValue: AnsiString;

  procedure Check(const AName: AnsiString; const AExpected: string);
  begin
    Assert.IsTrue(LThread.Interpreter.GetRegisterValue(AName, LValue, -1), string(AName));
    Assert.AreEqual(AExpected, string(LValue), string(AName));
  end;

begin
  FRig.Compile(
    'void main() {'#10 +
    '  float zero = 0; float small = 0.0000001; float big = 12345678; float huge = 1e30; float third = 1; float neg;'#10 +
    '  float inf; float tiny = 0.00012345; float round = 123456;'#10 +
    '  third = third / 3; neg = -2.5; inf = huge * huge;'#10 +
    '  sys.pause();'#10 +
    '}'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsFalse(LThread.Start);
  Check('zero', '0');
  Check('small', '1e-07');
  Check('big', '1.23457e+07');
  Check('huge', '1e+30');
  Check('third', '0.333333');
  Check('neg', '-2.5');
  Check('inf', 'inf');
  Check('tiny', '0.00012345');
  Check('round', '123456');
end;

procedure TTestDoomScriptInterpreter.DovrebbeMostrareUnThreadSenzaPila;
var
  LThread: TDoomScriptThread;
begin
  LThread := FRig.Machine.CreateThread;
  LThread.DisplayInfo;
  Assert.Contains(FRig.Printed, '  Call Stack: <NO STACK>'#10);
  Assert.Contains(FRig.Printed, ' Stack depth: 0 bytes, 0 max'#10);
  LThread.Interpreter.StackTrace;
  Assert.AreEqual(0, LThread.Interpreter.CurrentLine);
  Assert.AreEqual('', string(LThread.Interpreter.CurrentFile));
  Assert.AreSame(LThread, LThread.Interpreter.GetThread);
  // an error and a warning outside the program have no file and line
  TDoomScriptTestSupport.ExpectError(procedure begin LThread.Error('boom'); end, EDoomScriptError,
    Format('Thread ''%s'': boom'#10, [string(LThread.GetThreadName)]));
  LThread.Warning('careful');
  Assert.Contains(FRig.Warnings, Format('Thread ''%s'' : careful', [string(LThread.GetThreadName)]));
  TDoomScriptTestSupport.ExpectClass(procedure begin LThread.Interpreter.GetCallFrame(DS_MAX_STACK_DEPTH); end,
    EDoomScriptMemoryError);
  TDoomScriptTestSupport.ExpectClass(procedure begin LThread.Interpreter.GetCallFrame(-1); end,
    EDoomScriptMemoryError);
end;

procedure TTestDoomScriptInterpreter.DovrebbeRifiutareUnEventoSuPiuFotogrammiSenzaLaSuaEntita;
var
  LThread: TDoomScriptThread;
  LEntity: TDoomScriptEventTarget;
  LEvent: TDoomScriptEventDef;
begin
  LEntity := FRig.AddEntity(2, 'two');
  LEvent := FRig.Machine.Events.FindEvent('ping');
  LThread := FRig.Machine.CreateThread;
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      LThread.Interpreter.BeginMultiFrameEvent(LEntity, LEvent);
    end, EDoomScriptError);
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      LThread.Interpreter.EndMultiFrameEvent(LEntity, LEvent);
    end, EDoomScriptError);
  // without a current thread the host cannot begin or end one
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      TDoomScriptThread.BeginMultiFrameEvent(FRig.Machine.Context, LEntity, LEvent);
    end, EDoomScriptError);
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      TDoomScriptThread.EndMultiFrameEvent(FRig.Machine.Context, LEntity, LEvent);
    end, EDoomScriptError);
  Assert.IsFalse(LThread.Interpreter.MultiFrameEventInProgress);
end;

procedure TTestDoomScriptInterpreter.DovrebbeTerminareIlThreadPerUnEntitaNullaInUnArgomentoObbligatorio;
var
  LThread: TDoomScriptThread;
begin
  // kept from the original: a NULL entity for an 'e' argument ends the thread with a warning
  FRig.Compile('void main() { entity none; sys.waitFor( none ); sys.print( "never" ); }'#10);
  LThread := FRig.Machine.CreateThread(FRig.FindFunction('main'));
  Assert.IsTrue(LThread.Start);
  Assert.IsTrue(LThread.IsDying);
  Assert.Contains(FRig.Warnings, 'Entity not found for event ''waitFor''. Terminating thread.');
  Assert.IsFalse(FRig.Printed.Contains('never'));
  Assert.AreEqual(0, LThread.Interpreter.LocalStackUsed - FRig.FindFunction('main').Locals);
end;

procedure TTestDoomScriptInterpreter.DovrebbeDareUnValoreSicuroSeLEntitaNonRispondeAllEvento;
begin
  FRig.AddEntity(1, 'one');
  FRig.Compile(
    'scriptEvent float getTime();'#10 +
    'void main() {'#10 +
    '  entity none; float a = 7;'#10 +
    '  a = none.twice( 4 ); sys.print( "null " + a );'#10 +
    '  a = 7; a = $one.getTime(); sys.print( " deaf " + a );'#10 +
    '  a = $one.twice( 4 ); sys.print( " ok " + a );'#10 +
    '}'#10);
  FRig.Host.DeveloperOn := True;
  Assert.IsTrue(FRig.Run('main'));
  Assert.Contains(FRig.Printed, 'null 0 deaf 0 ok 8');
  // in developer mode an entity that does not know the event gives a warning; a NULL entity does not
  Assert.Contains(FRig.Warnings, 'Function ''getTime'' not supported on entity ''one''');
  Assert.IsFalse(FRig.Warnings.Contains('twice'));
end;

procedure TTestDoomScriptInterpreter.DovrebbeTracciareLeChiamateConIlDebug;
var
  LThread: TDoomScriptThread;
begin
  FRig.Compile('void inner() { }'#10'void main() { inner(); }'#10);
  LThread := FRig.Machine.CreateThread;
  LThread.EnableDebugInfo;
  LThread.CallFunction(FRig.FindFunction('main'), True);
  Assert.IsTrue(LThread.Execute);
  Assert.Contains(FRig.Printed, '0: call ''main'' clear stack'#10);
  Assert.Contains(FRig.Printed, '0: call ''inner'' from ''main''(line 2)'#10);
  Assert.Contains(FRig.Printed, 'exit inner return to main(line 2)'#10);
  Assert.Contains(FRig.Printed, 'exit main done'#10);
  LThread.DisableDebugInfo;
  Assert.IsFalse(LThread.Interpreter.Debug);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptInterpreter);

end.
