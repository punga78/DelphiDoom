{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - registers, evaluator, interpolator   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Registers;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiRegisters = class
  public
    [Test]
    procedure UnRegistroVec4VaEVieneDaiRegistri;
    [Test]
    procedure UnRegistroRettangoloVec2Vec3;
    [Test]
    procedure UnRegistroFloatIntBool;
    [Test]
    procedure UnIntFuoriIntervalloVaAlMinimo;
    [Test]
    procedure UnRegistroDisabilitatoONonPilotatoNonFaNulla;
    [Test]
    procedure UnRegistroDiStringaAbilitatoEUnErrore;
    [Test]
    procedure CopyRegsCopiaGliIndici;
    [Test]
    procedure LaListaCreaRegistriDaCostantiESenzaDuplicati;
    [Test]
    procedure LaListaTrovaSenzaMaiuscoleESiSvuota;
    [Test]
    procedure LaListaCopiaIRegistriNelleVariabili;
    [Test]
    procedure ILaValutatoreFaLeOperazioniAritmetiche;
    [Test]
    procedure IlValutatoreFaIConfrontiELaLogica;
    [Test]
    procedure IlValutatoreLeggeLeVariabili;
    [Test]
    procedure IlValutatoreLeggeUnComponenteDiUnVec4;
    [Test]
    procedure IlValutatoreUsaLeTabelle;
    [Test]
    procedure IlValutatoreSaltaLeOperazioniDaRisolvere;
    [Test]
    procedure LaStoreSiSvuotaEDaLoStessoRegistroPerLeCostanti;
    [Test]
    procedure ILimitiDiOperazioniETemporaneiDannoUnAvviso;
    [Test]
    procedure InterpolatorePrimaDellInizioDaIlValoreIniziale;
    [Test]
    procedure InterpolatoreSoloDecelerazione;
    [Test]
    procedure InterpolatoreConAccelerazioneEccessivaLaScala;
    [Test]
    procedure InterpolatoreRicalcolaLaFaseEIlValoreCorrente;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Scanner.IdDict, DelphiDoom.Scanner.IdParser,
  DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Interpolator, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.WinVar.Base,
  DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Int, DelphiDoom.Gui.WinVar.Float, DelphiDoom.Gui.WinVar.Str,
  DelphiDoom.Gui.WinVar.Vec2, DelphiDoom.Gui.WinVar.Vec3, DelphiDoom.Gui.WinVar.Vec4,
  DelphiDoom.Gui.WinVar.Rectangle, DelphiDoom.Gui.Regs.Types, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.Regs.Register,
  DelphiDoom.Gui.Regs.RegisterList, DelphiDoom.Gui.Regs.Store, DelphiDoom.Gui.Regs.Evaluator,
  DelphiDoom.Tests.Gui.WindowFakes;

type
  /// <summary>A register owner that gives a new constant register for each constant</summary>
  TFakeOwner = class(TInterfacedObject, IGuiRegisterOwner)
  strict private
    FNext: Integer;
  public
    function ParseExpression(const ASource: TIdParser): Integer;
    function ExpressionConstant(const AValue: Single): Integer;
    procedure InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
    function TranslateString(const AText: AnsiString): AnsiString;
  end;

function TFakeOwner.ParseExpression(const ASource: TIdParser): Integer;
begin
  Result := 0;
end;

function TFakeOwner.ExpressionConstant(const AValue: Single): Integer;
begin
  Inc(FNext);
  Result := FNext;
end;

procedure TFakeOwner.InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
begin
end;

function TFakeOwner.TranslateString(const AText: AnsiString): AnsiString;
begin
  Result := AText;
end;

function MakeRegister(const AType: TGuiRegisterType; const AVariable: TGuiWinVar): TGuiRegister;
var
  LIndex: Integer;
begin
  Result := TGuiRegister.Create('r', AType);
  Result.Variable := AVariable;
  for LIndex := 0 to 3 do
    Result.Regs[LIndex] := 10 + LIndex;
end;

procedure TTestGuiRegisters.UnRegistroVec4VaEVieneDaiRegistri;
var
  LVar: TGuiWinVec4;
  LRegister: TGuiRegister;
  LRegisters: TGuiRegisters;
begin
  LVar := TGuiWinVec4.Create;
  LRegister := MakeRegister(rtVec4, LVar);
  try
    LVar.Value := TIdVec4.Create(1, 2, 3, 4);
    LRegister.SetToRegs(LRegisters);
    Assert.AreEqual(Single(1.0), LRegisters[10]);
    Assert.AreEqual(Single(4.0), LRegisters[13]);
    LRegisters[12] := 9;
    LRegister.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(9.0), LVar.Value.Z);
    Assert.AreEqual(4, LRegister.RegCount);
    Assert.AreEqual(Word(11), LRegister.Regs[1]);
  finally
    LRegister.Free;
    LVar.Free;
  end;
