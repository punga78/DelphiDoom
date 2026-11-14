{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pmove library - the golden file of the player      }
{  movement of Quake III Arena and the runner that replays a scenario          }
{                                                                              }
{  Tests\Data\Pmove\pmove-golden.txt is written by Tools\Verifica\127\pmgen.c  }
{  (the real bg_pmove.c and bg_slidemove.c compiled with gcc)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Pmove.Support.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf, DelphiDoom.Tests.Pmove.Support.World;

type
  /// <summary>A segment of commands: the same command repeated, the angles growing by a step</summary>
  TGoldenSegment = record
    Count, Msec, Forward, Right, Up, Buttons, Weapon: Integer;
    Angles: array[0..2] of Integer;
    AngleSteps: array[0..2] of Integer;
  end;

  TGoldenScenario = class
  public
    Id: Integer;
    Name: string;
    TraceMask: Integer;
    NoFootsteps: Boolean;
    GauntletHit: Boolean;
    PmoveFixed: Boolean;
    PmoveMsec: Integer;
    DebugLevel: Integer;
    /// <summary>The words of the initial player state (the non zero ones are in the file)</summary>
    State: array[0..116] of Cardinal;
    Segments: TArray<TGoldenSegment>;
    Hashes: TArray<Cardinal>;
  end;

  /// <summary>The parsed golden: the item tags, the constants, the brushes and the scenarios</summary>
  TGoldenFile = class
  strict private
    FItemTags: TArray<Integer>;
    FFrameTimes: TArray<Cardinal>;
    FAngleHash: Cardinal;
    FBrushes: TArray<TFakeBrush>;
    FScenarios: TObjectList<TGoldenScenario>;
  public
    constructor Create(const ALines: TStrings);
    destructor Destroy; override;
    /// <summary>A world with the brushes of the golden</summary>
    function CreateWorld: TFakeWorld;
    property ItemTags: TArray<Integer> read FItemTags;
    /// <summary>msec * 0.001 as the C computes it (a float), for msec 1 to 200, as bits</summary>
    property FrameTimes: TArray<Cardinal> read FFrameTimes;
    /// <summary>The hash of SHORT2ANGLE of the 65536 shorts</summary>
    property AngleHash: Cardinal read FAngleHash;
    property Scenarios: TObjectList<TGoldenScenario> read FScenarios;
  end;

  /// <summary>Plays a scenario on a mover and gives the hash of every command (or a text dump of the state)</summary>
  TGoldenRunner = class
  public
    /// <summary>The hash of what one command left, as pmgen.c computes it</summary>
    class function StateHash(const APmove: TPmove; const ALogText: string): Cardinal; static;
    /// <summary>
    ///   Runs the scenario; the hashes are one for each command. ADump, when given, receives the same text as
    ///   "pmgen dump", to compare with a diff tool
    /// </summary>
    class function Run(const AMover: IPmove; const AScenario: TGoldenScenario; const ALog: TStringBuilder;
      const ADump: TStrings): TArray<Cardinal>; static;
  end;

  /// <summary>An ILog that keeps the text of the diagnostic lines, as Com_Printf of the harness does</summary>
  TGoldenLog = class(TInterfacedObject, ILog)
  strict private
    FText: TStringBuilder;
  public
    constructor Create(const AText: TStringBuilder);
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

implementation

uses
  DelphiDoom.Tests.Shared.Fnv, DelphiDoom.Tests.Collision.Q3Support;

constructor TGoldenLog.Create(const AText: TStringBuilder);
begin
  inherited Create;
  FText := AText;
end;

procedure TGoldenLog.Info(const AText: string);
begin
  FText.Append(AText);
end;

procedure TGoldenLog.Warning(const AText: string);
begin
end;

procedure TGoldenLog.DevWarning(const AText: string);
begin
end;

procedure TGoldenLog.Error(const AText: string);
begin
end;

function ParseHex(const AText: string): Cardinal;
begin
  Result := Cardinal(StrToInt64('$' + AText));
end;


constructor TGoldenFile.Create(const ALines: TStrings);
var
  LLine: string;
  LParts: TArray<string>;
  LScenario: TGoldenScenario;
  LIndex, LPlane, LPart, LSeparator: Integer;
  LBrush: TFakeBrush;
  LNormal: TQ3Vec3;
  LSegment: TGoldenSegment;
  LWord: string;
  LHashes: TList<Cardinal>;
begin
  inherited Create;
  FScenarios := TObjectList<TGoldenScenario>.Create(True);
  LScenario := nil;
  LHashes := TList<Cardinal>.Create;
  try
    for LLine in ALines do
    begin
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      LParts := LLine.Split([' ']);
      if LParts[0] = 'ITEMS' then
      begin
        SetLength(FItemTags, StrToInt(LParts[1]));
        for LIndex := 0 to High(FItemTags) do
          FItemTags[LIndex] := StrToInt(LParts[2 + LIndex]);
      end
      else if LParts[0] = 'CONST' then
      begin
        SetLength(FFrameTimes, Length(LParts) - 1);
        for LIndex := 0 to High(FFrameTimes) do
          FFrameTimes[LIndex] := ParseHex(LParts[1 + LIndex]);
      end
      else if LParts[0] = 'ANGLEHASH' then
        FAngleHash := ParseHex(LParts[1])
      else if LParts[0] = 'BRUSH' then
      begin
        LBrush.Contents := StrToInt(LParts[1]);
        LBrush.SurfaceFlags := StrToInt(LParts[2]);
        LBrush.Entity := StrToInt(LParts[3]);
        LBrush.Normals := nil;
        LBrush.Distances := nil;
        for LPlane := 0 to StrToInt(LParts[4]) - 1 do
        begin
          LPart := 5 + LPlane * 4;
          LNormal[0] := FloatOfBits(ParseHex(LParts[LPart]));
          LNormal[1] := FloatOfBits(ParseHex(LParts[LPart + 1]));
          LNormal[2] := FloatOfBits(ParseHex(LParts[LPart + 2]));
          LBrush.Normals := LBrush.Normals + [LNormal];
          LBrush.Distances := LBrush.Distances + [FloatOfBits(ParseHex(LParts[LPart + 3]))];
        end;
        FBrushes := FBrushes + [LBrush];
      end
      else if LParts[0] = 'SCENARIO' then
      begin
        LScenario := TGoldenScenario.Create;
        FScenarios.Add(LScenario);
        LHashes.Clear;
        LScenario.Id := StrToInt(LParts[1]);
        LScenario.Name := LParts[2];
        LScenario.TraceMask := StrToInt(LParts[3]);
        LScenario.NoFootsteps := LParts[4] <> '0';
        LScenario.GauntletHit := LParts[5] <> '0';
        LScenario.PmoveFixed := LParts[6] <> '0';
        LScenario.PmoveMsec := StrToInt(LParts[7]);
        LScenario.DebugLevel := StrToInt(LParts[8]);
      end
      else if LParts[0] = 'PS' then
      begin
        for LIndex := 1 to High(LParts) do
        begin
          LWord := LParts[LIndex];
          LSeparator := Pos(':', LWord);
          LScenario.State[StrToInt(Copy(LWord, 1, LSeparator - 1))] := ParseHex(Copy(LWord, LSeparator + 1, 20));
        end;
      end
      else if LParts[0] = 'SEG' then
      begin
        LSegment.Count := StrToInt(LParts[1]);
        LSegment.Msec := StrToInt(LParts[2]);
        LSegment.Forward := StrToInt(LParts[3]);
        LSegment.Right := StrToInt(LParts[4]);
        LSegment.Up := StrToInt(LParts[5]);
        LSegment.Buttons := StrToInt(LParts[6]);
        LSegment.Weapon := StrToInt(LParts[7]);
        for LIndex := 0 to 2 do
        begin
          LSegment.Angles[LIndex] := StrToInt(LParts[8 + LIndex]);
          LSegment.AngleSteps[LIndex] := StrToInt(LParts[11 + LIndex]);
        end;
        LScenario.Segments := LScenario.Segments + [LSegment];
      end
      else if LParts[0] = 'H' then
      begin
        for LIndex := 1 to High(LParts) do
          if LParts[LIndex] <> '' then
            LHashes.Add(ParseHex(LParts[LIndex]));
      end
      else if LParts[0] = 'END' then
        LScenario.Hashes := LHashes.ToArray;
    end;
  finally
    LHashes.Free;
  end;
end;

destructor TGoldenFile.Destroy;
begin
  FScenarios.Free;
  inherited Destroy;
end;

function TGoldenFile.CreateWorld: TFakeWorld;
var
  LBrush: TFakeBrush;
begin
  Result := TFakeWorld.Create;
  for LBrush in FBrushes do
    Result.AddBrush(LBrush);
end;

class function TGoldenRunner.StateHash(const APmove: TPmove; const ALogText: string): Cardinal;
var
  LWords: TArray<Integer>;
  LCount, LIndex: Integer;
  LBytes: TBytes;

  procedure Add(const AValue: Integer);
  begin
    if LCount >= Length(LWords) then
      SetLength(LWords, Length(LWords) * 2 + 16);
    LWords[LCount] := AValue;
    Inc(LCount);
  end;

  procedure AddFloat(const AValue: Single);
  var
    LBits: TQ3FloatBits;
  begin
    LBits.AsSingle := AValue;
    Add(LBits.AsInteger);
  end;

begin
  Result := TTestFnv.OFFSET_32;
  LCount := 0;
  Result := TTestFnv.Hash32(@APmove.Ps, SizeOf(APmove.Ps));
  Add(APmove.NumTouch);
  for LIndex := 0 to APmove.NumTouch - 1 do
    Add(APmove.TouchEnts[LIndex]);
  for LIndex := 0 to 2 do
    AddFloat(APmove.Mins[LIndex]);
  for LIndex := 0 to 2 do
    AddFloat(APmove.Maxs[LIndex]);
  Add(APmove.WaterType);
  Add(APmove.WaterLevel);
  AddFloat(APmove.XySpeed);
  for LIndex := 0 to 2 do
    Add(APmove.Cmd.Angles[LIndex]);
  Add(APmove.Cmd.Buttons);
  Add(APmove.Cmd.Weapon);
  Add(APmove.Cmd.ForwardMove);
  Add(APmove.Cmd.RightMove);
  Add(APmove.Cmd.UpMove);
  Add(APmove.Cmd.ServerTime);
  TTestFnv.Mix32(Result, @LWords[0], LCount * SizeOf(Integer));
  if ALogText <> '' then
  begin
    LBytes := TEncoding.ANSI.GetBytes(ALogText);
    TTestFnv.Mix32(Result, @LBytes[0], Length(LBytes));
  end;
end;

class function TGoldenRunner.Run(const AMover: IPmove; const AScenario: TGoldenScenario; const ALog: TStringBuilder;
  const ADump: TStrings): TArray<Cardinal>;
var
  LPmove: TPmove;
  LSegment: TGoldenSegment;
  LTime, LCommand, LStep, LIndex: Integer;
  LWords: PCardinal;
  LText, LLine: string;
  LHashes: TList<Cardinal>;
begin
  LHashes := TList<Cardinal>.Create;
  try
    Move(AScenario.State, LPmove.Ps, SizeOf(LPmove.Ps));
    LTime := LPmove.Ps.CommandTime;
    LCommand := 0;
    for LSegment in AScenario.Segments do
      for LStep := 0 to LSegment.Count - 1 do
      begin
        Inc(LTime, LSegment.Msec);
        LPmove.Cmd := Default(TQ3UserCmd);
        LPmove.Cmd.ServerTime := LTime;
        for LIndex := 0 to 2 do
          LPmove.Cmd.Angles[LIndex] := LSegment.Angles[LIndex] + LStep * LSegment.AngleSteps[LIndex];
        LPmove.Cmd.Buttons := LSegment.Buttons;
        LPmove.Cmd.Weapon := Byte(LSegment.Weapon);
        LPmove.Cmd.ForwardMove := ShortInt(LSegment.Forward);
        LPmove.Cmd.RightMove := ShortInt(LSegment.Right);
        LPmove.Cmd.UpMove := ShortInt(LSegment.Up);
        LPmove.TraceMask := AScenario.TraceMask;
        LPmove.DebugLevel := AScenario.DebugLevel;
        LPmove.NoFootsteps := AScenario.NoFootsteps;
        LPmove.GauntletHit := AScenario.GauntletHit;
        LPmove.FrameCount := 0;
        LPmove.NumTouch := 0;
        FillChar(LPmove.TouchEnts, SizeOf(LPmove.TouchEnts), 0);
        FillChar(LPmove.Mins, SizeOf(LPmove.Mins), 0);
        FillChar(LPmove.Maxs, SizeOf(LPmove.Maxs), 0);
        LPmove.WaterType := 0;
        LPmove.WaterLevel := 0;
        LPmove.XySpeed := 0;
        LPmove.PmoveFixed := AScenario.PmoveFixed;
        LPmove.PmoveMsec := AScenario.PmoveMsec;
        ALog.Clear;
        AMover.Execute(LPmove);
        LText := ALog.ToString;
        LHashes.Add(StateHash(LPmove, LText));
        if Assigned(ADump) then
        begin
          ADump.Add(Format('C %d t=%d', [LCommand, LTime]));
          LWords := @LPmove.Ps;
          LLine := 'W';
          for LIndex := 0 to 116 do
          begin
            if LWords^ <> 0 then
              LLine := LLine + Format(' %d:%.8x', [LIndex, LWords^]);
            Inc(LWords);
          end;
          ADump.Add(LLine);
          LLine := Format('O touch=%d', [LPmove.NumTouch]);
          for LIndex := 0 to LPmove.NumTouch - 1 do
            LLine := LLine + ',' + IntToStr(LPmove.TouchEnts[LIndex]);
          ADump.Add(LLine + Format(' mins=%.8x,%.8x,%.8x maxs=%.8x,%.8x,%.8x wt=%d wl=%d xy=%.8x cmd=%d,%d,%d,%d text=[%s]',
            [BitsOfFloat(LPmove.Mins[0]), BitsOfFloat(LPmove.Mins[1]), BitsOfFloat(LPmove.Mins[2]),
            BitsOfFloat(LPmove.Maxs[0]), BitsOfFloat(LPmove.Maxs[1]), BitsOfFloat(LPmove.Maxs[2]), LPmove.WaterType,
            LPmove.WaterLevel, BitsOfFloat(LPmove.XySpeed), LPmove.Cmd.Buttons, LPmove.Cmd.ForwardMove,
            LPmove.Cmd.RightMove, LPmove.Cmd.UpMove, LText]));
        end;
        Inc(LCommand);
      end;
    Result := LHashes.ToArray;
  finally
    LHashes.Free;
  end;
end;

end.
