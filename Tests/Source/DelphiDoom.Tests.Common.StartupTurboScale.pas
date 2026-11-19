{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scale of -turbo                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Common.StartupTurboScale;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Engine.Startup.TurboScale;

type
  [TestFixture]
  [Category('startup')]
  TTestStartupTurboScale = class(TObject)
  private
    function OldScale(const AArgument: string): Integer;
  public
    [Test]
    [TestCase('senza numero', 'abc,200')]
    [TestCase('sotto il minimo', '3,10')]
    [TestCase('al minimo', '10,10')]
    [TestCase('normale', '150,150')]
    [TestCase('al massimo', '200,200')]
    [TestCase('sopra il massimo', '400,200')]
    [TestCase('zero', '0,10')]
    procedure DovrebbeDareLaScalaAttesa(const AArgument: string; AExpected: Integer);
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuTuttiIValori;
  end;

implementation

uses
  d_delphi;

// Copy of the block of D_DoomMain of the four games before the extraction
function TTestStartupTurboScale.OldScale(const AArgument: string): Integer;
var
  scale: Integer;
begin
  scale := atoi(AArgument, 200);
  if scale < 10 then
    scale := 10
  else if scale > 200 then
    scale := 200;
  Result := scale;
end;

procedure TTestStartupTurboScale.DovrebbeDareLaScalaAttesa(const AArgument: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TStartupTurboScale.FromArgument(AArgument));
end;

procedure TTestStartupTurboScale.DovrebbeEssereUgualeAlVecchioCodiceSuTuttiIValori;
var
  LValue: Integer;
  LText: string;
begin
  for LValue := -50 to 500 do
  begin
    LText := IntToStr(LValue);
    Assert.AreEqual(OldScale(LText), TStartupTurboScale.FromArgument(LText), LText);
  end;
  Assert.AreEqual(OldScale(''), TStartupTurboScale.FromArgument(''));
  Assert.AreEqual(OldScale('x'), TStartupTurboScale.FromArgument('x'));
end;

end.