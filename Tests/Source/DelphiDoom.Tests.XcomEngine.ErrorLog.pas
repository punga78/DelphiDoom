{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXcomErrorLog, the file of the errors of the program   }
{  (issue 187)                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.ErrorLog;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.OptionsStore.Intf, DelphiDoom.XcomEngine.ErrorLog,
  DelphiDoom.XcomEngine.ErrorLog.Types, DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomEngine.GamePause;

type
  /// <summary>The error of the probe state</summary>
  EProbeError = class(Exception);

  /// <summary>A state that fails in its first turn, as a state with a defect does</summary>
  TFailingState = class(TXcomState)
  public
    procedure Think; override;
  end;

  /// <summary>An IXcomFileSystem that cannot write (a disk that is full, a folder that is read only)</summary>
  TUnwritableFileSystem = class(TInterfacedObject, IXcomFileSystem)
  public
    function FileExists(const APath: string): Boolean;
    function FolderExists(const APath: string): Boolean;
    function ReadAll(const APath: string): TBytes;
    procedure WriteAll(const APath: string; const ABytes: TBytes);
    function FolderContents(const AFolder, AExtension: string): TArray<string>;
  end;

  /// <summary>An options store whose writing fails</summary>
  TFailingOptionsStore = class(TInterfacedObject, IXcomOptionsStore)
  public
    procedure Load(AOptions: TXcomOptions; const AReason: string = '');
    procedure Save(AOptions: TXcomOptions; const AReason: string = '');
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomErrorLog = class
  strict private
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    FLog: TXcomErrorLog;
    FMinute: Integer;
    function NewEntry(const AMessage: string): TXcomErrorEntry;
    function Text: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFormareLaVoceConTuttiICampi;
    [Test]
    procedure DovrebbeScrivereLaVoceNelFile;
    [Test]
    procedure DovrebbeAccumulareLeVoci;
    [Test]
    procedure DovrebbeConservareIlContenutoGiaPresente;
    [Test]
    procedure DovrebbeScrivereUnaVoceSenzaStati;
    [Test]
    procedure DovrebbeDareFalsoESpiegareSeLaScritturaFallisce;
    [Test]
    procedure DovrebbeAzzerareLUltimoErroreDopoUnaScritturaRiuscita;
    [Test]
    procedure DovrebbeRifiutareIParametriNil;
    [Test]
    procedure DovrebbeScrivereLEccezioneDelCicloConLaPilaDegliStati;
    [Test]
    procedure NonDovrebbeNascondereLErroreOriginaleSeLeOpzioniNonSiScrivono;
    [Test]
    procedure DovrebbeDareIStatiConQuelloInCimaPerPrimo;
  end;

implementation

{ TFailingState }

procedure TFailingState.Think;
begin
  inherited Think;
  raise EProbeError.Create('probe failure');
end;

{ TUnwritableFileSystem }

function TUnwritableFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := False;
end;

function TUnwritableFileSystem.FolderExists(const APath: string): Boolean;
begin
  Result := False;
end;

function TUnwritableFileSystem.ReadAll(const APath: string): TBytes;
begin
  Result := nil;
end;

procedure TUnwritableFileSystem.WriteAll(const APath: string; const ABytes: TBytes);
begin
  raise EInOutError.Create('disk full');
end;

function TUnwritableFileSystem.FolderContents(const AFolder, AExtension: string): TArray<string>;
begin
  Result := nil;
end;

{ TFailingOptionsStore }

procedure TFailingOptionsStore.Load(AOptions: TXcomOptions; const AReason: string);
begin
end;

procedure TFailingOptionsStore.Save(AOptions: TXcomOptions; const AReason: string);
begin
  raise EInOutError.Create('options.cfg is locked');
end;

{ TTestXcomErrorLog }

procedure TTestXcomErrorLog.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FMinute := 0;
  FLog := TXcomErrorLog.Create(FFilesRef, 'user\xcom_errors.log',
    function: string
    begin
      Inc(FMinute);
      Result := Format('2026-11-13 10:%.2d:00', [FMinute]);
    end);
end;

procedure TTestXcomErrorLog.TearDown;
begin
  FLog.Free;
  FFilesRef := nil;
end;

function TTestXcomErrorLog.NewEntry(const AMessage: string): TXcomErrorEntry;
begin
  Result.ExceptionClass := 'EAccessViolation';
  Result.ExceptionMessage := AMessage;
  Result.MapAddress := '004A1B2C';
  Result.CallStack := '004A1B30 004A2000';
  Result.States := ['TXcomSellState', 'TXcomDebriefingState', 'TXcomGeoscapeState'];
  Result.Version := '1.0 git test';
end;

function TTestXcomErrorLog.Text: string;
begin
  Result := TEncoding.UTF8.GetString(FFilesRef.ReadAll('user\xcom_errors.log'));
end;

procedure TTestXcomErrorLog.DovrebbeFormareLaVoceConTuttiICampi;
var
  LExpected: string;
begin
  LExpected := '==== 2026-11-13 10:01:00' + sLineBreak +
    'version: 1.0 git test' + sLineBreak +
    'error: EAccessViolation: boom' + sLineBreak +
    'map address: 004A1B2C' + sLineBreak +
    'stack: 004A1B30 004A2000' + sLineBreak +
    'states: TXcomSellState > TXcomDebriefingState > TXcomGeoscapeState' + sLineBreak;
  Assert.AreEqual(LExpected, FLog.FormatEntry(NewEntry('boom')));
end;

procedure TTestXcomErrorLog.DovrebbeScrivereLaVoceNelFile;
begin
  Assert.IsTrue(FLog.Write(NewEntry('boom')));
  Assert.IsTrue(FFilesRef.FileExists('user\xcom_errors.log'));
  Assert.Contains(Text, 'error: EAccessViolation: boom');
  Assert.Contains(Text, 'states: TXcomSellState > TXcomDebriefingState');
  Assert.AreEqual('', FLog.LastError);
end;

procedure TTestXcomErrorLog.DovrebbeAccumulareLeVoci;
var
  LPosition: Integer;
begin
  Assert.IsTrue(FLog.Write(NewEntry('first')));
  Assert.IsTrue(FLog.Write(NewEntry('second')));
  Assert.IsTrue(FLog.Write(NewEntry('third')));
  LPosition := Pos('error: EAccessViolation: first', Text);
  Assert.IsTrue(LPosition > 0);
  Assert.IsTrue(Pos('error: EAccessViolation: second', Text) > LPosition);
  Assert.IsTrue(Pos('error: EAccessViolation: third', Text) > Pos('second', Text));
  Assert.Contains(Text, '==== 2026-11-13 10:01:00');
  Assert.Contains(Text, '==== 2026-11-13 10:03:00');
end;

procedure TTestXcomErrorLog.DovrebbeConservareIlContenutoGiaPresente;
begin
  FFiles.Put('user\xcom_errors.log', 'old line' + sLineBreak);
  Assert.IsTrue(FLog.Write(NewEntry('boom')));
  Assert.IsTrue(Text.StartsWith('old line' + sLineBreak));
  Assert.Contains(Text, 'boom');
end;

procedure TTestXcomErrorLog.DovrebbeScrivereUnaVoceSenzaStati;
var
  LEntry: TXcomErrorEntry;
begin
  LEntry := NewEntry('before the game');
  LEntry.States := nil;
  Assert.IsTrue(FLog.Write(LEntry));
  Assert.Contains(Text, 'states: ' + sLineBreak);
end;

procedure TTestXcomErrorLog.DovrebbeDareFalsoESpiegareSeLaScritturaFallisce;
var
  LFiles: IXcomFileSystem;
  LLog: TXcomErrorLog;
  LWritten: Boolean;
begin
  LFiles := TUnwritableFileSystem.Create;
  LLog := TXcomErrorLog.Create(LFiles, 'x.log', function: string begin Result := 't'; end);
  try
    LWritten := LLog.Write(NewEntry('boom'));
    Assert.IsFalse(LWritten);
    Assert.Contains(LLog.LastError, 'disk full');
    Assert.Contains(LLog.LastError, 'EInOutError');
  finally
    LLog.Free;
  end;
end;

procedure TTestXcomErrorLog.DovrebbeAzzerareLUltimoErroreDopoUnaScritturaRiuscita;
var
  LFiles: IXcomFileSystem;
  LLog: TXcomErrorLog;
begin
  LFiles := TUnwritableFileSystem.Create;
  LLog := TXcomErrorLog.Create(LFiles, 'x.log', function: string begin Result := 't'; end);
  try
    LLog.Write(NewEntry('boom'));
    Assert.IsTrue(LLog.LastError <> '');
  finally
    LLog.Free;
  end;
  Assert.IsTrue(FLog.Write(NewEntry('a')));
  Assert.AreEqual('', FLog.LastError);
end;

procedure TTestXcomErrorLog.DovrebbeRifiutareIParametriNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomErrorLog.Create(nil, 'x.log', function: string begin Result := ''; end).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomErrorLog.Create(FFilesRef, 'x.log', nil).Free;
    end, EArgumentNilException);
