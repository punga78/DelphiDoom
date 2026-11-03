{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMikModClient                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.Client;

{
  The client is tested against a fake IMikMod that records the calls it
  receives: no audio device is ever opened. What is NOT covered here is the
  real playback (device, mixing, module formats): it needs the game running,
  see "Build e prove" in CLAUDE.md.
}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.Client;

type
  /// <summary>
  ///   Player that only writes the calls it receives into a log
  /// </summary>
  TFakeMikModPlayer = class(TInterfacedObject, IMikModPlayer)
  private
    FLog: TStrings;
    FLoadResult: Integer;
  public
    constructor Create(ALog: TStrings; ALoadResult: Integer);
    function LoadFromFile(AFileName: PAnsiChar): Integer; stdcall;
    function LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer; stdcall;
    function Play(ALoop: LongBool): Integer; stdcall;
    function Stop: Integer; stdcall;
    function SetPaused(APaused: LongBool): Integer; stdcall;
    function SetVolume(AVolume: Integer): Integer; stdcall;
    function IsPlaying: LongBool; stdcall;
    function IsPaused: LongBool; stdcall;
    function Update: Integer; stdcall;
  end;

  /// <summary>
  ///   IMikMod that writes the calls it receives into a log and answers with
  ///   the results it has been told to give
  /// </summary>
  TFakeMikMod = class(TInterfacedObject, IMikMod)
  private
    FLog: TStrings;
    FInitialized: Boolean;
    FInitializeResult: Integer;
    FCreatePlayerResult: Integer;
    FLoadResult: Integer;
    FErrorText: AnsiString;
  public
    constructor Create(ALog: TStrings);
    function GetVersion: Cardinal; stdcall;
    function Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
      AInterpolation: LongBool; AWindow: NativeUInt;
      ABufferSize: Integer): Integer; stdcall;
    procedure Shutdown; stdcall;
    function IsInitialized: LongBool; stdcall;
    function CreatePlayer(out APlayer: IMikModPlayer): Integer; stdcall;
    function GetLastError(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
    property InitializeResult: Integer read FInitializeResult write FInitializeResult;
    property CreatePlayerResult: Integer read FCreatePlayerResult write FCreatePlayerResult;
    property LoadResult: Integer read FLoadResult write FLoadResult;
    property ErrorText: AnsiString read FErrorText write FErrorText;
  end;

  [TestFixture]
  [Category('mikmod')]
  TTestMikModClient = class(TObject)
  private
    FLog: TStringList;
    FFake: TFakeMikMod;
    FMikMod: IMikMod;
    FClient: TMikModClient;
    procedure InitializeClient;
    function MakeBytes(ACount: Integer): TBytes;
    function JoinLog: string;
    procedure AssertCode(AExpected: Integer; const AAction: TProc);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutMikModRaises;
    [Test]
    procedure TestLibraryVersion;
    [Test]
    procedure TestInitializePassesTheParameters;
    [Test]
    procedure TestInitializeFailureRaisesWithLibraryText;
    [Test]
    procedure TestInitializeTwiceRaises;
    [Test]
    procedure TestCreatePlayerFailureShutsDown;
    [Test]
    procedure TestOperationsBeforeInitializeRaiseNotInitialized;
    [Test]
    procedure TestQueriesBeforeInitializeAreFalse;
    [Test]
    procedure TestLoadFromFilePassesTheAnsiPath;
    [Test]
    procedure TestLoadFromFileWithNonAnsiNameRaises;
    [Test]
    procedure TestLoadFromMemoryPassesTheSize;
    [Test]
    procedure TestLoadFailureRaisesWithLibraryText;
    [Test]
    procedure TestPlaybackCallsAreForwarded;
    [Test]
    procedure TestShutdownReleasesTheEngine;
    [Test]
    procedure TestDestroyShutsDownWhatItStarted;
    [Test]
    procedure TestDestroyDoesNotShutDownWhatItDidNotStart;
  end;

implementation

{ TFakeMikModPlayer }

constructor TFakeMikModPlayer.Create(ALog: TStrings; ALoadResult: Integer);
begin
  inherited Create;
  FLog := ALog;
  FLoadResult := ALoadResult;
end;

function TFakeMikModPlayer.LoadFromFile(AFileName: PAnsiChar): Integer;
begin
  FLog.Add('LoadFromFile ' + string(AnsiString(AFileName)));
  Result := FLoadResult;
end;

function TFakeMikModPlayer.LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer;
begin
  FLog.Add(Format('LoadFromMemory %d assigned=%s',
    [ASize, BoolToStr(Assigned(AData), True)]));
  Result := FLoadResult;
end;

function TFakeMikModPlayer.Play(ALoop: LongBool): Integer;
begin
  FLog.Add('Play ' + BoolToStr(ALoop, True));
  Result := MIKMOD_OK;
end;

function TFakeMikModPlayer.Stop: Integer;
begin
  FLog.Add('Stop');
  Result := MIKMOD_OK;
end;

function TFakeMikModPlayer.SetPaused(APaused: LongBool): Integer;
begin
  FLog.Add('SetPaused ' + BoolToStr(APaused, True));
  Result := MIKMOD_OK;
end;

function TFakeMikModPlayer.SetVolume(AVolume: Integer): Integer;
begin
  FLog.Add('SetVolume ' + IntToStr(AVolume));
  Result := MIKMOD_OK;
end;

function TFakeMikModPlayer.IsPlaying: LongBool;
begin
  Result := True;
end;

function TFakeMikModPlayer.IsPaused: LongBool;
begin
  Result := False;
end;

function TFakeMikModPlayer.Update: Integer;
begin
  FLog.Add('Update');
  Result := MIKMOD_OK;
end;

{ TFakeMikMod }

constructor TFakeMikMod.Create(ALog: TStrings);
begin
  inherited Create;
  FLog := ALog;
  FInitializeResult := MIKMOD_OK;
  FCreatePlayerResult := MIKMOD_OK;
  FLoadResult := MIKMOD_OK;
end;

function TFakeMikMod.GetVersion: Cardinal;
begin
  Result := $030105;
end;

function TFakeMikMod.Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
  AInterpolation: LongBool; AWindow: NativeUInt; ABufferSize: Integer): Integer;
