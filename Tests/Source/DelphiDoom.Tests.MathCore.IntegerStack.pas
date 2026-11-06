{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the stack of integers          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.IntegerStack;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>Parity with the old TIntegerStack of m_stack (golden file stack.golden.txt)</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreIntegerStack = class(TObject)
  public
    [Test]
    procedure DovrebbeSeguireLaSequenzaDelVecchioStack;
    [Test]
    procedure DovrebbeDareIlUltimoNumeroMessoPerPrimo;
    [Test]
    procedure DovrebbeDareFalsoESenzaToccareIlValoreSeVuoto;
    [Test]
    procedure DovrebbeContareEdSvuotare;
  end;

implementation

uses
  DelphiDoom.MathCore.IntegerStack, DelphiDoom.Tests.MathCore.Golden,
  DelphiDoom.Tests.MathCore.Fingerprint, DelphiDoom.Tests.MathCore.Samples;

{ TTestMathCoreIntegerStack }

procedure TTestMathCoreIntegerStack.DovrebbeSeguireLaSequenzaDelVecchioStack;
var
  LGolden: TGoldenFile;
  LFingerprint: TFingerprint;
  LStack: TIntegerStack;
  LState: Cardinal;
  LIndex, LValue: Integer;
begin
  LGolden := TGoldenFile.Create('stack.golden.txt');
  LFingerprint := TFingerprint.Create;
  LStack := TIntegerStack.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 3000 do
    begin
      if TMathCoreSamples.NextRandom(LState) mod 3 <> 0 then
        LStack.Push(Integer(TMathCoreSamples.NextRandom(LState)))
      else
      begin
        LValue := 12345;
        LFingerprint.AddBoolean(LStack.Pop(LValue));
        LFingerprint.AddInteger(LValue);
      end;
      LFingerprint.AddInteger(LStack.Count);
    end;
    LGolden.Check('stack.sequence', LFingerprint.ToHex);
  finally
    LStack.Free;
    LFingerprint.Free;
    LGolden.Free;
  end;
end;

procedure TTestMathCoreIntegerStack.DovrebbeDareIlUltimoNumeroMessoPerPrimo;
var
  LStack: TIntegerStack;
  LValue: Integer;
begin
  LStack := TIntegerStack.Create;
  try
    LStack.Push(1);
    LStack.Push(2);
    LStack.Push(3);
    Assert.IsTrue(LStack.Pop(LValue));
    Assert.AreEqual(3, LValue);
    Assert.IsTrue(LStack.Pop(LValue));
    Assert.AreEqual(2, LValue);
  finally
    LStack.Free;
  end;
end;

procedure TTestMathCoreIntegerStack.DovrebbeDareFalsoESenzaToccareIlValoreSeVuoto;
var
  LStack: TIntegerStack;
  LValue: Integer;
begin
  LStack := TIntegerStack.Create;
  try
    LValue := 42;
    Assert.IsFalse(LStack.Pop(LValue));
    Assert.AreEqual(42, LValue);
  finally
    LStack.Free;
  end;
end;

procedure TTestMathCoreIntegerStack.DovrebbeContareEdSvuotare;
var
  LStack: TIntegerStack;
  LValue: Integer;
begin
  LStack := TIntegerStack.Create;
  try
    LStack.Push(5);
    LStack.Push(6);
    Assert.AreEqual(2, LStack.Count);
    LStack.Clear;
    Assert.AreEqual(0, LStack.Count);
    Assert.IsFalse(LStack.Pop(LValue));
  finally
    LStack.Free;
  end;
end;

end.