end;

procedure TTestXcomErrorLog.DovrebbeScrivereLEccezioneDelCicloConLaPilaDegliStati;
var
  LWorld: TTestWorld;
  LState: TFailingState;
  LEntry: TXcomErrorEntry;
  LCaught: Boolean;
begin
  LWorld := TTestWorld.Create;
  try
    LState := TFailingState.Create(LWorld.Game);
    LWorld.Game.PushState(LState);
    LCaught := False;
    // the loop of Xcom32: the entry is written where the game is still alive, then the error goes on
    try
      LWorld.Wait(50);
    except
      on E: Exception do
      begin
        LCaught := True;
        LEntry.ExceptionClass := E.ClassName;
        LEntry.ExceptionMessage := E.Message;
        LEntry.States := LWorld.Game.StateNames;
        LEntry.Version := 'v';
        Assert.IsTrue(FLog.Write(LEntry));
      end;
    end;
    Assert.IsTrue(LCaught);
    Assert.Contains(Text, 'error: EProbeError: probe failure');
    Assert.Contains(Text, 'states: TFailingState');
    Assert.Contains(Text, 'version: v');
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomErrorLog.NonDovrebbeNascondereLErroreOriginaleSeLeOpzioniNonSiScrivono;
var
  LWorld: TTestWorld;
  LStore: IXcomOptionsStore;
  LOriginal: string;