begin
  FLog.Add(Format('Initialize %d %s %s %s %d %d',
    [AMixFrequency, BoolToStr(AStereo, True), BoolToStr(A16Bits, True),
    BoolToStr(AInterpolation, True), AWindow, ABufferSize]));
  if FInitialized then
    Exit(MIKMOD_ERR_ALREADY_INITIALIZED);

  Result := FInitializeResult;
  FInitialized := Result = MIKMOD_OK;
end;

procedure TFakeMikMod.Shutdown;
begin
  FLog.Add('Shutdown');
  FInitialized := False;
end;

function TFakeMikMod.IsInitialized: LongBool;
begin
  Result := FInitialized;
end;

function TFakeMikMod.CreatePlayer(out APlayer: IMikModPlayer): Integer;
begin
  APlayer := nil;
  Result := FCreatePlayerResult;
  if Result = MIKMOD_OK then
    APlayer := TFakeMikModPlayer.Create(FLog, FLoadResult);
end;

function TFakeMikMod.GetLastError(ABuffer: PAnsiChar;
  ABufferSize: Cardinal): Cardinal;
var
  LCount: Cardinal;
begin
  Result := Length(FErrorText);
  if not Assigned(ABuffer) or (ABufferSize = 0) then
    Exit;

  LCount := Result;
  if LCount > ABufferSize - 1 then
    LCount := ABufferSize - 1;
  if LCount > 0 then
    Move(PAnsiChar(FErrorText)^, ABuffer^, LCount);
  ABuffer[LCount] := #0;
end;

{ TTestMikModClient }

procedure TTestMikModClient.Setup;
begin
  FLog := TStringList.Create;
  FFake := TFakeMikMod.Create(FLog);
  // The interface keeps the fake alive; FFake is only for configuring it
  FMikMod := FFake;
  FClient := TMikModClient.Create(FMikMod);
end;

procedure TTestMikModClient.TearDown;
begin
  FreeAndNil(FClient);
  FFake := nil;
  FMikMod := nil;
  FreeAndNil(FLog);
end;

procedure TTestMikModClient.InitializeClient;
begin
  FClient.Initialize(44100, True, True, True, 7);
end;

