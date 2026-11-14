{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - the table of opcodes    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Opcodes;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Opcodes;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptOpcodes = class
  private
    procedure CheckEntry(const AOp: Integer; const AName, AOpName: string; const APriority: Integer;
      const ARightAssociative: Boolean; const ATypeA, ATypeB, ATypeC: TDoomScriptEType);
  public
    [Test]
    procedure DovrebbeAvereUnaVocePerOgniOpcode;
    [Test]
    procedure DovrebbeAvereLeVociNoteAlLoroPosto;
    [Test]
    procedure DovrebbeConservareLeStranezzeDellOriginale;
    [Test]
    procedure DovrebbeAvereISegnapostoDeiCicliInFondo;
    [Test]
    procedure DovrebbeAvereTuttiIPushDiSeguito;
    [Test]
    procedure DovrebbeAvereLeAssegnazioniAssociativeADestra;
    [Test]
    procedure DovrebbeAvereLePrioritaDelParser;
  end;

implementation

procedure TTestDoomScriptOpcodes.CheckEntry(const AOp: Integer; const AName, AOpName: string; const APriority: Integer;
  const ARightAssociative: Boolean; const ATypeA, ATypeB, ATypeC: TDoomScriptEType);
begin
  Assert.AreEqual(AName, string(DoomScriptOpcodes[AOp].Name), AOpName + ' name');
  Assert.AreEqual(AOpName, string(DoomScriptOpcodes[AOp].OpName), AOpName + ' opname');
  Assert.AreEqual(APriority, DoomScriptOpcodes[AOp].Priority, AOpName + ' priority');
  Assert.AreEqual(ARightAssociative, DoomScriptOpcodes[AOp].RightAssociative, AOpName + ' associativity');
  Assert.IsTrue(DoomScriptOpcodes[AOp].TypeA = ATypeA, AOpName + ' a');
  Assert.IsTrue(DoomScriptOpcodes[AOp].TypeB = ATypeB, AOpName + ' b');
  Assert.IsTrue(DoomScriptOpcodes[AOp].TypeC = ATypeC, AOpName + ' c');
end;

procedure TTestDoomScriptOpcodes.DovrebbeAvereUnaVocePerOgniOpcode;
var
  LIndex: Integer;
begin
  Assert.AreEqual(123, NUM_OPCODES);
  Assert.AreEqual<Integer>(NUM_OPCODES, Length(DoomScriptOpcodes));
  Assert.AreEqual(0, Low(DoomScriptOpcodes));
  for LIndex := 0 to NUM_OPCODES - 1 do
  begin
    Assert.IsTrue(DoomScriptOpcodes[LIndex].Name <> '', Format('name of %d', [LIndex]));
    Assert.IsTrue(DoomScriptOpcodes[LIndex].OpName <> '', Format('opname of %d', [LIndex]));
  end;
end;

procedure TTestDoomScriptOpcodes.DovrebbeAvereLeVociNoteAlLoroPosto;
begin
  CheckEntry(OP_RETURN, '<RETURN>', 'RETURN', -1, False, evVoid, evVoid, evVoid);
  CheckEntry(OP_UINC_F, '++', 'UINC_F', 1, True, evFloat, evVoid, evVoid);
  CheckEntry(OP_MUL_FV, '*', 'MUL_FV', 3, False, evFloat, evVector, evVector);
  CheckEntry(OP_MOD_F, '%', 'MOD_F', 3, False, evFloat, evFloat, evFloat);
  CheckEntry(OP_ADD_SV, '+', 'ADD_SV', 4, False, evString, evVector, evString);
  CheckEntry(OP_EQ_OO, '==', 'EQ_OO', 5, False, evObject, evObject, evFloat);
  CheckEntry(OP_GT, '>', 'GT', 5, False, evFloat, evFloat, evFloat);
  CheckEntry(OP_ADDRESS, '.', 'ADDRESS', 1, False, evEntity, evField, evPointer);
  CheckEntry(OP_EVENTCALL, '.', 'EVENTCALL', 2, False, evEntity, evFunction, evVoid);
  CheckEntry(OP_OBJECTCALL, '.', 'OBJECTCALL', 2, False, evObject, evFunction, evVoid);
  CheckEntry(OP_SYSCALL, '.', 'SYSCALL', 2, False, evVoid, evFunction, evVoid);
  CheckEntry(OP_STORE_F, '=', 'STORE_F', 6, True, evFloat, evFloat, evFloat);
  CheckEntry(OP_STOREP_FTOS, '<=>', 'STOREP_FTOS', 6, True, evPointer, evFloat, evString);
  CheckEntry(OP_UOR_F, '|=', 'UOR_F', 6, True, evFloat, evFloat, evVoid);
  CheckEntry(OP_INT_F, 'int', 'INT_F', -1, False, evFloat, evVoid, evFloat);
  CheckEntry(OP_IFNOT, '<IFNOT>', 'IFNOT', -1, False, evFloat, evJumpOffset, evVoid);
  CheckEntry(OP_CALL, '<CALL>', 'CALL', -1, False, evFunction, evArgSize, evVoid);
  CheckEntry(OP_OBJTHREAD, '<THREAD>', 'OBJTHREAD', -1, False, evFunction, evArgSize, evVoid);
  CheckEntry(OP_GOTO, '<GOTO>', 'GOTO', -1, False, evJumpOffset, evVoid, evVoid);
  CheckEntry(OP_OR_BOOLBOOL, '||', 'OR_BOOLBOOL', 7, False, evBoolean, evBoolean, evFloat);
  CheckEntry(OP_BITOR, '|', 'BITOR', 3, False, evFloat, evFloat, evFloat);
end;

procedure TTestDoomScriptOpcodes.DovrebbeConservareLeStranezzeDellOriginale;
begin
  // DIV_F prints as DIV
  CheckEntry(OP_DIV_F, '/', 'DIV', 3, False, evFloat, evFloat, evFloat);
  // INDIRECT_ENT prints as INDIRECT_E
  CheckEntry(OP_INDIRECT_ENT, '.', 'INDIRECT_E', 1, False, evObject, evField, evEntity);
  // two entries are called STORE_OBJENT
  CheckEntry(OP_STORE_OBJENT, '=', 'STORE_OBJENT', 6, True, evObject, evEntity, evObject);
  CheckEntry(OP_STORE_ENTOBJ, '=', 'STORE_OBJENT', 6, True, evEntity, evObject, evObject);
  // NOT_S says it takes a vector
  CheckEntry(OP_NOT_S, '!', 'NOT_S', -1, False, evVector, evVoid, evFloat);
end;

procedure TTestDoomScriptOpcodes.DovrebbeAvereISegnapostoDeiCicliInFondo;
begin
  CheckEntry(OP_BREAK, '<BREAK>', 'BREAK', -1, False, evFloat, evVoid, evVoid);
  CheckEntry(OP_CONTINUE, '<CONTINUE>', 'CONTINUE', -1, False, evFloat, evVoid, evVoid);
  Assert.AreEqual(NUM_OPCODES - 2, OP_BREAK);
  Assert.AreEqual(NUM_OPCODES - 1, OP_CONTINUE);
end;

procedure TTestDoomScriptOpcodes.DovrebbeAvereTuttiIPushDiSeguito;
var
  LIndex: Integer;
begin
  // the compiler walks from PUSH_F while the name is <PUSH>
  for LIndex := OP_PUSH_F to OP_PUSH_BTOS do
    Assert.AreEqual('<PUSH>', string(DoomScriptOpcodes[LIndex].Name), Format('opcode %d', [LIndex]));
  Assert.AreEqual(11, OP_PUSH_BTOS - OP_PUSH_F + 1);
  Assert.AreNotEqual('<PUSH>', string(DoomScriptOpcodes[OP_PUSH_F - 1].Name));
  Assert.AreNotEqual('<PUSH>', string(DoomScriptOpcodes[OP_PUSH_BTOS + 1].Name));
  CheckEntry(OP_PUSH_ENT, '<PUSH>', 'PUSH_ENT', -1, False, evEntity, evEntity, evVoid);
  CheckEntry(OP_PUSH_BTOF, '<PUSH>', 'PUSH_BTOF', -1, False, evFloat, evBoolean, evVoid);
end;

procedure TTestDoomScriptOpcodes.DovrebbeAvereLeAssegnazioniAssociativeADestra;
var
  LIndex: Integer;
begin
  for LIndex := OP_STORE_F to OP_UOR_F do
  begin
    Assert.IsTrue(DoomScriptOpcodes[LIndex].RightAssociative, Format('opcode %d', [LIndex]));
    Assert.AreEqual(6, DoomScriptOpcodes[LIndex].Priority, Format('opcode %d', [LIndex]));
  end;
  // the indirections that an assignment turns into ADDRESS come right before it
  for LIndex := OP_INDIRECT_F to OP_ADDRESS do
    Assert.AreEqual('.', string(DoomScriptOpcodes[LIndex].Name), Format('opcode %d', [LIndex]));
  Assert.AreEqual(OP_ADDRESS, OP_INDIRECT_OBJ + 1);
end;

procedure TTestDoomScriptOpcodes.DovrebbeAvereLePrioritaDelParser;
begin
  Assert.AreEqual(2, DS_FUNCTION_PRIORITY);
  Assert.AreEqual(2, DS_INT_PRIORITY);
  Assert.AreEqual(5, DS_NOT_PRIORITY);
  Assert.AreEqual(5, DS_TILDE_PRIORITY);
  Assert.AreEqual(7, DS_TOP_PRIORITY);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptOpcodes);

end.