begin
  LWorld := TTestWorld.Create;
  LStore := TFailingOptionsStore.Create;
  try
    LWorld.Game.SetOptionsStore(LStore);
    LWorld.Game.PushState(TFailingState.Create(LWorld.Game));
    LOriginal := '';
    try
      try
        LWorld.Wait(50);
      except
        on E: Exception do
        begin
          FLog.Write(NewEntry(E.Message));
          LWorld.Game.SaveOptionsAfterFailure;
          raise;
        end;
      end;
    except
      on E: Exception do
        LOriginal := E.ClassName + ': ' + E.Message;
    end;
    // the options did not write, the error that went on is still the original one, and the file has it
    Assert.AreEqual('EProbeError: probe failure', LOriginal);
    Assert.Contains(LWorld.Game.OptionsSaveError, 'options.cfg is locked');
    Assert.Contains(Text, 'probe failure');
  finally
    LWorld.Game.SetOptionsStore(nil);
    LStore := nil;
    LWorld.Free;
  end;
end;

procedure TTestXcomErrorLog.DovrebbeDareIStatiConQuelloInCimaPerPrimo;
var
  LWorld: TTestWorld;
  LNames: TArray<string>;
begin
  LWorld := TTestWorld.Create;
  try
    Assert.AreEqual(0, Length(LWorld.Game.StateNames));
    LWorld.Game.PushState(TThinkingState.Create(LWorld.Game));
    LWorld.Game.PushState(TFailingState.Create(LWorld.Game));
    LNames := LWorld.Game.StateNames;
    Assert.AreEqual(2, Length(LNames));
    Assert.AreEqual('TFailingState', LNames[0]);
    Assert.AreEqual('TThinkingState', LNames[1]);
  finally
    LWorld.Free;
  end;
end;

end.