end;

procedure TTestGuiRegisters.UnRegistroRettangoloVec2Vec3;
var
  LRect: TGuiWinRectangle;
  LVec2: TGuiWinVec2;
  LVec3: TGuiWinVec3;
  LRegisterRect: TGuiRegister;
  LRegisterVec2: TGuiRegister;
  LRegisterVec3: TGuiRegister;
  LRegisters: TGuiRegisters;
begin
  LRect := TGuiWinRectangle.Create;
  LVec2 := TGuiWinVec2.Create;
  LVec3 := TGuiWinVec3.Create;
  LRegisterRect := MakeRegister(rtRectangle, LRect);
  LRegisterVec2 := MakeRegister(rtVec2, LVec2);
  LRegisterVec3 := MakeRegister(rtVec3, LVec3);
  try
    LRect.Value := TGuiRectangle.Create(1, 2, 3, 4);
    LRegisterRect.SetToRegs(LRegisters);
    Assert.AreEqual(Single(3.0), LRegisters[12]);
    LRegisters[13] := 40;
    LRegisterRect.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(40.0), LRect.Value.H);
    LVec2.Value := TIdVec2.Create(5, 6);
    LRegisterVec2.SetToRegs(LRegisters);
    Assert.AreEqual(Single(6.0), LRegisters[11]);
    LRegisters[10] := 50;
    LRegisterVec2.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(50.0), LVec2.Value.X);
    LVec3.Value := TIdVec3.Create(7, 8, 9);
    LRegisterVec3.SetToRegs(LRegisters);
    Assert.AreEqual(Single(9.0), LRegisters[12]);
    LRegisters[11] := 80;
    LRegisterVec3.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(80.0), LVec3.Value.Y);
  finally
    LRegisterVec3.Free;
    LRegisterVec2.Free;
    LRegisterRect.Free;
    LVec3.Free;
    LVec2.Free;
    LRect.Free;
  end;
end;

procedure TTestGuiRegisters.UnRegistroFloatIntBool;
var
  LFloat: TGuiWinFloat;
  LInt: TGuiWinInt;
  LBool: TGuiWinBool;
  LRegisterFloat: TGuiRegister;
  LRegisterInt: TGuiRegister;
  LRegisterBool: TGuiRegister;
  LRegisters: TGuiRegisters;
begin
  LFloat := TGuiWinFloat.Create;
  LInt := TGuiWinInt.Create;
  LBool := TGuiWinBool.Create;
  LRegisterFloat := MakeRegister(rtFloat, LFloat);
  LRegisterInt := MakeRegister(rtInt, LInt);
  LRegisterBool := MakeRegister(rtBool, LBool);
  try
    LFloat.Value := 2.5;
    LInt.Value := 7;
    LBool.Value := True;
    LRegisterFloat.SetToRegs(LRegisters);
    Assert.AreEqual(Single(2.5), LRegisters[10]);
    LRegisterInt.SetToRegs(LRegisters);
    Assert.AreEqual(Single(7.0), LRegisters[10]);
    LRegisterBool.SetToRegs(LRegisters);
    Assert.AreEqual(Single(1.0), LRegisters[10]);
    LRegisters[10] := 3.9;
    LRegisterInt.GetFromRegs(LRegisters);
    Assert.AreEqual(3, LInt.Value);
    LRegisters[10] := -3.9;
    LRegisterInt.GetFromRegs(LRegisters);
    Assert.AreEqual(-3, LInt.Value);
    LRegisterFloat.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(-3.9), LFloat.Value);
    LRegisters[10] := 0;
    LRegisterBool.GetFromRegs(LRegisters);
    Assert.IsFalse(LBool.Value);
    LRegisters[10] := 0.1;
    LRegisterBool.GetFromRegs(LRegisters);
    Assert.IsTrue(LBool.Value);
  finally
    LRegisterBool.Free;
    LRegisterInt.Free;
    LRegisterFloat.Free;
    LBool.Free;
    LInt.Free;
    LFloat.Free;
  end;
