{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the fakes of the client     }
{  services (sound, cinematics, the system of the client) and the rig that      }
{  builds the hosts of cgame and ui on them                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientSupport;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Intf, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Scanner.Q3.GlobalDefines,
  DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Types,
  DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.Client.Services, DelphiDoom.Q3Host.ClientState,
  DelphiDoom.Q3Host.ClientKeys, DelphiDoom.Q3Host.ClientCdKey, DelphiDoom.Q3Host.ClientRecordingRenderer,
  DelphiDoom.Q3Host.LanServers;

type
  /// <summary>Records the sound calls as lines of text; the sounds get the numbers 1, 2 ... in the order of registration</summary>
  TQ3FakeSound = class(TInterfacedObject, IQ3HostSound)
  strict private
    FCalls: TStringList;
    FNames: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function RegisterSound(const AName: AnsiString; ACompressed: Boolean): Integer;
    procedure StartSound(AOrigin: PQ3HostVec3; AEntityNumber, AEntityChannel, ASfx: Integer);
    procedure StartLocalSound(ASfx, AChannelNumber: Integer);
    procedure ClearLoopingSounds(AKillAll: Boolean);
    procedure AddLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
    procedure AddRealLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
    procedure StopLoopingSound(AEntityNumber: Integer);
    procedure UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3HostVec3);
    procedure Respatialize(AEntityNumber: Integer; const AHead: TQ3HostVec3; const AAxis: TQ3HostAxis;
      AInWater: Integer);
    procedure StartBackgroundTrack(const AIntro, ALoop: AnsiString);
    procedure StopBackgroundTrack;
    property Calls: TStringList read FCalls;
  end;

  /// <summary>Hands out handles and answers a fixed status</summary>
  TQ3FakeCinematics = class(TInterfacedObject, IQ3HostCinematics)
  strict private
    FCalls: TStringList;
    FStatus: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Play(const AName: AnsiString; AX, AY, AWidth, AHeight, ASystemBits: Integer): Integer;
    function Stop(AHandle: Integer): Integer;
    function Run(AHandle: Integer): Integer;
    procedure Draw(AHandle: Integer);
    procedure SetExtents(AHandle, AX, AY, AWidth, AHeight: Integer);
    property Calls: TStringList read FCalls;
    property Status: Integer read FStatus write FStatus;
  end;

  TQ3FakeClientSystem = class(TInterfacedObject, IQ3HostClientSystem)
  strict private
    FUpdates: Integer;
    FClipboard: AnsiString;
  public
    function MemoryRemaining: Integer;
    procedure UpdateScreen;
    function ClipboardText: AnsiString;
    property Updates: Integer read FUpdates;
    property Clipboard: AnsiString read FClipboard write FClipboard;
  end;

  TQ3FakeConnection = class(TInterfacedObject, IQ3HostUiConnection)
  strict private
    FState: TQ3HostUiClientState;
  public
    function GetClientState: TQ3HostUiClientState;
    property State: TQ3HostUiClientState read FState write FState;
  end;

  /// <summary>
  ///   The hosts of cgame and ui with every client service: the real state, keys, server lists and recording renderer,
  ///   the fakes for the rest. Machines run a program with a large image that does nothing but pass its arguments to
  ///   the system call, so the tests call the handlers directly
  /// </summary>
  TQ3ClientRig = class
  strict private
    FConsole: TQ3Console;
    FServices: TQ3HostClientServices;
    FHosts: array[TQ3Module] of IQ3SyscallHost;
    FMachines: array[TQ3Module] of IQvmMachine;
    FGlobals: TQ3GlobalDefines;
    FFiles: TQ3FakeGameFileSystem;
    FFilesIntf: IGameFileSystem;
    FState: TQ3ClientState;
    FKeys: TQ3ClientKeys;
    FLan: TQ3LanServers;
    FRenderer: TQ3RecordingRenderer;
    FSound: TQ3FakeSound;
    FCinematics: TQ3FakeCinematics;
    FSystem: TQ3FakeClientSystem;
    FConnection: TQ3FakeConnection;
    FCdKey: TQ3ClientCdKey;
    FSources: TQ3SourceHandles;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A file the parser can load (PC_LoadSourceHandle)</summary>
    procedure AddScriptFile(const AName, AText: string);
    function Call(AModule: TQ3Module; const AValues: array of Integer): Integer;
    function Memory(AModule: TQ3Module): IQvmMemory;
    function Machine(AModule: TQ3Module): IQvmMachine;
    function Host(AModule: TQ3Module): IQ3SyscallHost;
    property Console: TQ3Console read FConsole;
    property Services: TQ3HostClientServices read FServices;
    property State: TQ3ClientState read FState;
    property Keys: TQ3ClientKeys read FKeys;
    property Lan: TQ3LanServers read FLan;
    property Renderer: TQ3RecordingRenderer read FRenderer;
    property Sound: TQ3FakeSound read FSound;
    property Cinematics: TQ3FakeCinematics read FCinematics;
    property ClientSystem: TQ3FakeClientSystem read FSystem;
    property Connection: TQ3FakeConnection read FConnection;
    property CdKey: TQ3ClientCdKey read FCdKey;
  end;

  /// <summary>The program of the rig</summary>
  TQ3ClientPrograms = class
  public
    const
      IMAGE_SIZE = 131072;
    class function Pass: TBytes; static;
    /// <summary>A program whose entry point returns the value whatever it is asked (UI_HASUNIQUECDKEY)</summary>
    class function Constant(AValue: Integer): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Qvm.Factory, DelphiDoom.Qvm.Opcodes, DelphiDoom.Q3Host.Factory, DelphiDoom.Scanner.Q3.ScriptLoader,
  DelphiDoom.Scanner.Q3.Types, DelphiDoom.Tests.Qvm.Assembler, DelphiDoom.Tests.Qvm.Programs,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Q3Host.ScriptFiles, DelphiDoom.Q3Host.GameFiles,
  DelphiDoom.Q3Host.ClipMap;

