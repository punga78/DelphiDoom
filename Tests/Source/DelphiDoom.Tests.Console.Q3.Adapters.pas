{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the library implementations of the contracts of   }
{  the Quake III console (DUnitX)                                              }
{                                                                              }
{  Log on ILog, files on IGameFileSystem, the lines nobody handles, the info   }
{  strings of Libs\Net, Cmd_ArgvBuffer and Cmd_ArgsBuffer, and the input line  }
{  without its optional parts.                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.Adapters;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Console.Q3.CommandArguments, DelphiDoom.Console.Q3.LogAdapter, DelphiDoom.Console.Q3.GameFileSystem,
  DelphiDoom.Console.Q3.UnhandledCommands, DelphiDoom.Console.Q3.Factory, DelphiDoom.Console.Q3.Field.Types,
  DelphiDoom.Console.Q3.Field.Intf, DelphiDoom.Console.Q3.Field.Editor, DelphiDoom.Console.Q3.Field.History, DelphiDoom.Console.Q3.Field.Completer,
  DelphiDoom.Console.Q3.ConsoleInput, DelphiDoom.Net.Q3.ConsoleInfoWriter, DelphiDoom.Tests.Console.Q3.Fakes,
  DelphiDoom.Tests.Console.Q3.FieldHost;

type
  /// <summary>An ILog that keeps the lines</summary>
  TRecordingLog = class(TInterfacedObject, ILog)
  strict private
    FInfo: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Infos: TList<string> read FInfo;
  end;

  /// <summary>An IGameFileSystem with one file; the rest of the contract does nothing</summary>
  TOneFileSystem = class(TInterfacedObject, IGameFileSystem)
  strict private
    FName: string;
    FData: TBytes;
  public
    constructor Create(const AName: string; const AData: TBytes);
    procedure Startup;
    procedure Restart;
    procedure Shutdown;
    function IsInitialized: Boolean;
    function OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags; const AGameDir: string): IGameFile;
    function ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
    function FileLength(const ARelativePath: string): Integer;
    function FileIsInPak(const ARelativePath: string): Boolean;
    function ListFiles(const ARelativePath, AExtension: string; ASort: Boolean; AFullRelativePath: Boolean;
      const AGameDir: string): TArray<string>;
    function ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
      const AGameDir: string): TArray<string>;
    function SearchPaths: TArray<TGameSearchPath>;
    function PackChecksums: TArray<Cardinal>;
    function AddonPackFileNames: TArray<string>;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3ConsoleLogAdapter = class(TObject)
  public
    [Test]
    procedure DovrebbeInoltrareLeStampeAlLog;
    [Test]
    procedure DovrebbeStampareLeStampeDiSviluppoSoloInModoSviluppatore;
    [Test]
    procedure DovrebbeTacereSenzaLogOSenzaModoSviluppatore;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3GameFileSystem = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIlTestoDiUnFileByteAByte;
    [Test]
    procedure DovrebbeDireFalsoPerUnFileCheNonCe;
    [Test]
    procedure DovrebbeDareUnTestoVuotoPerUnFileVuoto;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3UnhandledCommands = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaRigaAlGiocoDelClienteSeInEsecuzione;
    [Test]
    procedure DovrebbeSaltareIlGiocoDelClienteSeNonInEsecuzione;
    [Test]
    procedure DovrebbeProvareServerEInterfacciaNellOrdineDelC;
    [Test]
    procedure DovrebbeInoltrareAlServerLaRigaChenessunoPrende;
    [Test]
    procedure DovrebbeTacereSenzaNullaDaChiamare;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3ArgumentBuffers = class(TObject)
  public
    [Test]
    procedure DovrebbeTroncareUnArgomentoAllaLunghezzaMenoUno;
    [Test]
    procedure DovrebbeTroncareTuttiGliArgomenti;
    [Test]
    procedure DovrebbeDareErroreConUnBufferSenzaSpazio;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3ConsoleInfoWriter = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereUnaCoppiaEDireVeroSenzaLog;
    [Test]
    procedure DovrebbeRifiutareIlBackslashEDirloAlLog;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3ConsoleInput = class(TObject)
  strict private
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FConsole: TQ3Console;
    FEditor: TQ3FieldEditor;
    FHistory: TQ3FieldHistory;
    FCompleter: TQ3FieldCompleter;
    FInput: TQ3ConsoleInput;
    function NewHost: TFakeQ3FieldHost;
    procedure Make(const AHost: TFakeQ3FieldHost);
    procedure Type_(const AText: AnsiString);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFarEseguireUnaRigaSenzaBarraFuoriDalGioco;
    [Test]
    procedure DovrebbeMandareUnaRigaSenzaBarraComeChatInGioco;
    [Test]
    procedure DovrebbeLasciareIlCampoVuotoEFuoriDallaStoriaConUnaRigaVuota;
    [Test]
    procedure DovrebbeNonFareNullaSeNonCeIlScorrimentoNeLoStatoDelClient;
    [Test]
    procedure DovrebbeAccelerareLaRotellaConIlTastoControllo;
    [Test]
    procedure DovrebbeAggiornareLoSchermoSoloSeDisconnesso;
    [Test]
    procedure DovrebbeMandareClearConControlL;
  end;

