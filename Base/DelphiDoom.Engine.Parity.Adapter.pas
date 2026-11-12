{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the adapter of the parity tools                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.Adapter;

interface

uses
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Engine.Parity.FrameSource,
  DelphiDoom.Engine.Parity.Hooks,
  DelphiDoom.Engine.Parity.StateSource,
  DelphiDoom.Engine.Shutdown.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Parity.FrameHashWriter,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.SwitchClock,
  DelphiDoom.Parity.Types,
  d_ticcmd;

type
  /// <summary>
  ///   The tools that tell where and when the behavior of the engine changes: the hash of the state for every
  ///   tic (-statehash), the hash of every frame (-framehash, -framedump) and the automatic pilot
  ///   (-autodemo). It reads the command line the first time somebody asks IsActive (the clock and the
  ///   gate of the input do, early); with no option nothing is built and the engine never calls it. With an
  ///   option the run becomes repeatable: the clock counts tics, the input is closed, the unpredictable
  ///   random numbers have a fixed seed
  /// </summary>
  TEngineParity = class(TInterfacedObject, IParitySwitch, IEngineParityHooks)
  strict private
    FCommandLine: ICommandLine;
    FRandom: IGameRandom;
    FShutdown: IEngineShutdown;
    FClock: TParitySwitchClock;
    FResolved: Boolean;
    FActive: Boolean;
    FOptions: TParityOptions;
    FStateLog: IParityLog;
    FFrameLog: IParityLog;
    FStateSource: TEngineParityStateSource;
    FFrameWriter: TFrameHashWriter;
    FFrameSource: TEngineParityFrameSource;
    FPilot: IParityPilot;
    FDumped: Boolean;
    FPilotDone: Boolean;
    procedure Resolve;
    procedure Activate;
    procedure DumpFrame;
  public
    /// <summary>
    ///   AClock: the clock of the engine that is virtual when the tools are on (it must be told when a
    ///   frame ends); the adapter does not own it
    /// </summary>
    constructor Create(const ACommandLine: ICommandLine; const AShutdown: IEngineShutdown);
    destructor Destroy; override;
    /// <summary>Gives the adapter the random numbers of the game (they are made after it: they use its switch)</summary>
    procedure AttachRandom(const ARandom: IGameRandom);
    /// <summary>Gives the adapter the clock that it must move at the end of every frame</summary>
    procedure AttachClock(AClock: TParitySwitchClock);
    function IsActive: Boolean;
    procedure AfterTick;
    procedure AfterFrame;
    procedure BuildTicCmd(ACommand: Pticcmd_t);
    procedure Flush;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Engine.Parity.PilotCommand,
  DelphiDoom.Parity.BitmapWriter,
  DelphiDoom.Parity.Factory,
  DelphiDoom.Parity.OptionsParser,
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game,
  i_system;

{ TEngineParity }

constructor TEngineParity.Create(const ACommandLine: ICommandLine; const AShutdown: IEngineShutdown);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create('ACommandLine');
  if not Assigned(AShutdown) then
    raise EArgumentNilException.Create('AShutdown');
  FCommandLine := ACommandLine;
  FShutdown := AShutdown;
end;

procedure TEngineParity.AttachRandom(const ARandom: IGameRandom);
begin
  FRandom := ARandom;
end;

destructor TEngineParity.Destroy;
begin
  FStateSource.Free;
  FFrameWriter.Free;
  FFrameSource.Free;
  inherited Destroy;
end;

procedure TEngineParity.AttachClock(AClock: TParitySwitchClock);
begin
  FClock := AClock;
end;

function TEngineParity.IsActive: Boolean;
begin
  if not FResolved then
    Resolve;
  Result := FActive;
end;

procedure TEngineParity.Resolve;
var
  LArguments: TArray<string>;
  LIndex: Integer;
begin
  // until the arguments are attached the command line is empty: ask again later
  if FCommandLine.Count = 0 then
    Exit;
  FResolved := True;
  SetLength(LArguments, FCommandLine.Count);
  for LIndex := 0 to FCommandLine.Count - 1 do
    LArguments[LIndex] := FCommandLine[LIndex];
  try
    FOptions := TParityOptionsParser.Parse(LArguments);
    if FOptions.IsActive then
      Activate;
  except
    on E: EParityException do
    begin
      FActive := False;
      FShutdown.Fail(E.Message);
    end;
  end;
end;

procedure TEngineParity.Activate;
var
  LSink: IParityStateSink;
begin
  if FOptions.StateHashFile <> '' then
  begin
    FStateLog := TParityFactory.CreateFileLog(FOptions.StateHashFile);
    FStateLog.WriteLine('# paritystate v1');
    LSink := TParityFactory.CreateStateWriter(FStateLog, FOptions.StateDetail, FOptions.StateDetailFirstTic,
      FOptions.StateDetailLastTic);
    FStateSource := TEngineParityStateSource.Create(LSink, FRandom);
  end;
  FFrameSource := TEngineParityFrameSource.Create;
  if FOptions.FrameHashFile <> '' then
  begin
    FFrameLog := TParityFactory.CreateFileLog(FOptions.FrameHashFile);
    FFrameLog.WriteLine('# parityframe v1');
    FFrameWriter := TParityFactory.CreateFrameWriter(FFrameLog);
  end;
  if FOptions.AutoDemo then
    FPilot := TParityFactory.CreatePilot(FOptions);
  FActive := True;
  parity_hooks := Self;
end;

procedure TEngineParity.AfterTick;
begin
  if FStateSource <> nil then
    FStateSource.Publish(g_game.gametic);
end;

procedure TEngineParity.DumpFrame;
var
  LPixels: Pointer;
  LWidth: Integer;
  LHeight: Integer;
begin
  LPixels := FFrameSource.ReadRgb(LWidth, LHeight);
  TParityBitmapWriter.SaveToFile(FOptions.FrameDumpFile, LWidth, LHeight, LPixels);
  FDumped := True;
end;

procedure TEngineParity.AfterFrame;
var
  LPixels: Pointer;
  LBytesPerPixel: Integer;
  LLayout: TParityFrameLayout;
  LPaletteHash: UInt64;
begin
  if (FFrameWriter <> nil) and FFrameSource.Capture(LPixels, LBytesPerPixel, LLayout, LPaletteHash) then
    FFrameWriter.WriteFrame(g_game.gametic, LLayout, LPixels, LBytesPerPixel, LPaletteHash);
  if (FOptions.FrameDumpTic >= 0) and not FDumped and (g_game.gametic >= FOptions.FrameDumpTic) then
    DumpFrame;
  // the end of a frame is the time that goes by
  if FClock <> nil then
    FClock.AdvanceFrame;
end;

procedure TEngineParity.BuildTicCmd(ACommand: Pticcmd_t);
begin
  if FPilot = nil then
    Exit;
  if TEngineParityPilotCommand.Apply(FPilot, ACommand, g_game.gametic) then
    Exit;
  if FPilotDone then
    Exit;
  // the tics asked for are done: a recorded demo is closed (it is written and the game ends), else the game ends
  FPilotDone := True;
  Flush;
  if demorecording then
    G_CheckDemoStatus
  else
    I_Quit;
end;

procedure TEngineParity.Flush;
begin
  if FStateLog <> nil then
    FStateLog.Flush;
  if FFrameLog <> nil then
    FFrameLog.Flush;
end;

end.
