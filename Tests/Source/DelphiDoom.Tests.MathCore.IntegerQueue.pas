{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the queue of integers          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.IntegerQueue;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>Parity with the old TIntegerQueue of m_stack (golden file stack.golden.txt)</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreIntegerQueue = class(TObject)
  public
    [Test]
    procedure DovrebbeSeguireLaSequenzaDellaVecchiaCoda;
    [Test]
    procedure DovrebbeDareIlPrimoNumeroMessoPerPrimo;
    [Test]
    procedure DovrebbeDareFalsoESenzaToccareIlValoreSeVuota;
    [Test]
    procedure DovrebbeContareEdSvuotare;
  end;

implementation

uses
  DelphiDoom.MathCore.IntegerQueue, DelphiDoom.Tests.MathCore.Golden,
  DelphiDoom.Tests.MathCore.Fingerprint, DelphiDoom.Tests.MathCore.Samples;

{ TTestMathCoreIntegerQueue }

procedure TTestMathCoreIntegerQueue.DovrebbeSeguireLaSequenzaDellaVecchiaCoda;
var
  LGolden: TGoldenFile;
  LFingerprint: TFingerprint;
  LQueue: TIntegerQueue;
  LState: Cardinal;
  LIndex, LValue: Integer;
begin
  LGolden := TGoldenFile.Create('stack.golden.txt');
  LFingerprint := TFingerprint.Create;
  LQueue := TIntegerQueue.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 3000 do
    begin
      if TMathCoreSamples.NextRandom(LState) mod 3 <> 0 then
        LQueue.Add(Integer(TMathCoreSamples.NextRandom(LState)))
      else
      begin
        LValue := 12345;
        LFingerprint.AddBoolean(LQueue.Remove(LValue));
        LFingerprint.AddInteger(LValue);
      end;
      LFingerprint.AddInteger(LQueue.Count);
    end;
    LGolden.Check('queue.sequence', LFingerprint.ToHex);
  finally
    LQueue.Free;
    LFingerprint.Free;
    LGolden.Free;
  end;
end;

procedure TTestMathCoreIntegerQueue.DovrebbeDareIlPrimoNumeroMessoPerPrimo;
var
  LQueue: TIntegerQueue;
  LValue: Integer;
begin
  LQueue := TIntegerQueue.Create;
  try
    LQueue.Add(1);
    LQueue.Add(2);
    LQueue.Add(3);
    Assert.IsTrue(LQueue.Remove(LValue));
    Assert.AreEqual(1, LValue);
    Assert.IsTrue(LQueue.Remove(LValue));
    Assert.AreEqual(2, LValue);
  finally
    LQueue.Free;
  end;
end;

procedure TTestMathCoreIntegerQueue.DovrebbeDareFalsoESenzaToccareIlValoreSeVuota;
var
  LQueue: TIntegerQueue;
  LValue: Integer;
begin
  LQueue := TIntegerQueue.Create;
  try
    LValue := 42;
    Assert.IsFalse(LQueue.Remove(LValue));
    Assert.AreEqual(42, LValue);
  finally
    LQueue.Free;
  end;
end;

procedure TTestMathCoreIntegerQueue.DovrebbeContareEdSvuotare;
var
  LQueue: TIntegerQueue;
  LValue: Integer;
begin
  LQueue := TIntegerQueue.Create;
  try
    LQueue.Add(5);
    LQueue.Add(6);
    Assert.AreEqual(2, LQueue.Count);
    LQueue.Clear;
    Assert.AreEqual(0, LQueue.Count);
    Assert.IsFalse(LQueue.Remove(LValue));
  finally
    LQueue.Free;
  end;
end;

end.
