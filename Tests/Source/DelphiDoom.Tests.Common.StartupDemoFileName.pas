{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the file name of -playdemo                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Common.StartupDemoFileName;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Engine.Startup.DemoFileName;

type
  [TestFixture]
  [Category('startup')]
  TTestStartupDemoFileName = class(TObject)
  private
    function OldFileName(const AArgument: string): string;
  public
    [Test]
    [TestCase('senza estensione', 'demo1,demo1.lmp')]
    [TestCase('con estensione', 'demo1.lmp,demo1.lmp')]
    [TestCase('altra estensione', 'a.dem,a.dem')]
    [TestCase('con cartella', 'c:\demos\x.lmp,c:\demos\x.lmp')]
    procedure DovrebbeDareIlNomeAtteso(const AArgument, AExpected: string);
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodice;
  end;

implementation

uses
  d_delphi;

// Copy of the block of D_DoomMain of the four games before the extraction
function TTestStartupDemoFileName.OldFileName(const AArgument: string): string;
var
  filename: string;
begin
  if CharPos('.', AArgument) > 0 then
    filename := AArgument
  else
    sprintf(filename, '%s.lmp', [AArgument]);
  Result := filename;
end;

procedure TTestStartupDemoFileName.DovrebbeDareIlNomeAtteso(const AArgument, AExpected: string);
begin
  Assert.AreEqual(AExpected, TStartupDemoFileName.FromArgument(AArgument));
end;

procedure TTestStartupDemoFileName.DovrebbeEssereUgualeAlVecchioCodice;
const
  CArguments: array[0..5] of string = ('', 'e1m1', '.lmp', 'a.b.c', 'demo', 'x.');
var
  LIndex: Integer;
begin
  for LIndex := Low(CArguments) to High(CArguments) do
    Assert.AreEqual(OldFileName(CArguments[LIndex]), TStartupDemoFileName.FromArgument(CArguments[LIndex]));
end;

end.