end;

procedure TTestGuiRegisters.UnIntFuoriIntervalloVaAlMinimo;
var
  LInt: TGuiWinInt;
  LRegister: TGuiRegister;
  LRegisters: TGuiRegisters;
begin
  LInt := TGuiWinInt.Create;
  LRegister := MakeRegister(rtInt, LInt);
  try
    LRegisters[10] := 3.0E9;
    LRegister.GetFromRegs(LRegisters);
    Assert.AreEqual(Low(Integer), LInt.Value);
  finally
    LRegister.Free;
    LInt.Free;
  end;
end;

procedure TTestGuiRegisters.UnRegistroDisabilitatoONonPilotatoNonFaNulla;
var
  LFloat: TGuiWinFloat;
  LRegister: TGuiRegister;
  LRegisters: TGuiRegisters;
  LDict: TIdDict;
begin
  LDict := TIdDict.Create;
  LFloat := TGuiWinFloat.Create;
  LRegister := MakeRegister(rtFloat, LFloat);
  try
    LFloat.Value := 5;
    LRegisters[10] := 1;
    LRegister.Enabled := False;
    LRegister.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(5.0), LFloat.Value);
    LRegister.Enabled := True;
    LFloat.Eval := False;
    LRegister.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(5.0), LFloat.Value);
    LFloat.Eval := True;
    LFloat.Init('gui::x', LDict);
    LRegisters[10] := 99;
    LRegister.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(0.0), LFloat.Value);
    LRegister.Variable := nil;
    LRegister.GetFromRegs(LRegisters);
    LRegister.SetToRegs(LRegisters);
  finally
    LRegister.Free;
    LFloat.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiRegisters.UnRegistroDiStringaAbilitatoEUnErrore;
var
  LString: TGuiWinStr;
  LRegister: TGuiRegister;
  LRegisters: TGuiRegisters;
begin
  LString := TGuiWinStr.Create;
  LRegister := MakeRegister(rtString, LString);
  try
    Assert.IsFalse(LRegister.Enabled);
    LRegister.Enabled := True;
    Assert.WillRaise(
      procedure
      begin
        LRegister.SetToRegs(LRegisters);
      end, EGuiWindowException);
    Assert.WillRaise(
      procedure
      begin
        LRegister.GetFromRegs(LRegisters);
      end, EGuiWindowException);
  finally
    LRegister.Free;
    LString.Free;
  end;
end;

procedure TTestGuiRegisters.CopyRegsCopiaGliIndici;
var
  LSource: TGuiRegister;
  LTarget: TGuiRegister;
begin
  LSource := MakeRegister(rtVec4, nil);
  LTarget := TGuiRegister.Create('t', rtVec4);
  try
    LTarget.CopyRegs(LSource);
    Assert.AreEqual(Word(13), LTarget.Regs[3]);
    Assert.AreEqual('t', string(LTarget.Name));
    Assert.IsTrue(LTarget.RegisterType = rtVec4);
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestGuiRegisters.LaListaCreaRegistriDaCostantiESenzaDuplicati;
var
  LList: TGuiRegisterList;
  LOwner: IGuiRegisterOwner;
  LVar: TGuiWinVec4;
begin
  LList := TGuiRegisterList.Create;
  LVar := TGuiWinVec4.Create;
  try
    LOwner := TFakeOwner.Create;
    LList.AddReg('Color', rtVec4, TIdVec4.Create(1, 2, 3, 4), LOwner, LVar);
    LList.AddReg('color', rtVec4, TIdVec4.Create(9, 9, 9, 9), LOwner, LVar);
    Assert.AreEqual(1, LList.Count);
    Assert.AreEqual(Word(4), LList[0].Regs[3]);
    Assert.IsTrue(LList[0].Variable = LVar);
  finally
    LVar.Free;
    LList.Free;
  end;
