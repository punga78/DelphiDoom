{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - TCommandLine                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.Arguments;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.CommandLine.Intf;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineArguments = class(TObject)
  private
    function Make(const AArguments: array of string): ICommandLine;
  public
    [Test]
    procedure TestArgumentsAreUpperCase;
    [Test]
    procedure TestIndexOfIsCaseInsensitive;
    [Test]
    procedure TestIndexOfNeverAnswersTheProgramName;
    [Test]
    procedure TestIndexOfMissingIsZero;
    [Test]
    procedure TestFirstOccurrenceWins;
    [Test]
    procedure TestHas;
    [Test]
    procedure TestValuesAfterStopAtTheNextParameter;
    [Test]
    procedure TestValuesAfterGoToTheEnd;
    [Test]
    procedure TestValuesAfterOfAMissingParameter;
    [Test]
    procedure TestValuesAfterWithNothingAfter;
    [Test]
    procedure TestText;
    [Test]
    procedure TestPositionOutOfRange;
    [Test]
    procedure TestEmptyCommandLine;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types, DelphiDoom.CommandLine.Factory;

{ TTestCommandLineArguments }

function TTestCommandLineArguments.Make(const AArguments: array of string): ICommandLine;
var
  LItems: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LItems, Length(AArguments));
  for LIndex := 0 to High(AArguments) do
    LItems[LIndex] := AArguments[LIndex];
  Result := TCommandLineFactory.CreateCommandLine(LItems);
end;

procedure TTestCommandLineArguments.TestArgumentsAreUpperCase;
var
  LLine: ICommandLine;
begin
  LLine := Make(['doom32.exe', '-warp', 'e1m1']);
  Assert.AreEqual(3, LLine.Count);
  Assert.AreEqual('DOOM32.EXE', LLine[0]);
  Assert.AreEqual('E1M1', LLine[2]);
end;

procedure TTestCommandLineArguments.TestIndexOfIsCaseInsensitive;
var
  LLine: ICommandLine;
begin
  LLine := Make(['doom32.exe', '-Warp', '1', '1']);
  Assert.AreEqual(1, LLine.IndexOf('-warp'));
  Assert.AreEqual(1, LLine.IndexOf('-WARP'));
end;

procedure TTestCommandLineArguments.TestIndexOfNeverAnswersTheProgramName;
var
  LLine: ICommandLine;
begin
  // the name of the program is not a parameter
  LLine := Make(['-nomonsters', '-nomonsters']);
  Assert.AreEqual(1, LLine.IndexOf('-nomonsters'));
  LLine := Make(['-x']);
  Assert.AreEqual(0, LLine.IndexOf('-x'));
end;

procedure TTestCommandLineArguments.TestIndexOfMissingIsZero;
begin
  Assert.AreEqual(0, Make(['a.exe', '-b']).IndexOf('-c'));
end;

procedure TTestCommandLineArguments.TestFirstOccurrenceWins;
begin
  Assert.AreEqual(2, Make(['a.exe', '-x', '-b', '-b']).IndexOf('-b'));
end;

procedure TTestCommandLineArguments.TestHas;
var
  LLine: ICommandLine;
begin
  LLine := Make(['a.exe', '-devparm']);
  Assert.IsTrue(LLine.Has('-DEVPARM'));
  Assert.IsFalse(LLine.Has('-nosound'));
end;

procedure TTestCommandLineArguments.TestValuesAfterStopAtTheNextParameter;
var
  LValues: TArray<string>;
begin
  LValues := Make(['a.exe', '-file', 'one.wad', 'two.wad', '-warp', '1']).ValuesAfter('-file');
  Assert.AreEqual(2, Length(LValues));
  Assert.AreEqual('ONE.WAD', LValues[0]);
  Assert.AreEqual('TWO.WAD', LValues[1]);
end;

procedure TTestCommandLineArguments.TestValuesAfterGoToTheEnd;
var
  LValues: TArray<string>;
begin
  LValues := Make(['a.exe', '-warp', '2', '5']).ValuesAfter('-warp');
  Assert.AreEqual(2, Length(LValues));
  Assert.AreEqual('5', LValues[1]);
end;

procedure TTestCommandLineArguments.TestValuesAfterOfAMissingParameter;
begin
  Assert.AreEqual(0, Length(Make(['a.exe', '-warp', '1']).ValuesAfter('-file')));
end;

procedure TTestCommandLineArguments.TestValuesAfterWithNothingAfter;
begin
  Assert.AreEqual(0, Length(Make(['a.exe', '-file']).ValuesAfter('-file')));
  Assert.AreEqual(0, Length(Make(['a.exe', '-file', '-warp']).ValuesAfter('-file')));
end;

procedure TTestCommandLineArguments.TestText;
begin
  Assert.AreEqual('-WARP 1 1', Make(['a.exe', '-warp', '1', '1']).Text);
  Assert.AreEqual('', Make(['a.exe']).Text);
end;

procedure TTestCommandLineArguments.TestPositionOutOfRange;
var
  LLine: ICommandLine;
begin
  LLine := Make(['a.exe']);
  Assert.WillRaise(procedure begin LLine[1]; end, ECommandLineException);
  Assert.WillRaise(procedure begin LLine[-1]; end, ECommandLineException);
end;

procedure TTestCommandLineArguments.TestEmptyCommandLine;
var
  LLine: ICommandLine;
begin
  LLine := TCommandLineFactory.CreateCommandLine(nil);
  Assert.AreEqual(0, LLine.Count);
  Assert.AreEqual(0, LLine.IndexOf('-x'));
  Assert.AreEqual('', LLine.Text);
end;

end.
