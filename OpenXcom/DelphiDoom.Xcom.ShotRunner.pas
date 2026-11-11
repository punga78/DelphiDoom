{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - runs the game without a window and takes screenshots   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ShotRunner;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.ManualClock,
  DelphiDoom.XcomEngine.QueueEventSource, DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.XcomEngine.Types,
  DelphiDoom.Xcom.ImageExporter;

type
  /// <summary>
  ///   Drives a game that runs on a manual clock, a queue of events and a display in memory: it lets the time pass,
  ///   sends clicks and keys, and saves what the display shows as a PNG (-shot). The script is a list of steps:
  ///   wait:ms, move:x,y, click:x,y, rclick:x,y (right button), drag:x1,y1,x2,y2,button, key:sdlkey, ckey:sdlkey
  ///   (with Ctrl held), shot:file. Coordinates are the ones of the display (the window).
  ///   To play without looking at every picture: trace:1 says every change of the state on top, state:label says it
  ///   now, until:Name,ms waits until the class of the state on top contains Name (or ms pass), and
  ///   on:Name=step+step runs the steps whenever such a state has been on top for 300 ms (again every second while
  ///   it stays; on:Name= forgets it)
  /// </summary>
  TXcomShotRunner = class
  strict private
    FGame: TXcomGame;
    FClock: TXcomManualClock;
    FEvents: TXcomQueueEventSource;
    FDevice: TXcomMemoryVideoDevice;
    FExporter: TXcomImageExporter;
    FSaved: TStringList;
    FHoldMilliseconds: Integer;
    FOnTick: TProc;
    FOnSay: TProc<string>;
    FHandlers: TStringList;
    FTrace: Boolean;
    FInHandler: Boolean;
    FLastTop: TObject;
    FLastTopName: string;
    FTopSince: Cardinal;
    FHandledAt: Cardinal;
    procedure Step(const AStep: string);
    procedure Say(const AText: string);
    procedure WaitUntil(const AValue: string);
    procedure Watch;
  public
    /// <summary>None of the arguments is owned</summary>
    constructor Create(AGame: TXcomGame; AClock: TXcomManualClock; AEvents: TXcomQueueEventSource;
      ADevice: TXcomMemoryVideoDevice; AExporter: TXcomImageExporter);
    destructor Destroy; override;
    /// <summary>Lets the time pass one millisecond at a time, running a turn of the game for each</summary>
    procedure Wait(AMilliseconds: Integer);
    procedure Move(AX, AY: Integer);
    procedure Click(AX, AY: Integer; AButton: Integer = XCOM_BUTTON_LEFT);
    procedure Drag(AFromX, AFromY, AToX, AToY, AButton: Integer);
    procedure Key(AKey: Integer; AModifiers: Integer = 0);
    /// <summary>Saves the last picture of the display as a PNG; the game runs a frame first if none was drawn yet</summary>
    procedure Shot(const AFileName: string);
    procedure Run(const ASteps: TArray<string>);
    /// <summary>
    ///   The steps of a script written one per line, joined with ';' (blank lines and what follows a # are skipped)
    /// </summary>
    class function ScriptOfFile(const AFileName: string): string; static;
    /// <summary>The files that were saved</summary>
    function Saved: TStrings;
    /// <summary>Called after every millisecond that passes (the sound output of a script asks its samples here)</summary>
    property OnTick: TProc read FOnTick write FOnTick;
    /// <summary>Receives the lines of trace:, state: and until: (each begins with the time of the script)</summary>
    property OnSay: TProc<string> read FOnSay write FOnSay;
    /// <summary>How long a click keeps the button down (40 ms; 80 like the capture script of the real program to compare timers)</summary>
    property HoldMilliseconds: Integer read FHoldMilliseconds write FHoldMilliseconds;
  end;

implementation

uses
  DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image;

const
  // KMOD_LCTRL of SDL 1.2
  XCOM_KMOD_LEFT_CTRL = $0040;

constructor TXcomShotRunner.Create(AGame: TXcomGame; AClock: TXcomManualClock; AEvents: TXcomQueueEventSource;
  ADevice: TXcomMemoryVideoDevice; AExporter: TXcomImageExporter);
begin
  inherited Create;
  FGame := AGame;
  FClock := AClock;
  FEvents := AEvents;
  FDevice := ADevice;
  FExporter := AExporter;
  FSaved := TStringList.Create;
  FHandlers := TStringList.Create;
  FHoldMilliseconds := 40;
end;

destructor TXcomShotRunner.Destroy;
begin
  FHandlers.Free;
  FSaved.Free;
  inherited Destroy;
end;

procedure TXcomShotRunner.Wait(AMilliseconds: Integer);
var
  LEnd: Cardinal;
begin
  // by the clock: the time that the steps of an on: handler take is part of the wait they interrupt
  LEnd := FClock.Ticks + Cardinal(AMilliseconds);
  while FClock.Ticks < LEnd do
  begin
    if FGame.IsQuitting then
      Exit;
    FGame.RunFrame;
    FClock.Advance(1);
    if Assigned(FOnTick) then
      FOnTick;
    Watch;
  end;
end;

procedure TXcomShotRunner.Say(const AText: string);
begin
  if Assigned(FOnSay) then
    FOnSay(Format('%d %s', [FClock.Ticks, AText]));
end;

procedure TXcomShotRunner.Watch;
const
  SETTLE_MILLISECONDS = 300;
  AGAIN_MILLISECONDS = 1000;
var
  LTop: TObject;
  LIndex: Integer;
  LStep: string;
begin
  LTop := FGame.TopState;
  // the class too: a new state can take the address of the one that was freed
  if (LTop <> FLastTop) or (Assigned(LTop) and (LTop.ClassName <> FLastTopName)) then
  begin
    FLastTop := LTop;
    if Assigned(LTop) then
      FLastTopName := LTop.ClassName
    else
      FLastTopName := '';
    FTopSince := FClock.Ticks;
    FHandledAt := 0;
    if FTrace then
      Say('top ' + FLastTopName);
  end;
  if FInHandler or (FHandlers.Count = 0) or (FLastTopName = '') then
    Exit;
  if FClock.Ticks - FTopSince < SETTLE_MILLISECONDS then
    Exit;
  if (FHandledAt <> 0) and (FClock.Ticks - FHandledAt < AGAIN_MILLISECONDS) then
    Exit;
  for LIndex := 0 to FHandlers.Count - 1 do
    if FLastTopName.ToLowerInvariant.Contains(FHandlers.Names[LIndex]) then
    begin
      FHandledAt := FClock.Ticks;
      FInHandler := True;
      try
        for LStep in FHandlers.ValueFromIndex[LIndex].Split(['+']) do
          Step(LStep);
      finally
        FInHandler := False;
      end;
      Break;
    end;
end;

procedure TXcomShotRunner.WaitUntil(const AValue: string);
var
  LParts: TArray<string>;
  LLimit: Integer;
  LStart: Cardinal;
begin
  // until:Name,ms
  LParts := AValue.Split([',']);
  if Length(LParts) <> 2 then
    raise Exception.Create('Bad step: until:' + AValue);
  LLimit := StrToInt(LParts[1]);
  LStart := FClock.Ticks;
  while (Integer(FClock.Ticks - LStart) < LLimit) and not FGame.IsQuitting
    and not FLastTopName.ToLowerInvariant.Contains(LParts[0].ToLowerInvariant) do
    Wait(1);
  Say(Format('until %s: %d ms, top %s', [LParts[0], FClock.Ticks - LStart, FLastTopName]));
end;

procedure TXcomShotRunner.Move(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX;
  LEvent.Y := AY;
  FEvents.Enqueue(LEvent);
  Wait(20);
end;

procedure TXcomShotRunner.Drag(AFromX, AFromY, AToX, AToY, AButton: Integer);
const
  STEPS = 8;
var
  LEvent: TXcomInputEvent;
  LStep: Integer;
begin
  Move(AFromX, AFromY);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AFromX;
  LEvent.Y := AFromY;
  LEvent.Button := AButton;
  FEvents.Enqueue(LEvent);
  Wait(40);
  for LStep := 1 to STEPS do
    Move(AFromX + (AToX - AFromX) * LStep div STEPS, AFromY + (AToY - AFromY) * LStep div STEPS);
  // held long enough not to be taken for a click
  Wait(400);
  LEvent.Kind := ekMouseUp;
  LEvent.X := AToX;
  LEvent.Y := AToY;
  FEvents.Enqueue(LEvent);
  Wait(40);
end;

procedure TXcomShotRunner.Click(AX, AY: Integer; AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  Move(AX, AY);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := AButton;
  FEvents.Enqueue(LEvent);
  Wait(FHoldMilliseconds);
  LEvent.Kind := ekMouseUp;
  FEvents.Enqueue(LEvent);
  Wait(40);
end;

procedure TXcomShotRunner.Key(AKey: Integer; AModifiers: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  LEvent.Modifiers := AModifiers;
  // a printable key also types its character (the unicode field of the SDL event)
  if (AModifiers = 0) and (AKey >= 32) and (AKey <= 126) then
    LEvent.Character := Cardinal(AKey);
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent.Kind := ekKeyUp;
  FEvents.Enqueue(LEvent);
  Wait(20);
end;

procedure TXcomShotRunner.Shot(const AFileName: string);
var
  LImage: TXcomImage;
  LIndex: Integer;
begin
  if FDevice.Presented = 0 then
    Wait(40);
  LImage := TXcomImage.Create(FDevice.Width, FDevice.Height);
  System.Move(FDevice.Pixels[0], LImage.Pixels[0], Length(LImage.Pixels));
  LImage.HasPalette := True;
  LImage.Palette := TXcomPalette.Create(256);
  for LIndex := 0 to 255 do
    LImage.Palette.Colors[LIndex] := FDevice.Palette[LIndex];
  FExporter.Save(LImage, AFileName, False);
  FSaved.Add(AFileName);
end;

procedure TXcomShotRunner.Step(const AStep: string);
var
  LName: string;
  LValue: string;
  LPosition: Integer;
  LParts: TArray<string>;
begin
  LPosition := Pos(':', AStep);
  if LPosition = 0 then
    raise Exception.Create('Bad step: ' + AStep);
  LName := LowerCase(Copy(AStep, 1, LPosition - 1));
  LValue := Copy(AStep, LPosition + 1, MaxInt);
  if LName = 'wait' then
    Wait(StrToInt(LValue))
  else if LName = 'hold' then
    FHoldMilliseconds := StrToInt(LValue)
  else if LName = 'key' then
    Key(StrToInt(LValue))
  else if LName = 'ckey' then
    Key(StrToInt(LValue), XCOM_KMOD_LEFT_CTRL)
  else if LName = 'shot' then
    Shot(LValue)
  else if LName = 'trace' then
    FTrace := LValue <> '0'
  else if LName = 'state' then
    Say('state ' + FLastTopName + ' ' + LValue)
  else if LName = 'until' then
    WaitUntil(LValue)
  else if LName = 'on' then
  begin
    // on:Name=step+step
    LPosition := Pos('=', LValue);
    if LPosition = 0 then
      raise Exception.Create('Bad step: ' + AStep);
    LParts := [Copy(LValue, 1, LPosition - 1).ToLowerInvariant, Copy(LValue, LPosition + 1, MaxInt)];
    if FHandlers.IndexOfName(LParts[0]) >= 0 then
      FHandlers.Delete(FHandlers.IndexOfName(LParts[0]));
    if LParts[1] <> '' then
      FHandlers.Add(LParts[0] + '=' + LParts[1]);
  end
  else if LName = 'drag' then
  begin
    // drag:x1,y1,x2,y2,button
    LParts := LValue.Split([',']);
    if Length(LParts) <> 5 then
      raise Exception.Create('Bad step: ' + AStep);
    Drag(StrToInt(LParts[0]), StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]), StrToInt(LParts[4]));
  end
  else if (LName = 'click') or (LName = 'rclick') or (LName = 'move') then
  begin
    LParts := LValue.Split([',']);
    if Length(LParts) <> 2 then
      raise Exception.Create('Bad step: ' + AStep);
    if LName = 'click' then
      Click(StrToInt(LParts[0]), StrToInt(LParts[1]))
    else if LName = 'rclick' then
      Click(StrToInt(LParts[0]), StrToInt(LParts[1]), XCOM_BUTTON_RIGHT)
    else
      Move(StrToInt(LParts[0]), StrToInt(LParts[1]));
  end
  else
    raise Exception.Create('Unknown step: ' + AStep);
end;

procedure TXcomShotRunner.Run(const ASteps: TArray<string>);
var
  LStep: string;
begin
  for LStep in ASteps do
    Step(LStep);
end;

class function TXcomShotRunner.ScriptOfFile(const AFileName: string): string;
var
  LLines: TStringList;
  LLine: string;
  LStep: string;
  LPosition: Integer;
begin
  Result := '';
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    for LLine in LLines do
    begin
      LPosition := Pos('#', LLine);
      if LPosition = 0 then
        LPosition := Length(LLine) + 1;
      LStep := Trim(Copy(LLine, 1, LPosition - 1));
      if LStep = '' then
        Continue;
      if Result <> '' then
        Result := Result + ';';
      Result := Result + LStep;
    end;
  finally
    LLines.Free;
  end;
end;

function TXcomShotRunner.Saved: TStrings;
begin
  Result := FSaved;
end;

end.
