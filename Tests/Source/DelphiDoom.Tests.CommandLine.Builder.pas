{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - the builder                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.Builder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.CommandLine.Intf;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineBuilder = class(TObject)
  private
    FBuilder: ICommandLineBuilder;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestBuildGivesWhatWasAdded;
    [Test]
    procedure TestEmptyArgumentsAreSkipped;
    [Test]
    procedure TestTheDefaultFileComesAfterAMarker;
    [Test]
    procedure TestTheMarkerIsThereEvenWhenTheFileHasNothing;
    [Test]
    procedure TestTheLimitOfArguments;
    [Test]
    procedure TestTheDefaultFileStopsAtTheLimit;
    [Test]
    procedure TestBuildStartsAgain;
    [Test]
    procedure TestValuesAfterTheMarkerAreOnlyThoseOfTheFile;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types, DelphiDoom.CommandLine.Factory;

{ TTestCommandLineBuilder }

procedure TTestCommandLineBuilder.Setup;
begin
  FBuilder := TCommandLineFactory.CreateBuilder;
end;

procedure TTestCommandLineBuilder.TestBuildGivesWhatWasAdded;
var
  LLine: ICommandLine;
begin
  Assert.IsTrue(FBuilder.Add('doom32.exe'));
  Assert.IsTrue(FBuilder.Add('-warp'));
  Assert.AreEqual(2, FBuilder.Count);
  LLine := FBuilder.Build;
  Assert.AreEqual(2, LLine.Count);
  Assert.AreEqual('DOOM32.EXE', LLine[0]);
  Assert.AreEqual(1, LLine.IndexOf('-warp'));
end;

procedure TTestCommandLineBuilder.TestEmptyArgumentsAreSkipped;
begin
  Assert.IsFalse(FBuilder.Add(''));
  Assert.AreEqual(0, FBuilder.Count);
end;

procedure TTestCommandLineBuilder.TestTheDefaultFileComesAfterAMarker;
var
  LLine: ICommandLine;
begin
  FBuilder.Add('doom32.exe');
  FBuilder.Add('-file');
  FBuilder.Add('mine.wad');
  FBuilder.AddDefaultFile('// my defaults'#13#10'-nomonsters -skill 4');
  LLine := FBuilder.Build;
  Assert.AreEqual(7, LLine.Count);
  Assert.AreEqual(COMMANDLINE_DEFAULT_MARKER, LLine[3]);
  Assert.AreEqual('-NOMONSTERS', LLine[4]);
  Assert.AreEqual('4', LLine[6]);
end;

procedure TTestCommandLineBuilder.TestTheMarkerIsThereEvenWhenTheFileHasNothing;
var
  LLine: ICommandLine;
begin
  FBuilder.Add('doom32.exe');
  FBuilder.AddDefaultFile('// nothing'#13#10);
  LLine := FBuilder.Build;
  Assert.AreEqual(2, LLine.Count);
  Assert.IsTrue(LLine.Has(COMMANDLINE_DEFAULT_MARKER));
end;

procedure TTestCommandLineBuilder.TestTheLimitOfArguments;
var
  LIndex: Integer;
begin
  for LIndex := 1 to COMMANDLINE_MAX_ARGUMENTS do
    Assert.IsTrue(FBuilder.Add('a' + IntToStr(LIndex)), 'argument ' + IntToStr(LIndex));
  Assert.IsFalse(FBuilder.Add('one too many'));
  Assert.AreEqual(COMMANDLINE_MAX_ARGUMENTS, FBuilder.Count);
  Assert.AreEqual(COMMANDLINE_MAX_ARGUMENTS, FBuilder.Build.Count);
end;

procedure TTestCommandLineBuilder.TestTheDefaultFileStopsAtTheLimit;
var
  LIndex: Integer;
begin
  for LIndex := 1 to COMMANDLINE_MAX_ARGUMENTS - 3 do
    FBuilder.Add('a' + IntToStr(LIndex));
  FBuilder.AddDefaultFile('-a -b -c -d -e');
  Assert.AreEqual(COMMANDLINE_MAX_ARGUMENTS, FBuilder.Count);
end;

procedure TTestCommandLineBuilder.TestBuildStartsAgain;
begin
  FBuilder.Add('a.exe');
  FBuilder.Build;
  Assert.AreEqual(0, FBuilder.Count);
  Assert.AreEqual(0, FBuilder.Build.Count);
end;

procedure TTestCommandLineBuilder.TestValuesAfterTheMarkerAreOnlyThoseOfTheFile;
var
  LValues: TArray<string>;
begin
  FBuilder.Add('doom32.exe');
  FBuilder.Add('-file');
  FBuilder.Add('first.wad');
  FBuilder.AddDefaultFile('-file second.wad');
  // the values of -file stop at the marker, which starts with '-'
  LValues := FBuilder.Build.ValuesAfter('-file');
  Assert.AreEqual<Integer>(1, Length(LValues));
  Assert.AreEqual('FIRST.WAD', LValues[0]);
end;

end.
