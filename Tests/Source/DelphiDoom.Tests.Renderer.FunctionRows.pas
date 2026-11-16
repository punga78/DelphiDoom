{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - rows of the table of drawing    }
{  functions                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.FunctionRows;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererFunctionRows: the one pass that gives the variables of the renderer their functions (issue #247)
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererFunctionRows = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlValoreSoloAlLivelloEAllaCombinazioneGiusti;
    [Test]
    procedure DovrebbeLasciareLeVariabiliChePerQuelLivelloNonHannoRighe;
    [Test]
    procedure DovrebbeDareNilQuandoLaRigaDiceNil;
    [Test]
    procedure DovrebbeDareLUltimoValoreDelleRigheDiUnaStessaVariabile;
    [Test]
    procedure DovrebbeUsareLaCombinazioneTrentuno;
    [Test]
    procedure DovrebbeFallireConUnaCombinazioneFuoriDalloIntervallo;
    [Test]
    procedure DovrebbeFunzionareConUnaTabellaVuota;
    [Test]
    procedure DovrebbeAvereLaDimensioneDiUnaRiga;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Renderer.FunctionRows;

type
  TProcedureVariable = procedure;

var
  FirstVariable: TProcedureVariable;
  SecondVariable: TProcedureVariable;

//==============================================================================
//
// Functions that only have to be different
//
//==============================================================================
procedure FunctionOne;
begin
end;

procedure FunctionTwo;
begin
end;

procedure Clear;
begin
  FirstVariable := nil;
  SecondVariable := nil;
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeDareIlValoreSoloAlLivelloEAllaCombinazioneGiusti
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeDareIlValoreSoloAlLivelloEAllaCombinazioneGiusti;
var
  LRows: array[0..1] of TRendererFunctionRow;
begin
  LRows[0].Detail := 2;
  LRows[0].Combos := $00000005; // combinations 0 and 2
  LRows[0].Slot := @@FirstVariable;
  LRows[0].Value := @FunctionOne;
  LRows[1].Detail := 3;
  LRows[1].Combos := $FFFFFFFF;
  LRows[1].Slot := @@SecondVariable;
  LRows[1].Value := @FunctionTwo;

  Clear;
  TRendererFunctionRows.Apply(LRows, 2, 1);
  Assert.IsTrue(@FirstVariable = nil);
  Assert.IsTrue(@SecondVariable = nil);

  TRendererFunctionRows.Apply(LRows, 2, 2);
  Assert.IsTrue(@FirstVariable = @FunctionOne);
  Assert.IsTrue(@SecondVariable = nil);

  Clear;
  TRendererFunctionRows.Apply(LRows, 3, 17);
  Assert.IsTrue(@FirstVariable = nil);
  Assert.IsTrue(@SecondVariable = @FunctionTwo);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeLasciareLeVariabiliChePerQuelLivelloNonHannoRighe
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeLasciareLeVariabiliChePerQuelLivelloNonHannoRighe;
var
  LRows: array[0..0] of TRendererFunctionRow;
begin
  LRows[0].Detail := 1;
  LRows[0].Combos := 1;
  LRows[0].Slot := @@FirstVariable;
  LRows[0].Value := @FunctionOne;

  Clear;
  SecondVariable := FunctionTwo;
  TRendererFunctionRows.Apply(LRows, 4, 0);
  Assert.IsTrue(@FirstVariable = nil);
  Assert.IsTrue(@SecondVariable = @FunctionTwo);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeDareNilQuandoLaRigaDiceNil
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeDareNilQuandoLaRigaDiceNil;
var
  LRows: array[0..0] of TRendererFunctionRow;
begin
  LRows[0].Detail := 0;
  LRows[0].Combos := 1;
  LRows[0].Slot := @@FirstVariable;
  LRows[0].Value := nil;

  Clear;
  FirstVariable := FunctionOne;
  TRendererFunctionRows.Apply(LRows, 0, 0);
  Assert.IsTrue(@FirstVariable = nil);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeDareLUltimoValoreDelleRigheDiUnaStessaVariabile
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeDareLUltimoValoreDelleRigheDiUnaStessaVariabile;
var
  LRows: array[0..1] of TRendererFunctionRow;
begin
  LRows[0].Detail := 0;
  LRows[0].Combos := 1;
  LRows[0].Slot := @@FirstVariable;
  LRows[0].Value := @FunctionOne;
  LRows[1].Detail := 0;
  LRows[1].Combos := 1;
  LRows[1].Slot := @@FirstVariable;
  LRows[1].Value := @FunctionTwo;

  Clear;
  TRendererFunctionRows.Apply(LRows, 0, 0);
  Assert.IsTrue(@FirstVariable = @FunctionTwo);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeUsareLaCombinazioneTrentuno
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeUsareLaCombinazioneTrentuno;
var
  LRows: array[0..0] of TRendererFunctionRow;
begin
  LRows[0].Detail := 5;
  LRows[0].Combos := $80000000;
  LRows[0].Slot := @@FirstVariable;
  LRows[0].Value := @FunctionOne;

  Clear;
  TRendererFunctionRows.Apply(LRows, 5, 30);
  Assert.IsTrue(@FirstVariable = nil);
  TRendererFunctionRows.Apply(LRows, 5, 31);
  Assert.IsTrue(@FirstVariable = @FunctionOne);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeFallireConUnaCombinazioneFuoriDalloIntervallo
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeFallireConUnaCombinazioneFuoriDalloIntervallo;
var
  LRows: array[0..0] of TRendererFunctionRow;
begin
  LRows[0].Detail := 0;
  LRows[0].Combos := 1;
  LRows[0].Slot := @@FirstVariable;
  LRows[0].Value := @FunctionOne;

  Assert.WillRaise(
    procedure
    begin
      TRendererFunctionRows.Apply(LRows, 0, 32);
    end,
    EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      TRendererFunctionRows.Apply(LRows, 0, -1);
    end,
    EArgumentOutOfRangeException);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeFunzionareConUnaTabellaVuota
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeFunzionareConUnaTabellaVuota;
var
  LRows: array of TRendererFunctionRow;
begin
  SetLength(LRows, 0);
  Clear;
  FirstVariable := FunctionOne;
  TRendererFunctionRows.Apply(LRows, 0, 0);
  Assert.IsTrue(@FirstVariable = @FunctionOne);
end;

//==============================================================================
//
// TTestRendererFunctionRows.DovrebbeAvereLaDimensioneDiUnaRiga
//
//==============================================================================
procedure TTestRendererFunctionRows.DovrebbeAvereLaDimensioneDiUnaRiga;
begin
  // the variables and the values are pointers: the same size at 32 and 64 bit (the row is in the data of the program)
  Assert.AreEqual<Integer>(SizeOf(Pointer), SizeOf(TProcedureVariable));
  Assert.AreEqual<Integer>(SizeOf(Pointer), SizeOf(PPointer));
end;

end.
