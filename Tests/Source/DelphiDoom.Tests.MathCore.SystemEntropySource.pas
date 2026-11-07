{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the source of the runtime      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.SystemEntropySource;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TSystemEntropySource gives the numbers of Random, the generator of the runtime that the
  ///   old I_Random used. The seed of the runtime is saved and restored by every test
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreSystemEntropySource = class(TObject)
  strict private
    FSavedSeed: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliStessiNumeriDiRandom;
    [Test]
    procedure DovrebbeRestareNellIntervallo;
    [Test]
    procedure DovrebbeCambiareIlSemeSeRichiesto;
  end;

implementation

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.MathCore.SystemEntropySource;

{ TTestMathCoreSystemEntropySource }

procedure TTestMathCoreSystemEntropySource.Setup;
begin
  FSavedSeed := RandSeed;
end;

procedure TTestMathCoreSystemEntropySource.TearDown;
begin
  RandSeed := FSavedSeed;
end;

procedure TTestMathCoreSystemEntropySource.DovrebbeDareGliStessiNumeriDiRandom;
var
  LSource: IEntropySource;
  LExpected: array[0..99] of Integer;
  LIndex: Integer;
begin
  RandSeed := 12345;
  for LIndex := 0 to High(LExpected) do
    LExpected[LIndex] := Random(256);
  LSource := TSystemEntropySource.Create(False);
  RandSeed := 12345;
  for LIndex := 0 to High(LExpected) do
    Assert.AreEqual(LExpected[LIndex], LSource.Next(256));
end;

procedure TTestMathCoreSystemEntropySource.DovrebbeRestareNellIntervallo;
var
  LSource: IEntropySource;
  LIndex, LValue: Integer;
begin
  LSource := TSystemEntropySource.Create(False);
  for LIndex := 1 to 1000 do
  begin
    LValue := LSource.Next(7);
    Assert.IsTrue((LValue >= 0) and (LValue < 7), 'value ' + IntToStr(LValue));
  end;
end;

procedure TTestMathCoreSystemEntropySource.DovrebbeCambiareIlSemeSeRichiesto;
var
  LSource: IEntropySource;
begin
  // Randomize takes the seed from the clock: it is enough that the seed is no longer the one set
  RandSeed := 0;
  LSource := TSystemEntropySource.Create(True);
  Assert.AreNotEqual(0, RandSeed);
  Assert.IsTrue(LSource.Next(10) < 10);
end;

end.