end;

procedure TTestGuiRegisters.LaListaTrovaSenzaMaiuscoleESiSvuota;
var
  LList: TGuiRegisterList;
  LOwner: IGuiRegisterOwner;
begin
  LList := TGuiRegisterList.Create;
  try
    LOwner := TFakeOwner.Create;
    LList.AddReg('Rect', rtRectangle, TIdVec4.Create(1, 2, 3, 4), LOwner, nil);
    Assert.IsNotNull(LList.FindReg('RECT'));
    Assert.IsNull(LList.FindReg('other'));
    LList.Reset;
    Assert.AreEqual(0, LList.Count);
    Assert.IsNull(LList.FindReg('rect'));
  finally
    LList.Free;
  end;
end;

procedure TTestGuiRegisters.LaListaCopiaIRegistriNelleVariabili;
var
  LList: TGuiRegisterList;
  LOwner: IGuiRegisterOwner;
  LFloat: TGuiWinFloat;
  LRegisters: TGuiRegisters;
begin
  LList := TGuiRegisterList.Create;
  LFloat := TGuiWinFloat.Create;
  try
    LOwner := TFakeOwner.Create;
    LList.AddReg('f', rtFloat, TIdVec4.Create(1, 0, 0, 0), LOwner, LFloat);
    LFloat.Value := 6;
    LList.SetToRegs(LRegisters);
    Assert.AreEqual(Single(6.0), LRegisters[1]);
    LRegisters[1] := 8;
    LList.GetFromRegs(LRegisters);
    Assert.AreEqual(Single(8.0), LFloat.Value);
  finally
    LFloat.Free;
    LList.Free;
  end;
end;

type
  TOpCase = record
    OpType: TGuiOpType;
    Expected: Single;
  end;

procedure TTestGuiRegisters.ILaValutatoreFaLeOperazioniAritmetiche;
const
  CASES: array[0..4] of TOpCase = ((OpType: otAdd; Expected: 10), (OpType: otSubtract; Expected: 2),
    (OpType: otMultiply; Expected: 24), (OpType: otDivide; Expected: 1.5), (OpType: otMod; Expected: 2));
var
  LStore: TGuiExpressionStore;
  LEvaluator: TGuiExpressionEvaluator;
  LRegisters: TGuiRegisters;
  LA: Integer;
  LB: Integer;
  LResults: array[0..4] of Integer;
  LIndex: Integer;
begin
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  LEvaluator := TGuiExpressionEvaluator.Create(nil, nil);
  try
    LA := LStore.ExpressionConstant(6);
    LB := LStore.ExpressionConstant(4);
    for LIndex := 0 to High(CASES) do
      LResults[LIndex] := LStore.EmitOp(LA, LB, CASES[LIndex].OpType);
    LEvaluator.Evaluate(LStore, 0, LRegisters, 'w', 't.gui');
    for LIndex := 0 to High(CASES) do
      Assert.AreEqual(CASES[LIndex].Expected, LRegisters[LResults[LIndex]]);
  finally
    LEvaluator.Free;
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.IlValutatoreFaIConfrontiELaLogica;
const
  CASES: array[0..7] of TOpCase = ((OpType: otGt; Expected: 1), (OpType: otGe; Expected: 1),
    (OpType: otLt; Expected: 0), (OpType: otLe; Expected: 0), (OpType: otEq; Expected: 0),
    (OpType: otNe; Expected: 1), (OpType: otAnd; Expected: 0), (OpType: otOr; Expected: 1));
var
  LStore: TGuiExpressionStore;
  LEvaluator: TGuiExpressionEvaluator;
  LRegisters: TGuiRegisters;
  LA: Integer;
  LB: Integer;
  LZero: Integer;
  LResults: array[0..7] of Integer;
  LCondition: Integer;
  LOpIndex: Integer;
  LOp: TGuiOp;
  LIndex: Integer;