implementation

{ TRecordingLog }

constructor TRecordingLog.Create;
begin
  inherited Create;
  FInfo := TList<string>.Create;
end;

destructor TRecordingLog.Destroy;
begin
  FInfo.Free;
  inherited Destroy;
end;

procedure TRecordingLog.Info(const AText: string);
begin
  FInfo.Add(AText);
end;

procedure TRecordingLog.Warning(const AText: string);
begin
  FInfo.Add('W:' + AText);
end;

procedure TRecordingLog.DevWarning(const AText: string);
begin
  FInfo.Add('D:' + AText);
end;

procedure TRecordingLog.Error(const AText: string);
begin
  FInfo.Add('E:' + AText);
end;

{ TOneFileSystem }

constructor TOneFileSystem.Create(const AName: string; const AData: TBytes);
begin
  inherited Create;
  FName := AName;
  FData := AData;
end;

procedure TOneFileSystem.Startup;
begin
end;

procedure TOneFileSystem.Restart;
begin
end;

procedure TOneFileSystem.Shutdown;
begin
end;

function TOneFileSystem.IsInitialized: Boolean;
begin
  Result := True;
end;

function TOneFileSystem.OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags;
  const AGameDir: string): IGameFile;
begin
  Result := nil;
end;

function TOneFileSystem.ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
begin
  Result := SameText(ARelativePath, FName);
  if Result then
    AData := FData
  else
    AData := nil;
end;

function TOneFileSystem.FileLength(const ARelativePath: string): Integer;
begin
  Result := -1;
end;

function TOneFileSystem.FileIsInPak(const ARelativePath: string): Boolean;
begin
  Result := False;
end;

function TOneFileSystem.ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TOneFileSystem.ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TOneFileSystem.SearchPaths: TArray<TGameSearchPath>;
begin
  Result := nil;
end;

function TOneFileSystem.PackChecksums: TArray<Cardinal>;
begin
  Result := nil;
end;

function TOneFileSystem.AddonPackFileNames: TArray<string>;
begin
  Result := nil;
end;

{ TTestQ3ConsoleLogAdapter }

procedure TTestQ3ConsoleLogAdapter.DovrebbeInoltrareLeStampeAlLog;
var
  LLog: TRecordingLog;
  LLogIntf: ILog;
  LAdapter: IQ3ConsoleLog;
