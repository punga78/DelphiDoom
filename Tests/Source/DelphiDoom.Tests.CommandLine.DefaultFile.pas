{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - the default file            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.DefaultFile;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineDefaultFile = class(TObject)
  private
    function Joined(const AText: string): string;
  public
    [Test]
    procedure TestArgumentsAreSplitAndUpperCase;
    [Test]
    procedure TestCommentLinesAreSkipped;
    [Test]
    procedure TestCommentAtTheEndOfALine;
    [Test]
    procedure TestOnlyTheCommentMarkWithASpaceCounts;
    [Test]
    procedure TestLineBreaksOfEveryKind;
    [Test]
    procedure TestManySpacesAndTabs;
    [Test]
    procedure TestEmptyText;
    [Test]
    procedure TestTheTemplateHoldsJustTheProgramName;
    [Test]
    procedure TestTheTemplateNamesTheApplicationAndTheProgram;
  end;

implementation

uses
  DelphiDoom.CommandLine.DefaultFile;

{ TTestCommandLineDefaultFile }

function TTestCommandLineDefaultFile.Joined(const AText: string): string;
var
  LItem: string;
begin
  Result := '';
  for LItem in TDefaultArgumentsFile.Parse(AText) do
    Result := Result + '[' + LItem + ']';
end;

procedure TTestCommandLineDefaultFile.TestArgumentsAreSplitAndUpperCase;
begin
  Assert.AreEqual('[-WARP][1][1][-NOMONSTERS]', Joined('-warp 1 1 -nomonsters'));
end;

procedure TTestCommandLineDefaultFile.TestCommentLinesAreSkipped;
begin
  Assert.AreEqual('[-DEVPARM]', Joined('// a comment'#13#10'-devparm'#13#10'// another'));
end;

procedure TTestCommandLineDefaultFile.TestCommentAtTheEndOfALine;
begin
  Assert.AreEqual('[-FILE][A.WAD]', Joined('-file a.wad // my wad, not the others -x'));
end;

procedure TTestCommandLineDefaultFile.TestOnlyTheCommentMarkWithASpaceCounts;
begin
  // "//x" is not a comment: it stays as an argument
  Assert.AreEqual('[//X][-A]', Joined('//x -a'));
end;

procedure TTestCommandLineDefaultFile.TestLineBreaksOfEveryKind;
begin
  Assert.AreEqual('[-A][-B][-C][-D]', Joined('-a'#13#10'-b'#10'-c'#13'-d'));
end;

procedure TTestCommandLineDefaultFile.TestManySpacesAndTabs;
begin
  Assert.AreEqual('[-A][-B]', Joined('   -a     -b   '));
  // a tab is not a separator: it only trims the ends
  Assert.AreEqual('[-A'#9'-B]', Joined('-a'#9'-b'));
  Assert.AreEqual('[-A]', Joined(#9'-a'#9));
end;

procedure TTestCommandLineDefaultFile.TestEmptyText;
begin
  Assert.AreEqual('', Joined(''));
  Assert.AreEqual('', Joined('   '#13#10'  '));
end;

procedure TTestCommandLineDefaultFile.TestTheTemplateHoldsJustTheProgramName;
begin
  // the new file holds the name of the program, which the engine reads as an argument
  Assert.AreEqual('[DOOM32]', Joined(TDefaultArgumentsFile.Template('Delphi Doom', 'Doom32')));
end;

procedure TTestCommandLineDefaultFile.TestTheTemplateNamesTheApplicationAndTheProgram;
var
  LText: string;
begin
  LText := TDefaultArgumentsFile.Template('Delphi Doom', 'DOOM32');
  Assert.IsTrue(Pos('everytime you run Delphi Doom.', LText) > 0);
  Assert.IsTrue(Pos('doom32 ', LText) > 0);
  Assert.IsTrue(LText.StartsWith('// Add default command line parameters to this file.'));
end;

end.
