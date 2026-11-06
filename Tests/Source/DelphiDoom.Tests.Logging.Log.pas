{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the logging library - the log and the recorder         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Logging.Log;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder;

type
  [TestFixture]
  [Category('logging')]
  TTestLoggingLog = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FDeveloper: Boolean;
    function MakeLog: ILog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInfoGoesToTheOutputAsItIs;
    [Test]
    procedure TestWarningGoesToTheErrorFileAndToTheOutput;
    [Test]
    procedure TestErrorGoesToTheErrorFileTheDialogAndTheOutput;
    [Test]
    procedure TestTheDialogGetsTheTextAlone;
    [Test]
    procedure TestDevWarningIsSilentOutsideDeveloperMode;
    [Test]
    procedure TestDevWarningInDeveloperMode;
    [Test]
    procedure TestDeveloperModeIsAskedEveryTime;
    [Test]
    procedure TestNoDeveloperFunctionMeansNever;
    [Test]
    procedure TestEverySinkGetsEveryMessage;
    [Test]
    procedure TestNoSinksIsFine;
    [Test]
    procedure TestPercentCharactersAreNotFormatted;
    [Test]
    procedure TestRecorderKeepsTheOrder;
    [Test]
    procedure TestRecorderClear;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory;

{ TTestLoggingLog }

procedure TTestLoggingLog.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  FDeveloper := False;
end;

procedure TTestLoggingLog.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
end;

function TTestLoggingLog.MakeLog: ILog;
begin
  Result := TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink),
    function: Boolean
    begin
      Result := FDeveloper;
    end);
end;

procedure TTestLoggingLog.TestInfoGoesToTheOutputAsItIs;
begin
  MakeLog.Info('hello'#13#10);
  Assert.AreEqual(1, FRecorder.Count);
  Assert.AreEqual(Ord(TLogChannel.Output), Ord(FRecorder[0].Channel));
  Assert.AreEqual('hello'#13#10, FRecorder[0].Text);
end;

procedure TTestLoggingLog.TestWarningGoesToTheErrorFileAndToTheOutput;
begin
  MakeLog.Warning('File not found'#13#10);
  Assert.AreEqual(2, FRecorder.Count);
  Assert.AreEqual(Ord(TLogChannel.ErrorFile), Ord(FRecorder[0].Channel));
  Assert.AreEqual('I_Warning: File not found'#13#10, FRecorder[0].Text);
  Assert.AreEqual(Ord(TLogChannel.Output), Ord(FRecorder[1].Channel));
  Assert.AreEqual('I_Warning: File not found'#13#10, FRecorder[1].Text);
end;

procedure TTestLoggingLog.TestErrorGoesToTheErrorFileTheDialogAndTheOutput;
begin
  MakeLog.Error('Bad news');
  Assert.AreEqual(3, FRecorder.Count);
  Assert.AreEqual(Ord(TLogChannel.ErrorFile), Ord(FRecorder[0].Channel));
  Assert.AreEqual(Ord(TLogChannel.Dialog), Ord(FRecorder[1].Channel));
  Assert.AreEqual(Ord(TLogChannel.Output), Ord(FRecorder[2].Channel));
  Assert.AreEqual('I_Error: Bad news'#13#10, FRecorder[0].Text);
  Assert.AreEqual('I_Error: Bad news'#13#10, FRecorder[2].Text);
end;

procedure TTestLoggingLog.TestTheDialogGetsTheTextAlone;
begin
  MakeLog.Error('Bad news');
  Assert.AreEqual('Bad news', FRecorder.TextOf(TLogChannel.Dialog));
end;

procedure TTestLoggingLog.TestDevWarningIsSilentOutsideDeveloperMode;
begin
  MakeLog.DevWarning('detail'#13#10);
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestLoggingLog.TestDevWarningInDeveloperMode;
begin
  FDeveloper := True;
  MakeLog.DevWarning('detail'#13#10);
  Assert.AreEqual(2, FRecorder.Count);
  Assert.AreEqual('I_Warning: detail'#13#10, FRecorder.TextOf(TLogChannel.Output));
end;

procedure TTestLoggingLog.TestDeveloperModeIsAskedEveryTime;
var
  LLog: ILog;
begin
  LLog := MakeLog;
  LLog.DevWarning('a'#13#10);
  Assert.AreEqual(0, FRecorder.Count);
  FDeveloper := True;
  LLog.DevWarning('b'#13#10);
  Assert.AreEqual(2, FRecorder.Count);
  FDeveloper := False;
  LLog.DevWarning('c'#13#10);
  Assert.AreEqual(2, FRecorder.Count);
end;

procedure TTestLoggingLog.TestNoDeveloperFunctionMeansNever;
begin
  TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil).DevWarning('x');
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestLoggingLog.TestEverySinkGetsEveryMessage;
var
  LOther: TLogRecorder;
  LOtherSink: ILogSink;
begin
  LOther := TLogRecorder.Create;
  LOtherSink := LOther;
  TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink, LOtherSink), nil).Warning('w'#13#10);
  Assert.AreEqual(2, FRecorder.Count);
  Assert.AreEqual(2, LOther.Count);
  Assert.AreEqual(FRecorder.TextOf(TLogChannel.ErrorFile), LOther.TextOf(TLogChannel.ErrorFile));
end;

procedure TTestLoggingLog.TestNoSinksIsFine;
var
  LLog: ILog;
begin
  LLog := TLogFactory.CreateLog(nil, nil);
  LLog.Info('a');
  LLog.Warning('b');
  LLog.Error('c');
  Assert.Pass;
end;

procedure TTestLoggingLog.TestPercentCharactersAreNotFormatted;
begin
  MakeLog.Info('100% of %d'#13#10);
  Assert.AreEqual('100% of %d'#13#10, FRecorder.TextOf(TLogChannel.Output));
end;

procedure TTestLoggingLog.TestRecorderKeepsTheOrder;
var
  LLog: ILog;
begin
  LLog := MakeLog;
  LLog.Info('1');
  LLog.Warning('2');
  LLog.Info('3');
  Assert.AreEqual('1I_Warning: 23', FRecorder.TextOf(TLogChannel.Output));
  Assert.AreEqual(4, FRecorder.Count);
end;

procedure TTestLoggingLog.TestRecorderClear;
begin
  MakeLog.Info('x');
  FRecorder.Clear;
  Assert.AreEqual(0, FRecorder.Count);
  Assert.AreEqual('', FRecorder.TextOf(TLogChannel.Output));
end;

end.