{ TQ3FakeSound }

constructor TQ3FakeSound.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
  FNames := TStringList.Create;
end;

destructor TQ3FakeSound.Destroy;
begin
  FCalls.Free;
  FNames.Free;
  inherited Destroy;
end;

function TQ3FakeSound.RegisterSound(const AName: AnsiString; ACompressed: Boolean): Integer;
begin
  FCalls.Add(Format('register %s %d', [AName, Ord(ACompressed)]));
  Result := FNames.IndexOf(string(AName));
  if Result < 0 then
    Result := FNames.Add(string(AName));
  Inc(Result);
end;

procedure TQ3FakeSound.StartSound(AOrigin: PQ3HostVec3; AEntityNumber, AEntityChannel, ASfx: Integer);
begin
  if AOrigin = nil then
    FCalls.Add(Format('start follow %d %d %d', [AEntityNumber, AEntityChannel, ASfx]))
  else
    FCalls.Add(Format('start %g %g %g %d %d %d', [AOrigin^[0], AOrigin^[1], AOrigin^[2], AEntityNumber,
      AEntityChannel, ASfx], TFormatSettings.Invariant));
end;

procedure TQ3FakeSound.StartLocalSound(ASfx, AChannelNumber: Integer);
begin
  FCalls.Add(Format('local %d %d', [ASfx, AChannelNumber]));
end;

procedure TQ3FakeSound.ClearLoopingSounds(AKillAll: Boolean);
begin
  FCalls.Add(Format('clearloops %d', [Ord(AKillAll)]));
end;

procedure TQ3FakeSound.AddLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
begin
  FCalls.Add(Format('loop %d %g %g %g %g %g %g %d', [AEntityNumber, AOrigin[0], AOrigin[1], AOrigin[2], AVelocity[0],
    AVelocity[1], AVelocity[2], ASfx], TFormatSettings.Invariant));
end;

procedure TQ3FakeSound.AddRealLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3;
  ASfx: Integer);
begin
  FCalls.Add(Format('realloop %d %g %g %g %d', [AEntityNumber, AOrigin[0], AOrigin[1], AOrigin[2], ASfx],
    TFormatSettings.Invariant));
end;

procedure TQ3FakeSound.StopLoopingSound(AEntityNumber: Integer);
begin
  FCalls.Add(Format('stoploop %d', [AEntityNumber]));
