{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the fakes                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.Client, DelphiDoom.Platform.Intf,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>A log that remembers what it was told, in order: "I:text", "W:text", "D:text", "E:text"</summary>
  TRecordingLog = class(TInterfacedObject, ILog)
  public
    Entries: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    /// <summary>Only the texts of the Info entries, one after the other</summary>
    function InfoText: string;
  end;

  /// <summary>A sequencer that writes the commands it receives and answers what the test says</summary>
  TFakeMciSequencer = class(TInterfacedObject, IMciSequencer)
  public
    Commands: TStringList;
    OpenResult: Cardinal;
    StatusResult: Cardinal;
    PlayResult: Cardinal;
    SeekResult: Cardinal;
    IsMapper: Boolean;
    NextDevice: Cardinal;
    constructor Create;
    destructor Destroy; override;
    function Open(const AFileName: string; out ADeviceId: Cardinal): Cardinal;
    function QueryMapperPort(ADeviceId: Cardinal; out AIsMapper: Boolean): Cardinal;
    function Play(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
    function SeekToStart(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
    procedure Stop(ADeviceId: Cardinal);
    procedure Close(ADeviceId: Cardinal);
    procedure Pause(ADeviceId: Cardinal);
    procedure Resume(ADeviceId: Cardinal);
  end;

  /// <summary>A notify window that is a number; the test calls Notify as the sequencer would</summary>
  TFakeNotifyWindow = class(TInterfacedObject, IMidiNotifyWindow)
  public
    Commands: TStringList;
    Handle: NativeUInt;
    OnNotify: TMidiNotifyEvent;
    constructor Create(AHandle: NativeUInt);
    destructor Destroy; override;
    function Open(const AOnNotify: TMidiNotifyEvent): NativeUInt;
    procedure Close(AHandle: NativeUInt);
    procedure Notify(ASuccessful: Boolean);
  end;

  /// <summary>A MikMod that writes its calls; the results are the ones that the test sets</summary>
  TRecordingMikMod = class(TInterfacedObject, IMikMod)
  public
    Calls: TStringList;
    InitializeResult: Integer;
    LoadResult: Integer;
    /// <summary>When true Stop, Update, SetVolume and the pause calls answer that nothing is loaded</summary>
    NothingLoaded: Boolean;
    Paused: Boolean;
    Initialized: Boolean;
    constructor Create;
    destructor Destroy; override;
    function GetVersion: Cardinal; stdcall;
    function Initialize(AMixFrequency: Cardinal; AStereo, A16Bits, AInterpolation: LongBool;
      AWindow: NativeUInt; ABufferSize: Integer): Integer; stdcall;
    procedure Shutdown; stdcall;
    function IsInitialized: LongBool; stdcall;
    function CreatePlayer(out APlayer: IMikModPlayer): Integer; stdcall;
    function GetLastError(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal; stdcall;
  end;

  /// <summary>The player of a TRecordingMikMod</summary>
  TRecordingMikModPlayer = class(TInterfacedObject, IMikModPlayer)
  strict private
    FOwner: TRecordingMikMod;
  public
    constructor Create(AOwner: TRecordingMikMod);
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

  /// <summary>The MikMod client that the test gives to the player, with a count of the releases</summary>
  TFakeMikModClientSource = class(TInterfacedObject, IMikModClientSource)
  strict private
    FMikMod: TRecordingMikMod;
    FMikModRef: IMikMod;
    FClient: TMikModClient;
  public
    Releases: Integer;
    constructor Create(AMikMod: TRecordingMikMod);
    destructor Destroy; override;
    function Client: TMikModClient;
    procedure Release;
  end;

  /// <summary>A processor that is what the test says</summary>
  TFakeCpu = class(TInterfacedObject, ICpuInfo)
  public
    Processors: Integer;
    Mmx: Boolean;
    ThreeDNow: Boolean;
    constructor Create(AProcessors: Integer; AMmx, AThreeDNow: Boolean);
    function ProcessorCount: Integer;
    function HasMmx: Boolean;
    function Has3DNow: Boolean;
  end;

implementation

{ TRecordingLog }

constructor TRecordingLog.Create;
begin
  inherited Create;
  Entries := TStringList.Create;
end;

destructor TRecordingLog.Destroy;
begin
  Entries.Free;
  inherited Destroy;
end;

procedure TRecordingLog.Info(const AText: string);
begin
  Entries.Add('I:' + AText);
end;

procedure TRecordingLog.Warning(const AText: string);
begin
  Entries.Add('W:' + AText);
end;

procedure TRecordingLog.DevWarning(const AText: string);
begin
  Entries.Add('D:' + AText);
end;

procedure TRecordingLog.Error(const AText: string);
begin
  Entries.Add('E:' + AText);
end;

function TRecordingLog.InfoText: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to Entries.Count - 1 do
    if Copy(Entries[LIndex], 1, 2) = 'I:' then
      Result := Result + Copy(Entries[LIndex], 3, MaxInt);
end;

{ TFakeMciSequencer }

constructor TFakeMciSequencer.Create;
begin
  inherited Create;
  Commands := TStringList.Create;
  NextDevice := 11;
  IsMapper := True;
end;

destructor TFakeMciSequencer.Destroy;
begin
  Commands.Free;
  inherited Destroy;
end;

function TFakeMciSequencer.Open(const AFileName: string; out ADeviceId: Cardinal): Cardinal;
begin
  Commands.Add('open ' + AFileName);
  Result := OpenResult;
  ADeviceId := 0;
  if Result = 0 then
  begin
    ADeviceId := NextDevice;
    Inc(NextDevice);
  end;
end;

function TFakeMciSequencer.QueryMapperPort(ADeviceId: Cardinal; out AIsMapper: Boolean): Cardinal;
begin
  Commands.Add(Format('port %d', [ADeviceId]));
  Result := StatusResult;
  AIsMapper := IsMapper;
end;

function TFakeMciSequencer.Play(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
begin
  Commands.Add(Format('play %d window=%d', [ADeviceId, ANotifyWindow]));
  Result := PlayResult;
end;

function TFakeMciSequencer.SeekToStart(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
begin
  Commands.Add(Format('seek %d window=%d', [ADeviceId, ANotifyWindow]));
  Result := SeekResult;
end;

procedure TFakeMciSequencer.Stop(ADeviceId: Cardinal);
begin
  Commands.Add(Format('stop %d', [ADeviceId]));
end;

procedure TFakeMciSequencer.Close(ADeviceId: Cardinal);
begin
  Commands.Add(Format('close %d', [ADeviceId]));
end;

procedure TFakeMciSequencer.Pause(ADeviceId: Cardinal);
begin
  Commands.Add(Format('pause %d', [ADeviceId]));
end;

procedure TFakeMciSequencer.Resume(ADeviceId: Cardinal);
begin
  Commands.Add(Format('resume %d', [ADeviceId]));
end;

{ TFakeNotifyWindow }

constructor TFakeNotifyWindow.Create(AHandle: NativeUInt);
begin
  inherited Create;
  Commands := TStringList.Create;
  Handle := AHandle;
end;

destructor TFakeNotifyWindow.Destroy;
begin
  Commands.Free;
  inherited Destroy;
end;

function TFakeNotifyWindow.Open(const AOnNotify: TMidiNotifyEvent): NativeUInt;
begin
  Commands.Add('open');
  OnNotify := AOnNotify;
  Result := Handle;
end;

procedure TFakeNotifyWindow.Close(AHandle: NativeUInt);
begin
  Commands.Add(Format('close %d', [AHandle]));
end;

procedure TFakeNotifyWindow.Notify(ASuccessful: Boolean);
begin
  OnNotify(ASuccessful);
end;

{ TRecordingMikMod }

constructor TRecordingMikMod.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
end;

destructor TRecordingMikMod.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

function TRecordingMikMod.GetVersion: Cardinal;
begin
  Result := $030105;
end;

function TRecordingMikMod.Initialize(AMixFrequency: Cardinal; AStereo, A16Bits,
  AInterpolation: LongBool; AWindow: NativeUInt; ABufferSize: Integer): Integer;
begin
  Calls.Add(Format('initialize %d %s %s %s %d %d', [AMixFrequency, BoolToStr(AStereo, True),
    BoolToStr(A16Bits, True), BoolToStr(AInterpolation, True), AWindow, ABufferSize]));
  Result := InitializeResult;
  Initialized := Result = MIKMOD_OK;
end;

procedure TRecordingMikMod.Shutdown;
begin
  Calls.Add('shutdown');
  Initialized := False;
end;

function TRecordingMikMod.IsInitialized: LongBool;
begin
  Result := Initialized;
end;

function TRecordingMikMod.CreatePlayer(out APlayer: IMikModPlayer): Integer;
begin
  APlayer := TRecordingMikModPlayer.Create(Self);
  Result := MIKMOD_OK;
end;

function TRecordingMikMod.GetLastError(ABuffer: PAnsiChar; ABufferSize: Cardinal): Cardinal;
begin
  Result := 0;
end;

{ TRecordingMikModPlayer }

constructor TRecordingMikModPlayer.Create(AOwner: TRecordingMikMod);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TRecordingMikModPlayer.LoadFromFile(AFileName: PAnsiChar): Integer;
begin
  FOwner.Calls.Add('loadfile');
  Result := FOwner.LoadResult;
end;

function TRecordingMikModPlayer.LoadFromMemory(AData: Pointer; ASize: Cardinal): Integer;
begin
  FOwner.Calls.Add(Format('load %d', [ASize]));
  Result := FOwner.LoadResult;
end;

function TRecordingMikModPlayer.Play(ALoop: LongBool): Integer;
begin
  FOwner.Calls.Add('play ' + BoolToStr(ALoop, True));
  Result := MIKMOD_OK;
end;

function TRecordingMikModPlayer.Stop: Integer;
begin
  FOwner.Calls.Add('stop');
  if FOwner.NothingLoaded then
    Result := MIKMOD_ERR_NO_MODULE
  else
    Result := MIKMOD_OK;
end;

function TRecordingMikModPlayer.SetPaused(APaused: LongBool): Integer;
begin
  FOwner.Calls.Add('paused ' + BoolToStr(APaused, True));
  FOwner.Paused := APaused;
  if FOwner.NothingLoaded then
    Result := MIKMOD_ERR_NO_MODULE
  else
    Result := MIKMOD_OK;
end;

function TRecordingMikModPlayer.SetVolume(AVolume: Integer): Integer;
begin
  FOwner.Calls.Add(Format('volume %d', [AVolume]));
  if FOwner.NothingLoaded then
    Result := MIKMOD_ERR_NO_MODULE
  else
    Result := MIKMOD_OK;
end;

function TRecordingMikModPlayer.IsPlaying: LongBool;
begin
  Result := not FOwner.Paused;
end;

function TRecordingMikModPlayer.IsPaused: LongBool;
begin
  Result := FOwner.Paused;
end;

function TRecordingMikModPlayer.Update: Integer;
begin
  FOwner.Calls.Add('update');
  if FOwner.NothingLoaded then
    Result := MIKMOD_ERR_NO_MODULE
  else
    Result := MIKMOD_OK;
end;

{ TFakeMikModClientSource }

constructor TFakeMikModClientSource.Create(AMikMod: TRecordingMikMod);
begin
  inherited Create;
  FMikMod := AMikMod;
  // the interface keeps the fake alive
  FMikModRef := AMikMod;
end;

destructor TFakeMikModClientSource.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

function TFakeMikModClientSource.Client: TMikModClient;
begin
  if not Assigned(FClient) then
    FClient := TMikModClient.Create(FMikModRef);
  Result := FClient;
end;

procedure TFakeMikModClientSource.Release;
begin
  Inc(Releases);
  FreeAndNil(FClient);
end;

{ TFakeCpu }

constructor TFakeCpu.Create(AProcessors: Integer; AMmx, AThreeDNow: Boolean);
begin
  inherited Create;
  Processors := AProcessors;
  Mmx := AMmx;
  ThreeDNow := AThreeDNow;
end;

function TFakeCpu.ProcessorCount: Integer;
begin
  Result := Processors;
end;

function TFakeCpu.HasMmx: Boolean;
begin
  Result := Mmx;
end;

function TFakeCpu.Has3DNow: Boolean;
begin
  Result := ThreeDNow;
end;

end.
