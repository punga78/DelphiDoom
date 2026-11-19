{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the main loop of a dedicated server         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): Com_Frame and   }
{  Com_ModifyMsec (common.c). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Quake3.DedicatedLoop;

// Overflow checks are off: the times are 32 bit ints of the C.

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Quake3.Clock.Intf, DelphiDoom.Quake3.Types;

type
  /// <summary>One step of a frame, in the order they were added; it is given the milliseconds of the frame</summary>
  TQ3FrameStage = reference to procedure(AMilliseconds: Integer);

  /// <summary>
  ///   Com_Frame of a dedicated server with the time of the clock: the loop waits until a frame of the server has
  ///   passed (minMsec is SV_FrameMsec, 1000 / sv_fps), runs the command buffer, takes the milliseconds through
  ///   Com_ModifyMsec (a warning over 500, a clamp at 5000) and runs the stages: the network of the client, the
  ///   packets of the server, SV_Frame, the packets for the client. The frame limit of the command line counts
  ///   these frames
  /// </summary>
  TQ3DedicatedLoop = class
  strict private
    const
      HITCH_MILLISECONDS = 500;
      CLAMP_MILLISECONDS = 5000;
    var
      FClock: IQ3Clock;
      FBuffer: IQ3CommandBuffer;
      FPrint: IQ3HostConsole;
      FMinMilliseconds: TFunc<Integer>;
      FStages: TList<TQ3FrameStage>;
      FFrameLimit: Integer;
      FFrames: Integer;
      FLastTime: Integer;
      FQuit: Boolean;
  public
    /// <summary>
    ///   AMinMilliseconds says how long a frame is at least (read at every frame: sv_fps may change); AFrameLimit
    ///   is Q3_FRAMES_UNLIMITED to run until Quit
    /// </summary>
    constructor Create(const AClock: IQ3Clock; const ABuffer: IQ3CommandBuffer; const APrint: IQ3HostConsole;
      const AMinMilliseconds: TFunc<Integer>; AFrameLimit: Integer);
    destructor Destroy; override;
    procedure AddStage(const AStage: TQ3FrameStage);
    /// <summary>Com_Frame: one pass; the milliseconds that were given to the stages</summary>
    function RunFrame: Integer;
    /// <summary>Frames until the limit or Quit; the number of frames that were run</summary>
    function Run: Integer;
    /// <summary>"quit": the loop stops after the frame it is in</summary>
    procedure Quit;
    /// <summary>Com_ModifyMsec for a dedicated server (the hitch warning goes to the print)</summary>
    function ModifyMilliseconds(AMilliseconds: Integer): Integer;
    property Frames: Integer read FFrames;
    property IsQuitRequested: Boolean read FQuit;
  end;

implementation

{ TQ3DedicatedLoop }

constructor TQ3DedicatedLoop.Create(const AClock: IQ3Clock; const ABuffer: IQ3CommandBuffer;
  const APrint: IQ3HostConsole; const AMinMilliseconds: TFunc<Integer>; AFrameLimit: Integer);
begin
  inherited Create;
  FClock := AClock;
  FBuffer := ABuffer;
  FPrint := APrint;
  FMinMilliseconds := AMinMilliseconds;
  FFrameLimit := AFrameLimit;
  FStages := TList<TQ3FrameStage>.Create;
  // the first frame counts from here, not from the start of the machine (lastTime of Com_Frame)
  FLastTime := FClock.Milliseconds;
end;

destructor TQ3DedicatedLoop.Destroy;
begin
  FStages.Free;
  inherited Destroy;
end;

procedure TQ3DedicatedLoop.AddStage(const AStage: TQ3FrameStage);
begin
  FStages.Add(AStage);
end;

procedure TQ3DedicatedLoop.Quit;
begin
  FQuit := True;
end;

function TQ3DedicatedLoop.ModifyMilliseconds(AMilliseconds: Integer): Integer;
begin
  Result := AMilliseconds;
  // dedicated servers do not want to clamp for a much longer period: it would mess up the views of time of clients
  if Result > HITCH_MILLISECONDS then
    FPrint.Print(AnsiString(Format('Hitch warning: %d msec frame time'#10, [Result])));
  if Result > CLAMP_MILLISECONDS then
    Result := CLAMP_MILLISECONDS;
end;

function TQ3DedicatedLoop.RunFrame: Integer;
var
  LMinMilliseconds, LNow, LMilliseconds: Integer;
  LStage: TQ3FrameStage;
begin
  LMinMilliseconds := 1;
  if Assigned(FMinMilliseconds) then
    LMinMilliseconds := FMinMilliseconds();
  if LMinMilliseconds < 1 then
    LMinMilliseconds := 1;
  // we may want to spin here if things are going too fast: the processor rests instead
  repeat
    LNow := FClock.Milliseconds;
    // possible on the first frame
    if FLastTime > LNow then
      FLastTime := LNow;
    LMilliseconds := LNow - FLastTime;
    if LMilliseconds < LMinMilliseconds then
      FClock.Sleep(1);
  until LMilliseconds >= LMinMilliseconds;
  FBuffer.Execute;
  FLastTime := LNow;
  Result := ModifyMilliseconds(LMilliseconds);
  for LStage in FStages do
    LStage(Result);
  Inc(FFrames);
end;

function TQ3DedicatedLoop.Run: Integer;
begin
  Result := 0;
  while not FQuit and ((FFrameLimit = Q3_FRAMES_UNLIMITED) or (Result < FFrameLimit)) do
  begin
    RunFrame;
    Inc(Result);
  end;
end;

end.