begin
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  LEvaluator := TGuiExpressionEvaluator.Create(nil, nil);
  try
    LA := LStore.ExpressionConstant(6);
    LB := LStore.ExpressionConstant(4);
    LZero := LStore.ExpressionConstant(0);
    for LIndex := 0 to 5 do
      LResults[LIndex] := LStore.EmitOp(LA, LB, CASES[LIndex].OpType);
    // and, or: 6 && 0, 6 || 0
    LResults[6] := LStore.EmitOp(LA, LZero, otAnd);
    LResults[7] := LStore.EmitOp(LA, LZero, otOr);
    LCondition := LStore.EmitOp(LZero, LB, otCond, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.D := LA;
    LStore.Ops[LOpIndex] := LOp;
    LEvaluator.Evaluate(LStore, 0, LRegisters, 'w', 't.gui');
    for LIndex := 0 to 7 do
      Assert.AreEqual(CASES[LIndex].Expected, LRegisters[LResults[LIndex]]);
    // the condition is 0: the else register
    Assert.AreEqual(Single(6.0), LRegisters[LCondition]);
  finally
    LEvaluator.Free;
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.IlValutatoreLeggeLeVariabili;
var
  LStore: TGuiExpressionStore;
  LEvaluator: TGuiExpressionEvaluator;
  LRegisters: TGuiRegisters;
  LFloat: TGuiWinFloat;
  LInt: TGuiWinInt;
  LBool: TGuiWinBool;
  LString: TGuiWinStr;
  LResults: array[0..4] of Integer;
  LOpIndex: Integer;
  LOp: TGuiOp;
begin
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  LEvaluator := TGuiExpressionEvaluator.Create(nil, nil);
  LFloat := TGuiWinFloat.Create;
  LInt := TGuiWinInt.Create;
  LBool := TGuiWinBool.Create;
  LString := TGuiWinStr.Create;
  try
    LFloat.Value := 1.5;
    LInt.Value := 3;
    LBool.Value := True;
    LString.Value := '2.5';
    LResults[0] := LStore.EmitOp(0, -1, otVarf, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.Variable := LFloat;
    LStore.Ops[LOpIndex] := LOp;
    LResults[1] := LStore.EmitOp(0, -1, otVari, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.Variable := LInt;
    LStore.Ops[LOpIndex] := LOp;
    LResults[2] := LStore.EmitOp(0, -1, otVarb, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.Variable := LBool;
    LStore.Ops[LOpIndex] := LOp;
    LResults[3] := LStore.EmitOp(0, -1, otVars, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.Variable := LString;
    LStore.Ops[LOpIndex] := LOp;
    // a variable that is not there reads 0
    LResults[4] := LStore.EmitOp(0, -1, otVarf, LOpIndex);
    LEvaluator.Evaluate(LStore, 0, LRegisters, 'w', 't.gui');
    Assert.AreEqual(Single(1.5), LRegisters[LResults[0]]);
    Assert.AreEqual(Single(3.0), LRegisters[LResults[1]]);
    Assert.AreEqual(Single(1.0), LRegisters[LResults[2]]);
    Assert.AreEqual(Single(2.5), LRegisters[LResults[3]]);
    Assert.AreEqual(Single(0.0), LRegisters[LResults[4]]);
  finally
    LString.Free;
    LBool.Free;
    LInt.Free;
    LFloat.Free;
    LEvaluator.Free;
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.IlValutatoreLeggeUnComponenteDiUnVec4;
var
  LStore: TGuiExpressionStore;
  LEvaluator: TGuiExpressionEvaluator;
  LRegisters: TGuiRegisters;
  LVec: TGuiWinVec4;
  LIndexRegister: Integer;
  LByIndex: Integer;
  LWhole: Integer;
  LNone: Integer;
  LOpIndex: Integer;
  LOp: TGuiOp;
begin
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  LEvaluator := TGuiExpressionEvaluator.Create(nil, nil);
  LVec := TGuiWinVec4.Create;
  try
    LVec.Value := TIdVec4.Create(10, 20, 30, 40);
    LIndexRegister := LStore.ExpressionConstant(2);
    LByIndex := LStore.EmitOp(0, LIndexRegister, otVar, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.Variable := LVec;
    LStore.Ops[LOpIndex] := LOp;
    // B -1: x() of the variable
    LWhole := LStore.EmitOp(0, -1, otVar, LOpIndex);
    LOp := LStore.Ops[LOpIndex];
    LOp.Variable := LVec;
    LStore.Ops[LOpIndex] := LOp;
    // no variable: 0
    LNone := LStore.EmitOp(0, -1, otVar, LOpIndex);
    LEvaluator.Evaluate(LStore, 0, LRegisters, 'w', 't.gui');
    Assert.AreEqual(Single(30.0), LRegisters[LByIndex]);
    Assert.AreEqual(Single(10.0), LRegisters[LWhole]);
    Assert.AreEqual(Single(0.0), LRegisters[LNone]);
  finally
    LVec.Free;
    LEvaluator.Free;
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.IlValutatoreUsaLeTabelle;
var
  LStore: TGuiExpressionStore;
  LEvaluator: TGuiExpressionEvaluator;
  LEmpty: TGuiExpressionEvaluator;
  LRegisters: TGuiRegisters;
  LIndexRegister: Integer;
  LResult: Integer;
  LValues: TArray<Single>;
begin
  SetLength(LValues, 3);
  LValues[0] := 10;
  LValues[1] := 20;
  LValues[2] := 30;
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  LEvaluator := TGuiExpressionEvaluator.Create(TGuiWindowFakeTables.Create('t', LValues), nil);
  LEmpty := TGuiExpressionEvaluator.Create(nil, nil);
  try
    LIndexRegister := LStore.ExpressionConstant(1);
    LResult := LStore.EmitOp(7, LIndexRegister, otTable);
    LEvaluator.Evaluate(LStore, 0, LRegisters, 'w', 't.gui');
    Assert.AreEqual(Single(20.0), LRegisters[LResult]);
    LEmpty.Evaluate(LStore, 0, LRegisters, 'w', 't.gui');
    Assert.AreEqual(Single(0.0), LRegisters[LResult]);
  finally
    LEmpty.Free;
    LEvaluator.Free;
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.IlValutatoreSaltaLeOperazioniDaRisolvere;
var
  LStore: TGuiExpressionStore;
  LEvaluator: TGuiExpressionEvaluator;
  LRegisters: TGuiRegisters;
  LResult: Integer;
begin
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  LEvaluator := TGuiExpressionEvaluator.Create(nil, nil);
  try
    LStore.ExpressionConstant(5);
    LResult := LStore.EmitOp(0, -2, otVar);
    LRegisters[LResult] := 77;
    LEvaluator.Evaluate(LStore, 160, LRegisters, 'w', 't.gui');
    // the operation is not run: the temporaries are cleared at the start, but this one is not touched after
    Assert.AreEqual(Single(0.0), LRegisters[LResult]);
    Assert.AreEqual(Single(160.0), LRegisters[WEXP_REG_TIME]);
  finally
    LEvaluator.Free;
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.LaStoreSiSvuotaEDaLoStessoRegistroPerLeCostanti;
var
  LStore: TGuiExpressionStore;
begin
  LStore := TGuiExpressionStore.Create('t.gui', nil);
  try
    Assert.AreEqual(1, LStore.ExpressionConstant(5));
    Assert.AreEqual(1, LStore.ExpressionConstant(5));
    Assert.AreEqual(2, LStore.ExpressionConstant(6));
    Assert.IsFalse(LStore.RegisterIsTemporary(1));
    Assert.AreEqual(3, LStore.ExpressionTemporary);
    Assert.IsTrue(LStore.RegisterIsTemporary(3));
    // a temporary is not shared with a constant that has the same value
    Assert.AreEqual(4, LStore.ExpressionConstant(0));
    LStore.Clear;
    Assert.AreEqual(0, LStore.RegisterCount);
    Assert.AreEqual(0, LStore.OpCount);
  finally
    LStore.Free;
  end;
end;

procedure TTestGuiRegisters.ILimitiDiOperazioniETemporaneiDannoUnAvviso;
var
  LStore: TGuiExpressionStore;
  LLines: TStringList;
  LIndex: Integer;
  LOpIndex: Integer;
begin
  LLines := TStringList.Create;
  LStore := TGuiExpressionStore.Create('ops.gui', TGuiWindowFakeLog.Create(LLines));
  try
    LStore.ExpressionConstant(1);
    for LIndex := 1 to GUI_MAX_EXPRESSION_OPS + 2 do
      LStore.EmitOp(1, 1, otAdd, LOpIndex);
    Assert.AreEqual(GUI_MAX_EXPRESSION_OPS, LStore.OpCount);
    Assert.AreEqual(GUI_MAX_EXPRESSION_REGISTERS, LStore.RegisterCount);
    // a temporary at the limit: a warning and register 0
    Assert.AreEqual(0, LStore.ExpressionTemporary);
    Assert.IsTrue(LLines.IndexOf('W: expressionOp: gui ops.gui hit MAX_EXPRESSION_OPS') >= 0);
    Assert.IsTrue(LLines.IndexOf('W: expressionTemporary: gui ops.gui hit MAX_EXPRESSION_REGISTERS') >= 0);
  finally
    LStore.Free;
    LLines.Free;
  end;
end;

procedure TTestGuiRegisters.InterpolatorePrimaDellInizioDaIlValoreIniziale;
var
  LInterpolator: TGuiInterpolator;
begin
  LInterpolator := TGuiInterpolator.Create;
  try
    LInterpolator.Init(100, 0, 0, 1000, TIdVec4.Create(5, 0, 0, 0), TIdVec4.Create(15, 0, 0, 0));
    Assert.AreEqual(Single(5.0), LInterpolator.GetCurrentValue(50).X);
    Assert.AreEqual(Single(5.0), LInterpolator.StartValue.X);
    // the same time again: the value of the last call
    Assert.AreEqual(Double(10.0), Double(LInterpolator.GetCurrentValue(600).X), 0.01);
    Assert.AreEqual(Double(10.0), Double(LInterpolator.GetCurrentValue(600).X), 0.01);
  finally
    LInterpolator.Free;
  end;
end;

procedure TTestGuiRegisters.InterpolatoreSoloDecelerazione;
var
  LInterpolator: TGuiInterpolator;
begin
  LInterpolator := TGuiInterpolator.Create;
  try
    LInterpolator.Init(0, 0, 1000, 1000, TIdVec4.Create(0, 0, 0, 0), TIdVec4.Create(100, 0, 0, 0));
    Assert.AreEqual(Double(75.0), Double(LInterpolator.GetCurrentValue(500).X), 0.01);
    Assert.AreEqual(Double(100.0), Double(LInterpolator.GetCurrentValue(1000).X), 0.01);
  finally
    LInterpolator.Free;
  end;
end;

procedure TTestGuiRegisters.InterpolatoreConAccelerazioneEccessivaLaScala;
var
  LInterpolator: TGuiInterpolator;
begin
  LInterpolator := TGuiInterpolator.Create;
  try
    // 800 + 800 > 1000: both become 500
    LInterpolator.Init(0, 800, 800, 1000, TIdVec4.Create(0, 0, 0, 0), TIdVec4.Create(100, 0, 0, 0));
    Assert.AreEqual(Double(50.0), Double(LInterpolator.GetCurrentValue(500).X), 0.01);
    Assert.IsFalse(LInterpolator.IsDone(999));
    Assert.IsTrue(LInterpolator.IsDone(1000));
  finally
    LInterpolator.Free;
  end;
end;

procedure TTestGuiRegisters.InterpolatoreRicalcolaLaFaseEIlValoreCorrente;
var
  LInterpolator: TGuiInterpolator;
begin
  LInterpolator := TGuiInterpolator.Create;
  try
    LInterpolator.Init(0, 200, 200, 1000, TIdVec4.Create(0, 0, 0, 0), TIdVec4.Create(100, 0, 0, 0));
    // going back to an earlier phase after a later one
    Assert.AreEqual(Double(100.0), Double(LInterpolator.GetCurrentValue(1000).X), 0.01);
    Assert.AreEqual(Double(3.125), Double(LInterpolator.GetCurrentValue(100).X), 0.01);
    Assert.AreEqual(Double(50.0), Double(LInterpolator.GetCurrentValue(500).X), 0.01);
  finally
    LInterpolator.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiRegisters);

end.
