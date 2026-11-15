{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the runner of the scripts of the frames           }
{                                                                              }
{  The Delphi side of Tools\Verifica\197\war_frame_ref.c (a program of this    }
{  repository for the remake war1 of (c) 2019 Alejandro Coto Gutierrez, zlib   }
{  License, see Libs\War\LICENSE-war1.txt): it reads the same scripts and      }
{  writes the same "H n hash" lines. This is an altered version.               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.ScriptRunner;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Generics.Defaults, DelphiDoom.War.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Render.Types,
  DelphiDoom.War.Render.Transform, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Game;

type
  /// <summary>
  ///   Runs a script on a TWarUiGame. Commands (one per line, # starts a comment): scene blizzard|menu; briefing
  ///   human|orc MAPTYPE; move X Y; lbutton|rbutton down|up; key NAME down|up; text STRING; run N [K] (N frames of 1/60
  ///   second, a line H every K, none if K is 0, one by default); hash; rgba FILE; trace on|off. The commands that need
  ///   the map (campaign, custom) or the network (scene download) are refused with EWarException: they are not in the
  ///   part of the game that this runner runs. The input of a frame is cleared after each frame of "run", as the
  ///   original does. The runner is not counted by reference (it is the trace of the transform it is given)
  /// </summary>
  TWarUiScriptRunner = class(TSingletonImplementation, IWarRenderTrace)
  strict private
    FGame: TWarUiGame;
    FOutput: TStrings;
    FTraceOutput: TStrings;
    FTracing: Boolean;
    function Fnv1a: Cardinal;
    function KeyFromName(const AName: string): TWarKey;
    function Number(const AText: string): Single;
    procedure RunCommand(const ALine: string);
    procedure RunFrames(ACount, AEvery: Integer);
    procedure WriteHash;
    function FormatG(AValue: Single): string;
  public
    /// <summary>The output and the trace are not owned (the trace output may be nil: then "trace on" is ignored)</summary>
    constructor Create(const AGame: TWarUiGame; const AOutput, ATraceOutput: TStrings);
    /// <summary>The lines of a script</summary>
    procedure Run(const ALines: TArray<string>);
    /// <summary>The lines of a script file</summary>
    procedure RunFile(const APath: string);
    procedure TraceBlit(const ABlit: TWarBlit);
    procedure TraceRect(const ARect: TWarRectF; const AColor: TWarRgba; AStroke: Boolean);
  end;

implementation

{ TWarUiScriptRunner }

constructor TWarUiScriptRunner.Create(const AGame: TWarUiGame; const AOutput, ATraceOutput: TStrings);
begin
  inherited Create;
  FGame := AGame;
  FOutput := AOutput;
  FTraceOutput := ATraceOutput;
end;

function TWarUiScriptRunner.FormatG(AValue: Single): string;
begin
  // printf("%.9g"): nine significant digits, no trailing zeros
  Result := Format('%.9g', [Double(AValue)], TFormatSettings.Invariant);
end;

procedure TWarUiScriptRunner.TraceBlit(const ABlit: TWarBlit);
var
  LKind: string;
  LLine: string;
  LFlip: Integer;
begin
  LFlip := 0;
  if ABlit.FlipHorizontal then
    LFlip := LFlip or 1;
  if ABlit.FlipVertical then
    LFlip := LFlip or 2;
  if LFlip = 0 then
    LKind := 'T'
  else
    LKind := 'R';
  // the texture is not written: its address means nothing outside the process
  LLine := Format('%s %s %s %s %s > %s %s %s %s a%d c%d,%d,%d b1', [LKind, FormatG(ABlit.Source.X),
    FormatG(ABlit.Source.Y), FormatG(ABlit.Source.Width), FormatG(ABlit.Source.Height),
    FormatG(ABlit.Destination.X), FormatG(ABlit.Destination.Y), FormatG(ABlit.Destination.Width),
    FormatG(ABlit.Destination.Height), ABlit.Color.A, ABlit.Color.R, ABlit.Color.G, ABlit.Color.B]);
  if LFlip <> 0 then
    LLine := LLine + Format(' f%d', [LFlip]);
  FTraceOutput.Add(LLine);
end;

procedure TWarUiScriptRunner.TraceRect(const ARect: TWarRectF; const AColor: TWarRgba; AStroke: Boolean);
var
  LKind: string;
begin
  if AStroke then
    LKind := 'S'
  else
    LKind := 'F';
  FTraceOutput.Add(Format('%s %s %s %s %s c%d,%d,%d,%d', [LKind, FormatG(ARect.X), FormatG(ARect.Y),
    FormatG(ARect.Width), FormatG(ARect.Height), AColor.R, AColor.G, AColor.B, AColor.A]));
end;

function TWarUiScriptRunner.Fnv1a: Cardinal;
var
  LPixels: TBytes;
  LIndex: Integer;
begin
  LPixels := FGame.Canvas.Blitter.Pixels;
  Result := 2166136261;
  for LIndex := 0 to High(LPixels) do
  begin
    Result := Result xor LPixels[LIndex];
    Result := Result * 16777619;
  end;
end;

function TWarUiScriptRunner.KeyFromName(const AName: string): TWarKey;
const
  NAMES: array[TWarKey] of string = ('', 'space', '''', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', ';', '=', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
    's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '[', '\', ']', '`', 'esc', 'enter', 'tab', 'backspace', 'insert', 'delete',
    'right', 'left', 'down', 'up', 'pageup', 'pagedown', 'home', 'end', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8',
    'f9', 'f10', 'f11', 'f12', 'shift', 'ctrl', 'alt');
var
  LKey: TWarKey;
begin
  for LKey := Succ(Low(TWarKey)) to High(TWarKey) do
    if NAMES[LKey] = AName then
      Exit(LKey);
  raise EWarException.CreateFmt('Unknown key in the script: %s', [AName]);
end;

function TWarUiScriptRunner.Number(const AText: string): Single;
begin
  // atof: the number at the start of the text
  Result := StrToFloat(AText, TFormatSettings.Invariant);
end;

procedure TWarUiScriptRunner.WriteHash;
begin
  FOutput.Add(Format('H %d %s', [FGame.Manager.FrameCount, LowerCase(IntToHex(Fnv1a, 8))]));
end;

procedure TWarUiScriptRunner.RunFrames(ACount, AEvery: Integer);
var
  LIndex: Integer;
  LDelta: Single;
begin
  // FIXED_DT = 1.0f / 60.0f
  LDelta := Single(1) / Single(60);
  for LIndex := 0 to ACount - 1 do
  begin
    FGame.Manager.RunFrame(LDelta);
    if (AEvery > 0) and ((LIndex + 1) mod AEvery = 0) then
      WriteHash;
    FGame.Manager.BeginInputFrame;
  end;
end;

procedure TWarUiScriptRunner.RunCommand(const ALine: string);
var
  LParts: TArray<string>;
  LCommand: string;
  LArg1: string;
  LArg2: string;
  LStream: TFileStream;
  LPixels: TBytes;
  LButton: TWarMouseButton;
begin
  LParts := ALine.Split([' '], TStringSplitOptions.ExcludeEmpty);
  LCommand := LParts[0];
  LArg1 := '';
  LArg2 := '';
  if Length(LParts) > 1 then
    LArg1 := LParts[1];
  if Length(LParts) > 2 then
    LArg2 := LParts[2];
  if LCommand = 'scene' then
  begin
    if LArg1 = 'blizzard' then
      FGame.Manager.SetNextScene(FGame.Scenes.CreateBlizzard, 0)
    else if LArg1 = 'download' then
      raise EWarException.Create('The download scene (the network) is not ported')
    else
      FGame.Manager.SetNextScene(FGame.Scenes.CreateMainMenu, 0);
  end
  else if LCommand = 'briefing' then
  begin
    if LArg1 = 'human' then
      FGame.Manager.SetNextScene(FGame.Scenes.CreateBriefing(wraHumans, StrToInt(LArg2)), 0)
    else
      FGame.Manager.SetNextScene(FGame.Scenes.CreateBriefing(wraOrcs, StrToInt(LArg2)), 0);
  end
  else if (LCommand = 'campaign') or (LCommand = 'custom') then
    raise EWarException.CreateFmt('The command %s needs the map, that is not in this part of the game', [LCommand])
  else if LCommand = 'move' then
    FGame.Input.SetPosition(Number(LArg1), Number(LArg2))
  else if (LCommand = 'lbutton') or (LCommand = 'rbutton') then
  begin
    if LCommand = 'lbutton' then
      LButton := wmbLeft
    else
      LButton := wmbRight;
    FGame.Input.SetButton(LButton, LArg1 = 'down');
  end
  else if LCommand = 'key' then
    FGame.Input.SetKey(KeyFromName(LArg1), LArg2 = 'down')
  else if LCommand = 'text' then
    FGame.Manager.HandleTextInput(AnsiString(Copy(ALine, 6, MaxInt)))
  else if LCommand = 'run' then
  begin
    if LArg2 <> '' then
      RunFrames(StrToInt(LArg1), StrToInt(LArg2))
    else
      RunFrames(StrToInt(LArg1), 1);
  end
  else if LCommand = 'hash' then
    WriteHash
  else if LCommand = 'png' then
  begin
    // the files of the frames are the "rgba" ones in this runner: png is accepted and writes nothing
  end
  else if LCommand = 'rgba' then
  begin
    LPixels := FGame.Canvas.Blitter.Pixels;
    LStream := TFileStream.Create(LArg1, fmCreate);
    try
      LStream.WriteBuffer(LPixels[0], Length(LPixels));
    finally
      LStream.Free;
    end;
  end
  else if LCommand = 'trace' then
  begin
    FTracing := (LArg1 = 'on') and Assigned(FTraceOutput);
    if FTracing then
      FGame.Canvas.Transform.Trace := Self
    else
      FGame.Canvas.Transform.Trace := nil;
  end
  else
    raise EWarException.CreateFmt('Unknown command in the script: %s', [LCommand]);
end;

procedure TWarUiScriptRunner.Run(const ALines: TArray<string>);
var
  LLine: string;
begin
  for LLine in ALines do
  begin
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    RunCommand(LLine);
  end;
end;

procedure TWarUiScriptRunner.RunFile(const APath: string);
var
  LText: TStringList;
  LLines: TArray<string>;
  LIndex: Integer;
begin
  LText := TStringList.Create;
  try
    LText.LoadFromFile(APath);
    SetLength(LLines, LText.Count);
    for LIndex := 0 to LText.Count - 1 do
      LLines[LIndex] := LText[LIndex].TrimRight([#13, #10]);
  finally
    LText.Free;
  end;
  Run(LLines);
end;

end.
