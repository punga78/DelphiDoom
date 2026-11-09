{******************************************************************************}
{                                                                              }
{  DelphiDoom: XcomGame - runs the game without a window and takes screenshots  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ShotRunner;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.ManualClock,
  DelphiDoom.XcomEngine.QueueEventSource, DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.Xcom.ImageExporter;

type
  /// <summary>
  ///   Drives a game that runs on a manual clock, a queue of events and a display in memory: it lets the time pass,
  ///   sends clicks and keys, and saves what the display shows as a PNG (-shot). The script is a list of steps:
  ///   wait:ms, move:x,y, click:x,y, key:sdlkey, shot:file. Coordinates are the ones of the display (the window)
  /// </summary>
  TXcomShotRunner = class
  strict private
    FGame: TXcomGame;
    FClock: TXcomManualClock;
    FEvents: TXcomQueueEventSource;
    FDevice: TXcomMemoryVideoDevice;
    FExporter: TXcomImageExporter;
    FSaved: TStringList;
    procedure Step(const AStep: string);
  public
    /// <summary>None of the arguments is owned</summary>
    constructor Create(AGame: TXcomGame; AClock: TXcomManualClock; AEvents: TXcomQueueEventSource;
      ADevice: TXcomMemoryVideoDevice; AExporter: TXcomImageExporter);
    destructor Destroy; override;
    /// <summary>Lets the time pass one millisecond at a time, running a turn of the game for each</summary>
    procedure Wait(AMilliseconds: Integer);
    procedure Move(AX, AY: Integer);
    procedure Click(AX, AY: Integer);
    procedure Key(AKey: Integer);
    /// <summary>Saves the last picture of the display as a PNG; the game runs a frame first if none was drawn yet</summary>
    procedure Shot(const AFileName: string);
    procedure Run(const ASteps: TArray<string>);
    /// <summary>The files that were saved</summary>
    function Saved: TStrings;
  end;

implementation

uses
  DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image, DelphiDoom.XcomEngine.Types;

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
end;

destructor TXcomShotRunner.Destroy;
begin
  FSaved.Free;
  inherited Destroy;
end;

procedure TXcomShotRunner.Wait(AMilliseconds: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to AMilliseconds do
  begin
    if FGame.IsQuitting then
      Exit;
    FGame.RunFrame;
    FClock.Advance(1);
  end;
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

procedure TXcomShotRunner.Click(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  Move(AX, AY);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := XCOM_BUTTON_LEFT;
  FEvents.Enqueue(LEvent);
  Wait(40);
  LEvent.Kind := ekMouseUp;
  FEvents.Enqueue(LEvent);
  Wait(40);
end;

procedure TXcomShotRunner.Key(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
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
  else if LName = 'key' then
    Key(StrToInt(LValue))
  else if LName = 'shot' then
    Shot(LValue)
  else if (LName = 'click') or (LName = 'move') then
  begin
    LParts := LValue.Split([',']);
    if Length(LParts) <> 2 then
      raise Exception.Create('Bad step: ' + AStep);
    if LName = 'click' then
      Click(StrToInt(LParts[0]), StrToInt(LParts[1]))
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

function TXcomShotRunner.Saved: TStrings;
begin
  Result := FSaved;
end;

end.