end;

procedure TQ3FakeSound.UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3HostVec3);
begin
  FCalls.Add(Format('position %d %g %g %g', [AEntityNumber, AOrigin[0], AOrigin[1], AOrigin[2]],
    TFormatSettings.Invariant));
end;

procedure TQ3FakeSound.Respatialize(AEntityNumber: Integer; const AHead: TQ3HostVec3; const AAxis: TQ3HostAxis;
  AInWater: Integer);
begin
  FCalls.Add(Format('respatialize %d %g %g %g axis %g %g %g %g %g %g %g %g %g water %d', [AEntityNumber, AHead[0],
    AHead[1], AHead[2], AAxis[0][0], AAxis[0][1], AAxis[0][2], AAxis[1][0], AAxis[1][1], AAxis[1][2], AAxis[2][0],
    AAxis[2][1], AAxis[2][2], AInWater], TFormatSettings.Invariant));
end;

procedure TQ3FakeSound.StartBackgroundTrack(const AIntro, ALoop: AnsiString);
begin
  FCalls.Add(Format('music %s|%s', [AIntro, ALoop]));
end;

procedure TQ3FakeSound.StopBackgroundTrack;
begin
  FCalls.Add('stopmusic');
end;

{ TQ3FakeCinematics }

constructor TQ3FakeCinematics.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
  FStatus := Q3_FMV_PLAY;
end;

destructor TQ3FakeCinematics.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

function TQ3FakeCinematics.Play(const AName: AnsiString; AX, AY, AWidth, AHeight, ASystemBits: Integer): Integer;
begin
  FCalls.Add(Format('play %s %d %d %d %d %d', [AName, AX, AY, AWidth, AHeight, ASystemBits]));
  Result := FCalls.Count - 1;
end;

function TQ3FakeCinematics.Stop(AHandle: Integer): Integer;
begin
  FCalls.Add(Format('stop %d', [AHandle]));
  Result := Q3_FMV_EOF;
end;

function TQ3FakeCinematics.Run(AHandle: Integer): Integer;
begin
  FCalls.Add(Format('run %d', [AHandle]));
  Result := FStatus;
end;

procedure TQ3FakeCinematics.Draw(AHandle: Integer);
begin
  FCalls.Add(Format('draw %d', [AHandle]));
end;

procedure TQ3FakeCinematics.SetExtents(AHandle, AX, AY, AWidth, AHeight: Integer);
begin
  FCalls.Add(Format('extents %d %d %d %d %d', [AHandle, AX, AY, AWidth, AHeight]));
end;

{ TQ3FakeClientSystem }

function TQ3FakeClientSystem.MemoryRemaining: Integer;
begin
  Result := Q3_HUNK_FREE;
end;

procedure TQ3FakeClientSystem.UpdateScreen;
begin
  Inc(FUpdates);
end;

function TQ3FakeClientSystem.ClipboardText: AnsiString;
begin
  Result := FClipboard;
end;

{ TQ3FakeConnection }

function TQ3FakeConnection.GetClientState: TQ3HostUiClientState;
begin
  Result := FState;
end;

{ TQ3ClientPrograms }

class function TQ3ClientPrograms.Pass: TBytes;
const
  FRAME = 32;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Data([0]);
    LAssembler.Op(OP_ENTER, FRAME);
    TQvmPrograms.Argument(LAssembler, FRAME, 2);
    LAssembler.Op(OP_ARG, 8);
    TQvmPrograms.Argument(LAssembler, FRAME, 3);
    LAssembler.Op(OP_ARG, 12);
    TQvmPrograms.Argument(LAssembler, FRAME, 4);
    LAssembler.Op(OP_ARG, 16);
    // the address of the system call is -1 - number
    LAssembler.Op(OP_CONST, -1);
    TQvmPrograms.Argument(LAssembler, FRAME, 1);
    LAssembler.Op(OP_SUB);
    LAssembler.Op(OP_CALL);
    LAssembler.Op(OP_LEAVE, FRAME);
    LAssembler.ImageSize(IMAGE_SIZE);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