function TTestMikModClient.MakeBytes(ACount: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(LIndex + 1);
end;

function TTestMikModClient.JoinLog: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FLog.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + FLog[LIndex];
  end;
end;

procedure TTestMikModClient.AssertCode(AExpected: Integer; const AAction: TProc);
begin
  try
    AAction();
  except
    on E: EMikModException do
    begin
      Assert.AreEqual(AExpected, E.Code);
      Exit;
    end;
  end;
  Assert.Fail('EMikModException expected');
end;

procedure TTestMikModClient.TestCreateWithoutMikModRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TMikModClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestMikModClient.TestLibraryVersion;
begin
  Assert.AreEqual('3.1.5', FClient.LibraryVersion);
end;

procedure TTestMikModClient.TestInitializePassesTheParameters;
begin
  FClient.Initialize(22050, True, False, True, 7, 4096);

  Assert.IsTrue(FClient.IsInitialized);
  Assert.AreEqual('Initialize 22050 True False True 7 4096', FLog[0]);
end;

procedure TTestMikModClient.TestInitializeFailureRaisesWithLibraryText;
begin
  FFake.InitializeResult := MIKMOD_ERR_INIT;
  FFake.ErrorText := 'no audio device';

  try
    InitializeClient;
    Assert.Fail('EMikModException expected');
  except
    on E: EMikModException do
    begin
      Assert.AreEqual(MIKMOD_ERR_INIT, E.Code);
      Assert.IsTrue(Pos('no audio device', E.Message) > 0);
    end;
  end;
  Assert.IsFalse(FClient.IsInitialized);
end;

procedure TTestMikModClient.TestInitializeTwiceRaises;
begin
  InitializeClient;

  AssertCode(MIKMOD_ERR_ALREADY_INITIALIZED,
    procedure
    begin
      InitializeClient;
    end);
end;

procedure TTestMikModClient.TestCreatePlayerFailureShutsDown;
begin
  FFake.CreatePlayerResult := MIKMOD_ERR_BUSY;

  AssertCode(MIKMOD_ERR_BUSY,
    procedure
    begin
      InitializeClient;
    end);

  Assert.IsFalse(FClient.IsInitialized);
  Assert.AreEqual('Shutdown', FLog[FLog.Count - 1]);
end;

procedure TTestMikModClient.TestOperationsBeforeInitializeRaiseNotInitialized;
begin
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.LoadFromMemory(MakeBytes(3));
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.LoadFromFile('song.s3m');
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.Play;
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.Stop;
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.Pause;
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.Resume;
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.SetVolume(64);
    end);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.Update;
    end);
end;

procedure TTestMikModClient.TestQueriesBeforeInitializeAreFalse;
begin
  Assert.IsFalse(FClient.IsInitialized);
  Assert.IsFalse(FClient.IsPlaying);
  Assert.IsFalse(FClient.IsPaused);
  Assert.AreEqual('', FClient.LastErrorText);
end;

procedure TTestMikModClient.TestLoadFromFilePassesTheAnsiPath;
begin
  InitializeClient;
  FClient.LoadFromFile('music\song.s3m');

  Assert.AreEqual('LoadFromFile music\song.s3m', FLog[FLog.Count - 1]);
end;

procedure TTestMikModClient.TestLoadFromFileWithNonAnsiNameRaises;
var
  LName: string;
begin
  // Thai letters: outside the code pages of Western and most other systems
  LName := #$0E01#$0E02#$0E03'.s3m';
  if string(AnsiString(LName)) = LName then
  begin
    Assert.Pass('The ANSI code page of this system can write the name');
    Exit;
  end;

  InitializeClient;
  AssertCode(MIKMOD_ERR_INVALID_ARGUMENT,
    procedure
    begin
      FClient.LoadFromFile(LName);
    end);
end;

procedure TTestMikModClient.TestLoadFromMemoryPassesTheSize;
begin
  InitializeClient;
  FClient.LoadFromMemory(MakeBytes(5));

  Assert.AreEqual('LoadFromMemory 5 assigned=True', FLog[FLog.Count - 1]);
end;

procedure TTestMikModClient.TestLoadFailureRaisesWithLibraryText;
begin
  FFake.LoadResult := MIKMOD_ERR_LOAD_MODULE;
  FFake.ErrorText := 'not a module';
  InitializeClient;

  try
    FClient.LoadFromMemory(MakeBytes(3));
    Assert.Fail('EMikModException expected');
  except
    on E: EMikModException do
    begin
      Assert.AreEqual(MIKMOD_ERR_LOAD_MODULE, E.Code);
      Assert.IsTrue(Pos('not a module', E.Message) > 0);
    end;
  end;
end;

procedure TTestMikModClient.TestPlaybackCallsAreForwarded;
begin
  InitializeClient;
  FLog.Clear;

  FClient.Play(False);
  FClient.Pause;
  FClient.Resume;
  FClient.SetVolume(96);
  FClient.Update;
  FClient.Stop;

  Assert.AreEqual('Play False,SetPaused True,SetPaused False,SetVolume 96,' +
    'Update,Stop', JoinLog);
  Assert.IsTrue(FClient.IsPlaying);
  Assert.IsFalse(FClient.IsPaused);
end;

procedure TTestMikModClient.TestShutdownReleasesTheEngine;
begin
  InitializeClient;
  FClient.Shutdown;

  Assert.IsFalse(FClient.IsInitialized);
  Assert.AreEqual('Shutdown', FLog[FLog.Count - 1]);
  AssertCode(MIKMOD_ERR_NOT_INITIALIZED,
    procedure
    begin
      FClient.Play;
    end);
end;

procedure TTestMikModClient.TestDestroyShutsDownWhatItStarted;
begin
  InitializeClient;
  FreeAndNil(FClient);

  Assert.AreEqual('Shutdown', FLog[FLog.Count - 1]);
end;

procedure TTestMikModClient.TestDestroyDoesNotShutDownWhatItDidNotStart;
begin
  FreeAndNil(FClient);

  Assert.AreEqual(0, FLog.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMikModClient);

end.