begin
  LLog := TRecordingLog.Create;
  LLogIntf := LLog;
  LAdapter := TQ3ConsoleLogAdapter.Create(LLogIntf);
  LAdapter.Print('ciao'#10);
  Assert.AreEqual(1, LLog.Infos.Count);
  Assert.AreEqual('ciao'#10, LLog.Infos[0]);
end;

procedure TTestQ3ConsoleLogAdapter.DovrebbeStampareLeStampeDiSviluppoSoloInModoSviluppatore;
var
  LLog: TRecordingLog;
  LLogIntf: ILog;
  LDeveloper: Boolean;
  LAdapter: IQ3ConsoleLog;
begin
  LLog := TRecordingLog.Create;
  LLogIntf := LLog;
  LDeveloper := False;
  LAdapter := TQ3ConsoleLogAdapter.Create(LLogIntf,
    function: Boolean
    begin
      Result := LDeveloper;
    end);
  LAdapter.DevPrint('uno'#10);
  Assert.AreEqual(0, LLog.Infos.Count);
  LDeveloper := True;
  LAdapter.DevPrint('due'#10);
  Assert.AreEqual(1, LLog.Infos.Count);
  // no prefix: it is not a warning
  Assert.AreEqual('due'#10, LLog.Infos[0]);
end;

procedure TTestQ3ConsoleLogAdapter.DovrebbeTacereSenzaLogOSenzaModoSviluppatore;
var
  LLog: TRecordingLog;
  LLogIntf: ILog;
  LNoLog: IQ3ConsoleLog;
  LNoDeveloper: IQ3ConsoleLog;
begin
  LNoLog := TQ3ConsoleLogAdapter.Create(nil);
  LNoLog.Print('x');
  LNoLog.DevPrint('x');
  LLog := TRecordingLog.Create;
  LLogIntf := LLog;
  LNoDeveloper := TQ3ConsoleLogAdapter.Create(LLogIntf);
  LNoDeveloper.DevPrint('x');
  Assert.AreEqual(0, LLog.Infos.Count);
end;

{ TTestQ3GameFileSystem }

procedure TTestQ3GameFileSystem.DovrebbeLeggereIlTestoDiUnFileByteAByte;
var
  LFiles: IQ3FileSystem;
  LText: AnsiString;
begin
  LFiles := TQ3GameFileSystem.Create(TOneFileSystem.Create('autoexec.cfg', TBytes.Create(Ord('s'), Ord('e'), 200, 10)));
  Assert.IsTrue(LFiles.TryReadFile('autoexec.cfg', LText));
  Assert.AreEqual(4, Length(LText));
  Assert.AreEqual(200, Integer(Ord(LText[3])));
end;

procedure TTestQ3GameFileSystem.DovrebbeDireFalsoPerUnFileCheNonCe;
var
  LFiles: IQ3FileSystem;
  LText: AnsiString;
begin
  LFiles := TQ3GameFileSystem.Create(TOneFileSystem.Create('a.cfg', TBytes.Create(1)));
  Assert.IsFalse(LFiles.TryReadFile('b.cfg', LText));
  Assert.AreEqual('', string(LText));
end;

procedure TTestQ3GameFileSystem.DovrebbeDareUnTestoVuotoPerUnFileVuoto;
var
  LFiles: IQ3FileSystem;
  LText: AnsiString;
begin
  LFiles := TQ3GameFileSystem.Create(TOneFileSystem.Create('a.cfg', nil));
  Assert.IsTrue(LFiles.TryReadFile('a.cfg', LText));
  Assert.AreEqual('', string(LText));
end;

{ TTestQ3UnhandledCommands }

procedure TTestQ3UnhandledCommands.DovrebbeDareLaRigaAlGiocoDelClienteSeInEsecuzione;
var
  LChain: IQ3UnhandledCommands;
  LCalls: string;
begin
  LCalls := '';
  LChain := TQ3UnhandledCommands.Create(
    function: Boolean begin Result := True; end,
    function: Boolean begin Result := True; end,
    function: Boolean begin LCalls := LCalls + 'C'; Result := True; end,
    function: Boolean begin LCalls := LCalls + 'S'; Result := True; end,
    function: Boolean begin LCalls := LCalls + 'U'; Result := True; end,
    procedure(AText: AnsiString) begin LCalls := LCalls + 'F'; end);
  Assert.IsTrue(LChain.Execute('x'));
  Assert.AreEqual('C', LCalls);
end;

procedure TTestQ3UnhandledCommands.DovrebbeSaltareIlGiocoDelClienteSeNonInEsecuzione;
var
  LChain: IQ3UnhandledCommands;
  LCalls: string;
begin
  LCalls := '';
  LChain := TQ3UnhandledCommands.Create(
    function: Boolean begin Result := False; end,
    function: Boolean begin Result := True; end,
    function: Boolean begin LCalls := LCalls + 'C'; Result := True; end,
    function: Boolean begin LCalls := LCalls + 'S'; Result := True; end,
    function: Boolean begin LCalls := LCalls + 'U'; Result := True; end,
    procedure(AText: AnsiString) begin LCalls := LCalls + 'F'; end);
  Assert.IsTrue(LChain.Execute('x'));
  Assert.AreEqual('S', LCalls);
end;

procedure TTestQ3UnhandledCommands.DovrebbeProvareServerEInterfacciaNellOrdineDelC;
var
  LChain: IQ3UnhandledCommands;
  LCalls: string;
begin
  LCalls := '';
  LChain := TQ3UnhandledCommands.Create(
    function: Boolean begin Result := True; end,
    function: Boolean begin Result := True; end,
    function: Boolean begin LCalls := LCalls + 'C'; Result := False; end,
    function: Boolean begin LCalls := LCalls + 'S'; Result := False; end,
    function: Boolean begin LCalls := LCalls + 'U'; Result := True; end,
    procedure(AText: AnsiString) begin LCalls := LCalls + 'F'; end);
  Assert.IsTrue(LChain.Execute('x'));
  Assert.AreEqual('CSU', LCalls);
end;

procedure TTestQ3UnhandledCommands.DovrebbeInoltrareAlServerLaRigaChenessunoPrende;
var
  LChain: IQ3UnhandledCommands;
  LForwarded: string;
begin
  LForwarded := '';
  LChain := TQ3UnhandledCommands.Create(nil, nil, nil, nil, nil,
    procedure(AText: AnsiString) begin LForwarded := string(AText); end);
  Assert.IsFalse(LChain.Execute('say ciao'));
  Assert.AreEqual('say ciao', LForwarded);
end;

procedure TTestQ3UnhandledCommands.DovrebbeTacereSenzaNullaDaChiamare;
var
  LChain: IQ3UnhandledCommands;
begin
  LChain := TQ3UnhandledCommands.Create(nil, nil, nil, nil, nil, nil);
  Assert.IsFalse(LChain.Execute('x'));
end;

{ TTestQ3ArgumentBuffers }

procedure TTestQ3ArgumentBuffers.DovrebbeTroncareUnArgomentoAllaLunghezzaMenoUno;
var
  LArguments: IQ3CommandArguments;
begin
  LArguments := TQ3CommandArguments.Create;
  LArguments.Tokenize('cmd abcdefgh');
  Assert.AreEqual('abc', string(LArguments.ArgvBuffer(1, 4)));
  Assert.AreEqual('', string(LArguments.ArgvBuffer(1, 1)));
  Assert.AreEqual('abcdefgh', string(LArguments.ArgvBuffer(1, 100)));
  Assert.AreEqual('', string(LArguments.ArgvBuffer(7, 100)));
end;

procedure TTestQ3ArgumentBuffers.DovrebbeTroncareTuttiGliArgomenti;
var
  LArguments: IQ3CommandArguments;
begin
  LArguments := TQ3CommandArguments.Create;
  LArguments.Tokenize('cmd one two');
  Assert.AreEqual('one t', string(LArguments.ArgsBuffer(6)));
end;

procedure TTestQ3ArgumentBuffers.DovrebbeDareErroreConUnBufferSenzaSpazio;
var
  LArguments: IQ3CommandArguments;
begin
  LArguments := TQ3CommandArguments.Create;
  Assert.WillRaise(
    procedure
    begin
      LArguments.ArgvBuffer(0, 0);
    end, EQ3ConsoleException);
  Assert.WillRaise(
    procedure
    begin
      LArguments.ArgsBuffer(-3);
    end, EQ3ConsoleException);
end;

{ TTestQ3ConsoleInfoWriter }

procedure TTestQ3ConsoleInfoWriter.DovrebbeScrivereUnaCoppiaEDireVeroSenzaLog;
var
  LWriter: IQ3InfoStringWriter;
  LInfo: AnsiString;
begin
  LWriter := TQ3ConsoleInfoWriter.Create;
  LInfo := '';
  Assert.IsTrue(LWriter.SetValueForKey(LInfo, 'name', 'Anna', False));
  Assert.AreEqual('\name\Anna', string(LInfo));
  Assert.IsFalse(LWriter.SetValueForKey(LInfo, 'a;b', 'x', False));
end;

procedure TTestQ3ConsoleInfoWriter.DovrebbeRifiutareIlBackslashEDirloAlLog;
var
  LLog: TFakeQ3Log;
  LLogIntf: IQ3ConsoleLog;
  LWriter: IQ3InfoStringWriter;
  LInfo: AnsiString;
begin
  LLog := TFakeQ3Log.Create;
  LLogIntf := LLog;
  LWriter := TQ3ConsoleInfoWriter.Create(LLogIntf);
  LInfo := '';
  Assert.IsFalse(LWriter.SetValueForKey(LInfo, 'a', 'b\c', False));
  Assert.AreEqual('Can''t use keys or values with a \'#10, LLog.TakePrinted);
end;

{ TTestQ3ConsoleInput }

function TTestQ3ConsoleInput.NewHost: TFakeQ3FieldHost;
begin
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  Result := TFakeQ3FieldHost.Create(FLogIntf);
end;

procedure TTestQ3ConsoleInput.Make(const AHost: TFakeQ3FieldHost);
begin
  if not Assigned(FLog) then
  begin
    FLog := TFakeQ3Log.Create;
    FLogIntf := FLog;
  end;
  FConsole := TQ3Console.Create(FLogIntf);
  FConsole.Init;
  FEditor := TQ3FieldEditor.Create;
  FHistory := TQ3FieldHistory.Create;
  FCompleter := TQ3FieldCompleter.Create(FConsole.Arguments, FConsole.Commands, FConsole.CVars, FLogIntf);
  if Assigned(AHost) then
    FInput := TQ3ConsoleInput.Create(FConsole.Buffer, FEditor, FHistory, FCompleter, FLogIntf, AHost, AHost, AHost)
  else
    FInput := TQ3ConsoleInput.Create(FConsole.Buffer, FEditor, FHistory, FCompleter, FLogIntf);
end;

procedure TTestQ3ConsoleInput.Type_(const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    FInput.Character(Ord(AText[LIndex]));
end;

procedure TTestQ3ConsoleInput.TearDown;
begin
  FInput.Free;
  FCompleter.Free;
  FHistory.Free;
  FEditor.Free;
  FConsole.Free;
  FInput := nil;
  FCompleter := nil;
  FHistory := nil;
  FEditor := nil;
  FConsole := nil;
  FLogIntf := nil;
  FLog := nil;
end;

procedure TTestQ3ConsoleInput.DovrebbeFarEseguireUnaRigaSenzaBarraFuoriDalGioco;
begin
  Make(nil);
  Type_('echo ciao');
  FInput.Key(Q3_K_ENTER);
  Assert.AreEqual(']\echo ciao'#10, FLog.TakePrinted);
  Assert.AreEqual('echo ciao'#10, string(FConsole.Buffer.Pending));
  Assert.AreEqual('', string(FInput.Field.Text));
end;

procedure TTestQ3ConsoleInput.DovrebbeMandareUnaRigaSenzaBarraComeChatInGioco;
var
  LHost: TFakeQ3FieldHost;
  LKeep: IQ3KeyState;
begin
  LHost := NewHost;
  LKeep := LHost;
  LHost.SetConnection(True, False);
  Make(LHost);
  Type_('ciao a tutti');
  FInput.Key(Q3_K_KP_ENTER);
  Assert.AreEqual('cmd say ciao a tutti'#10, string(FConsole.Buffer.Pending));
end;

procedure TTestQ3ConsoleInput.DovrebbeLasciareIlCampoVuotoEFuoriDallaStoriaConUnaRigaVuota;
var
  LHost: TFakeQ3FieldHost;
  LKeep: IQ3KeyState;
begin
  LHost := NewHost;
  LKeep := LHost;
  LHost.SetConnection(True, False);
  Make(LHost);
  FInput.Key(Q3_K_ENTER);
  Assert.AreEqual(0, FHistory.NextLine);
  Assert.AreEqual('', string(FConsole.Buffer.Pending));
end;

procedure TTestQ3ConsoleInput.DovrebbeNonFareNullaSeNonCeIlScorrimentoNeLoStatoDelClient;
begin
  Make(nil);
  FInput.Key(Q3_K_PGUP);
  FInput.Key(Q3_K_PGDN);
  FInput.Key(Q3_K_MWHEELUP);
  FInput.Key(Q3_K_MWHEELDOWN);
  FInput.Key(Q3_K_HOME);
  FInput.Key(Q3_K_END);
  Assert.AreEqual('', string(FLog.TakePrinted));
end;

procedure TTestQ3ConsoleInput.DovrebbeAccelerareLaRotellaConIlTastoControllo;
var
  LHost: TFakeQ3FieldHost;
  LKeep: IQ3KeyState;
begin
  LHost := NewHost;
  LKeep := LHost;
  Make(LHost);
  FInput.Key(Q3_K_MWHEELUP);
  Assert.AreEqual('[PageUp]'#10, FLog.TakePrinted);
  LHost.SetKey(Q3_K_CTRL, True);
  FInput.Key(Q3_K_MWHEELUP);
  Assert.AreEqual('[PageUp]'#10'[PageUp]'#10'[PageUp]'#10, FLog.TakePrinted);
  FInput.Key(Q3_K_MWHEELDOWN);
  Assert.AreEqual('[PageDown]'#10'[PageDown]'#10'[PageDown]'#10, FLog.TakePrinted);
  FInput.Key(Q3_K_HOME);
  FInput.Key(Q3_K_END);
  Assert.AreEqual('[Top]'#10'[Bottom]'#10, FLog.TakePrinted);
end;

procedure TTestQ3ConsoleInput.DovrebbeAggiornareLoSchermoSoloSeDisconnesso;
var
  LHost: TFakeQ3FieldHost;
  LKeep: IQ3KeyState;
begin
  LHost := NewHost;
  LKeep := LHost;
  LHost.SetConnection(False, True);
  Make(LHost);
  Type_('wait');
  FInput.Key(Q3_K_ENTER);
  Assert.AreEqual(1, LHost.Updates);
  LHost.SetConnection(False, False);
  Type_('wait');
  FInput.Key(Q3_K_ENTER);
  Assert.AreEqual(1, LHost.Updates);
end;

procedure TTestQ3ConsoleInput.DovrebbeMandareClearConControlL;
var
  LHost: TFakeQ3FieldHost;
  LKeep: IQ3KeyState;
begin
  LHost := NewHost;
  LKeep := LHost;
  Make(LHost);
  LHost.SetKey(Q3_K_CTRL, True);
  FInput.Key(Ord('l'));
  Assert.AreEqual('clear'#10, string(FConsole.Buffer.Pending));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3ConsoleLogAdapter);
  TDUnitX.RegisterTestFixture(TTestQ3GameFileSystem);
  TDUnitX.RegisterTestFixture(TTestQ3UnhandledCommands);
  TDUnitX.RegisterTestFixture(TTestQ3ArgumentBuffers);
  TDUnitX.RegisterTestFixture(TTestQ3ConsoleInfoWriter);
  TDUnitX.RegisterTestFixture(TTestQ3ConsoleInput);

end.