class function TQ3ClientPrograms.Constant(AValue: Integer): TBytes;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Data([0]);
    LAssembler.Op(OP_ENTER, 8);
    LAssembler.Op(OP_CONST, AValue);
    LAssembler.Op(OP_LEAVE, 8);
    LAssembler.ImageSize(IMAGE_SIZE);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

{ TQ3ClientRig }

procedure TQ3ClientRig.AddScriptFile(const AName, AText: string);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.ANSI.GetBytes(AText);
  FFiles.Add(AName, LBytes);
end;

constructor TQ3ClientRig.Create;
var
  LModule: TQ3Module;
  LServices: TQ3HostServices;
begin
  inherited Create;
  FConsole := TQ3Console.Create;
  FConsole.Init;
  FConsole.CVars.Get('sv_maxclients', '8', 0);

  FFiles := TQ3FakeGameFileSystem.Create;
  FFilesIntf := FFiles;
  FGlobals := TQ3GlobalDefines.Create;
  FSources := TQ3SourceHandles.Create(TQ3ScriptLoader.Create(TQ3HostScriptFiles.Create(FFilesIntf), nil), nil,
    FGlobals);
  FState := TQ3ClientState.Create(FConsole.Arguments);
  FKeys := TQ3ClientKeys.Create(FConsole.CVars);
  FLan := TQ3LanServers.Create;
  FRenderer := TQ3RecordingRenderer.Create;
  FSound := TQ3FakeSound.Create;
  FCinematics := TQ3FakeCinematics.Create;
  FSystem := TQ3FakeClientSystem.Create;
  FConnection := TQ3FakeConnection.Create;
  FCdKey := TQ3ClientCdKey.Create;

  FServices := Default(TQ3HostClientServices);
  FServices.State := FState;
  FServices.Connection := FConnection;
  FServices.ClientSystem := FSystem;
  FServices.Keys := FKeys;
  FServices.Sound := FSound;
  FServices.Cinematics := FCinematics;
  FServices.Renderer := FRenderer;
  FServices.Lan := FLan;
  FServices.CdKey := FCdKey;
  FServices.Sources := FSources;

  LServices := Default(TQ3HostServices);
  LServices.CVars := FConsole.CVars;
  LServices.Arguments := FConsole.Arguments;
  LServices.Buffer := FConsole.Buffer;
  LServices.Commands := FConsole.Commands;
  LServices.Client := FServices;
  // the services of phase 2b that cgame and ui use too (files, the clipmap, the real time)
  LServices.Files := TQ3GameHostFiles.Create(FFilesIntf, nil);
  LServices.ClipMap := TQ3HostClipMap.Create(nil);
  LServices.Calendar := TQ3FixedCalendar.Create;
  for LModule := TQ3Module.CGame to TQ3Module.Ui do
  begin
    FHosts[LModule] := TQ3HostFactory.CreateHostWithServices(LModule, TQ3RecordingConsole.Create(nil),
      TQ3FixedTime.Create(0), LServices);
    FMachines[LModule] := TQvmFactory.CreateMachine('client', TQ3ClientPrograms.Pass, FHosts[LModule]);
  end;
end;

destructor TQ3ClientRig.Destroy;
var
  LModule: TQ3Module;
begin
  for LModule := Low(TQ3Module) to High(TQ3Module) do
  begin
    FMachines[LModule] := nil;
    FHosts[LModule] := nil;
  end;
  FServices := Default(TQ3HostClientServices);
  FSources.Free;
  FGlobals.Free;
  FFilesIntf := nil;
  FCdKey.Free;
  FConsole.Free;
  inherited Destroy;
end;

function TQ3ClientRig.Call(AModule: TQ3Module; const AValues: array of Integer): Integer;
begin
  Result := TQ3TestCalls.Invoke(FHosts[AModule], FMachines[AModule], AValues);
end;

function TQ3ClientRig.Memory(AModule: TQ3Module): IQvmMemory;
begin
  Result := FMachines[AModule].Memory;
end;

function TQ3ClientRig.Machine(AModule: TQ3Module): IQvmMachine;
begin
  Result := FMachines[AModule];
end;

function TQ3ClientRig.Host(AModule: TQ3Module): IQ3SyscallHost;
begin
  Result := FHosts[AModule];
end;

end.
