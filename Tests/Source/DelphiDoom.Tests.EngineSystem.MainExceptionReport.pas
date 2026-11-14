{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the report of an exception of the main loop            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.MainExceptionReport;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.EngineSystem.MainExceptionReport;

type
  [TestFixture]
  [Category('enginesystem')]
  TTestEngineSystemMainExceptionReport = class(TObject)
  public
    [Test]
    procedure DovrebbeDireClasseMessaggioEIndirizzo;
    [Test]
    procedure DovrebbeDareLOffsetDalLoadAddress;
    [Test]
    procedure DovrebbeDireSeLIndirizzoEFuoriDalProgramma;
    [Test]
    procedure DovrebbeDireUnaClasseSconosciutaSenzaNome;
    [Test]
    procedure DovrebbeDireLaBitnessDelProgramma;
    [Test]
    procedure DovrebbeUscireConUnCodiceDiversoDaZero;
  end;

implementation

{ TTestEngineSystemMainExceptionReport }

procedure TTestEngineSystemMainExceptionReport.DovrebbeDireClasseMessaggioEIndirizzo;
var
  LText: string;
begin
  LText := TMainExceptionReport.Build('EAccessViolation', 'Access violation at address 00401000', $401234, $400000);
  Assert.IsTrue(Pos('Exception: EAccessViolation', LText) > 0);
  Assert.IsTrue(Pos('Message: Access violation at address 00401000', LText) > 0);
  Assert.IsTrue(Pos('00401234', LText) > 0);
end;

procedure TTestEngineSystemMainExceptionReport.DovrebbeDareLOffsetDalLoadAddress;
var
  LText: string;
begin
  LText := TMainExceptionReport.Build('EAccessViolation', '', $12345678 + $1A2B3, $12345678);
  Assert.IsTrue(Pos('offset 0001A2B3', LText) > 0, LText);
end;

procedure TTestEngineSystemMainExceptionReport.DovrebbeDireSeLIndirizzoEFuoriDalProgramma;
var
  LText: string;
begin
  LText := TMainExceptionReport.Build('ERangeError', 'x', $100, $400000);
  Assert.IsTrue(Pos('outside of the program', LText) > 0);
  Assert.AreEqual(0, Pos('from the image base', LText));
end;

procedure TTestEngineSystemMainExceptionReport.DovrebbeDireUnaClasseSconosciutaSenzaNome;
begin
  Assert.IsTrue(Pos('unknown exception', TMainExceptionReport.Build('', '', $401000, $400000)) > 0);
end;

procedure TTestEngineSystemMainExceptionReport.DovrebbeDireLaBitnessDelProgramma;
begin
  Assert.IsTrue(Pos(IntToStr(SizeOf(Pointer) * 8) + ' bit', TMainExceptionReport.Build('E', '', 0, 0)) > 0);
end;

procedure TTestEngineSystemMainExceptionReport.DovrebbeUscireConUnCodiceDiversoDaZero;
begin
  Assert.IsTrue(TMainExceptionReport.ExitCode <> 0);
end;

end.
