{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the random numbers of the pilot   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.Random;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.Random;

type
  [TestFixture]
  [Category('parity')]
  TTestParityRandom = class(TObject)
  public
    [Test]
    procedure LoStessoSemeDovrebbeDareLaStessaSerie;
    [Test]
    procedure SemiDiversiDovrebberoDareSerieDiverse;
    [Test]
    procedure DovrebbeDareLaSerieNotaDiSplitMix32;
    [Test]
    procedure NextBelowDovrebbeRestareNelLimite;
    [Test]
    procedure NextBelowDiUnoOMenoDovrebbeDareZero;
    [Test]
    procedure NextBetweenDovrebbeIncludereGliEstremi;
    [Test]
    procedure NextBetweenConEstremiAlContrarioDovrebbeDareIlMinimo;
    [Test]
    procedure DovrebbeUsareTuttiIValoriDiUnPiccoloLimite;
    [Test]
    procedure NonDovrebbeToccareIlGeneratoreDelRuntime;
  end;

implementation

procedure TTestParityRandom.LoStessoSemeDovrebbeDareLaStessaSerie;
var
  LFirst: TParityRandom;
  LSecond: TParityRandom;
  LIndex: Integer;
begin
  LFirst := TParityRandom.Create(1234);
  LSecond := TParityRandom.Create(1234);
  try
    for LIndex := 1 to 1000 do
      Assert.AreEqual(LFirst.NextCardinal, LSecond.NextCardinal);
  finally
    LFirst.Free;
    LSecond.Free;
  end;
end;

procedure TTestParityRandom.SemiDiversiDovrebberoDareSerieDiverse;
var
  LFirst: TParityRandom;
  LSecond: TParityRandom;
begin
  LFirst := TParityRandom.Create(1);
  LSecond := TParityRandom.Create(2);
  try
    Assert.AreNotEqual(LFirst.NextCardinal, LSecond.NextCardinal);
  finally
    LFirst.Free;
    LSecond.Free;
  end;
end;

procedure TTestParityRandom.DovrebbeDareLaSerieNotaDiSplitMix32;
var
  LRandom: TParityRandom;
begin
  // the values of the reference implementation (seed 0): they never change, on any machine
  LRandom := TParityRandom.Create(0);
  try
    Assert.AreEqual(Cardinal($92CA2F0E), LRandom.NextCardinal);
    Assert.AreEqual(Cardinal($3CD6E3F3), LRandom.NextCardinal);
  finally
    LRandom.Free;
  end;
end;

procedure TTestParityRandom.NextBelowDovrebbeRestareNelLimite;
var
  LRandom: TParityRandom;
  LIndex: Integer;
  LValue: Integer;
begin
  LRandom := TParityRandom.Create(9);
  try
    for LIndex := 1 to 5000 do
    begin
      LValue := LRandom.NextBelow(7);
      Assert.IsTrue((LValue >= 0) and (LValue < 7));
    end;
  finally
    LRandom.Free;
  end;
end;

procedure TTestParityRandom.NextBelowDiUnoOMenoDovrebbeDareZero;
var
  LRandom: TParityRandom;
begin
  LRandom := TParityRandom.Create(9);
  try
    Assert.AreEqual(0, LRandom.NextBelow(1));
    Assert.AreEqual(0, LRandom.NextBelow(0));
    Assert.AreEqual(0, LRandom.NextBelow(-4));
  finally
    LRandom.Free;
  end;
end;

procedure TTestParityRandom.NextBetweenDovrebbeIncludereGliEstremi;
var
  LRandom: TParityRandom;
  LIndex: Integer;
  LValue: Integer;
  LSawMinimum: Boolean;
  LSawMaximum: Boolean;
begin
  LRandom := TParityRandom.Create(5);
  try
    LSawMinimum := False;
    LSawMaximum := False;
    for LIndex := 1 to 2000 do
    begin
      LValue := LRandom.NextBetween(3, 6);
      Assert.IsTrue((LValue >= 3) and (LValue <= 6));
      LSawMinimum := LSawMinimum or (LValue = 3);
      LSawMaximum := LSawMaximum or (LValue = 6);
    end;
    Assert.IsTrue(LSawMinimum and LSawMaximum);
  finally
    LRandom.Free;
  end;
end;

procedure TTestParityRandom.NextBetweenConEstremiAlContrarioDovrebbeDareIlMinimo;
var
  LRandom: TParityRandom;
begin
  LRandom := TParityRandom.Create(5);
  try
    Assert.AreEqual(8, LRandom.NextBetween(8, 2));
  finally
    LRandom.Free;
  end;
end;

procedure TTestParityRandom.DovrebbeUsareTuttiIValoriDiUnPiccoloLimite;
var
  LRandom: TParityRandom;
  LSeen: array[0..3] of Boolean;
  LIndex: Integer;
begin
  FillChar(LSeen, SizeOf(LSeen), 0);
  LRandom := TParityRandom.Create(77);
  try
    for LIndex := 1 to 500 do
      LSeen[LRandom.NextBelow(4)] := True;
  finally
    LRandom.Free;
  end;
  for LIndex := 0 to 3 do
    Assert.IsTrue(LSeen[LIndex], IntToStr(LIndex));
end;

procedure TTestParityRandom.NonDovrebbeToccareIlGeneratoreDelRuntime;
var
  LRandom: TParityRandom;
  LSaved: Integer;
  LBefore: Integer;
  LAfter: Integer;
begin
  LSaved := RandSeed;
  RandSeed := 4242;
  LBefore := Random(1000000);
  RandSeed := 4242;
  LRandom := TParityRandom.Create(1);
  try
    LRandom.NextCardinal;
    LRandom.NextBelow(10);
  finally
    LRandom.Free;
  end;
  LAfter := Random(1000000);
  RandSeed := LSaved;
  Assert.AreEqual(LBefore, LAfter);
end;

end.
