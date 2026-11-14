{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the reader of a script of commands             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.ScriptParser;

interface

uses
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   Reads the text of a script of commands (-autoscript): one step for every line, words separated by
  ///   blanks, not case sensitive, the rest of a line after # is a comment. The steps:
  ///   hold tics [forward n] [back n] [side n] [turn n] [look n] [center] [fire] [use] [jump] [crouch] [weapon n];
  ///   goto x y [z height] [radius n] [speed n] [timeout tics] [fire] [use] [fight] [range n];
  ///   face x y [timeout tics] [fire];
  ///   climb height [timeout tics];
  ///   hunt tics [range n];
  ///   heal health tics [range n].
  ///   forward, back and speed are 1..50, side is -40..40 (positive = right), turn is in steps of 256/65536 of
  ///   a turn for every tic (-5..5, positive = left), look is -7..7 (positive = up), x, y and the heights are
  ///   map units
  /// </summary>
  TParityScriptParser = class
  public const
    DEFAULT_RADIUS = 48;
    DEFAULT_SPEED = 50;
    DEFAULT_TIMEOUT = 700;
    DEFAULT_ENEMY_RANGE = 1200;
    MAX_FORWARD = 50;
    MAX_SIDE = 40;
    MAX_TURN_STEPS = 5;
    MAX_LOOK = 7;
    MAX_WEAPON = 8;
    /// <summary>One step of turn in the units of the ticcmd: a demo keeps the high byte of the angle</summary>
    TURN_UNIT = 256;
  strict private
    class function SplitWords(const ALine: string): TArray<string>; static;
    class function ReadNumber(const AWords: TArray<string>; AIndex, ALine, AMinimum, AMaximum: Integer): Integer; static;
    class function ParseLine(const AWords: TArray<string>; ALine: Integer): TParityScriptStep; static;
  public
    /// <summary>The steps of the script; EParityException (with the number of the line) for what it does not know</summary>
    class function Parse(const AText: string): TArray<TParityScriptStep>; static;
  end;

implementation

uses
  System.SysUtils;

const
  SUnknownStep = 'Script, line %d: unknown step "%s"';
  SUnknownWord = 'Script, line %d: unknown word "%s"';
  SMissingNumber = 'Script, line %d: a number is missing after "%s"';
  SWrongNumber = 'Script, line %d: "%s" is not a whole number';
  SOutOfRange = 'Script, line %d: %d is not between %d and %d';

  COORDINATE_LIMIT = 32767;
  MAX_TICS = 1000000;

{ TParityScriptParser }

class function TParityScriptParser.SplitWords(const ALine: string): TArray<string>;
var
  LText: string;
  LComment: Integer;
begin
  LText := ALine;
  LComment := Pos('#', LText);
  if LComment > 0 then
    LText := Copy(LText, 1, LComment - 1);
  Result := LText.ToLowerInvariant.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
end;

class function TParityScriptParser.ReadNumber(const AWords: TArray<string>; AIndex, ALine, AMinimum,
  AMaximum: Integer): Integer;
begin
  if AIndex > High(AWords) then
    raise EParityException.CreateFmt(SMissingNumber, [ALine, AWords[AIndex - 1]]);
  if not TryStrToInt(AWords[AIndex], Result) then
    raise EParityException.CreateFmt(SWrongNumber, [ALine, AWords[AIndex]]);
  if (Result < AMinimum) or (Result > AMaximum) then
    raise EParityException.CreateFmt(SOutOfRange, [ALine, Result, AMinimum, AMaximum]);
end;

class function TParityScriptParser.ParseLine(const AWords: TArray<string>; ALine: Integer): TParityScriptStep;
var
  LIndex: Integer;
  LWord: string;
  LIsHold: Boolean;
  LIsGoto: Boolean;
begin
  Result := Default(TParityScriptStep);
  Result.Line := ALine;
  Result.Tics := DEFAULT_TIMEOUT;
  if AWords[0] = 'hold' then
  begin
    Result.Kind := skHold;
    Result.Tics := ReadNumber(AWords, 1, ALine, 1, MAX_TICS);
    LIndex := 2;
  end
  else if AWords[0] = 'goto' then
  begin
    Result.Kind := skGoto;
    Result.X := ReadNumber(AWords, 1, ALine, -COORDINATE_LIMIT, COORDINATE_LIMIT);
    Result.Y := ReadNumber(AWords, 2, ALine, -COORDINATE_LIMIT, COORDINATE_LIMIT);
    Result.Radius := DEFAULT_RADIUS;
    Result.Command.Forward := DEFAULT_SPEED;
    LIndex := 3;
  end
  else if AWords[0] = 'face' then
  begin
    Result.Kind := skFace;
    Result.X := ReadNumber(AWords, 1, ALine, -COORDINATE_LIMIT, COORDINATE_LIMIT);
    Result.Y := ReadNumber(AWords, 2, ALine, -COORDINATE_LIMIT, COORDINATE_LIMIT);
    LIndex := 3;
  end
  else if AWords[0] = 'climb' then
  begin
    Result.Kind := skClimb;
    Result.Z := ReadNumber(AWords, 1, ALine, -COORDINATE_LIMIT, COORDINATE_LIMIT);
    Result.HasZ := True;
    LIndex := 2;
  end
  else if AWords[0] = 'hunt' then
  begin
    Result.Kind := skHunt;
    Result.Tics := ReadNumber(AWords, 1, ALine, 1, MAX_TICS);
    Result.Fight := True;
    Result.EnemyRange := DEFAULT_ENEMY_RANGE;
    LIndex := 2;
  end
  else if AWords[0] = 'heal' then
  begin
    Result.Kind := skHeal;
    Result.Health := ReadNumber(AWords, 1, ALine, 1, MAX_TICS);
    Result.Tics := ReadNumber(AWords, 2, ALine, 1, MAX_TICS);
    Result.Fight := True;
    Result.EnemyRange := DEFAULT_ENEMY_RANGE;
    LIndex := 3;
  end
  else
    raise EParityException.CreateFmt(SUnknownStep, [ALine, AWords[0]]);

  LIsHold := Result.Kind = skHold;
  LIsGoto := Result.Kind = skGoto;
  while LIndex <= High(AWords) do
  begin
    LWord := AWords[LIndex];
    Inc(LIndex);
    if (LWord = 'timeout') and not (Result.Kind in [skHold, skHunt, skHeal]) then
    begin
      Result.Tics := ReadNumber(AWords, LIndex, ALine, 1, MAX_TICS);
      Inc(LIndex);
    end
    else if (LWord = 'fight') and LIsGoto then
    begin
      Result.Fight := True;
      if Result.EnemyRange = 0 then
        Result.EnemyRange := DEFAULT_ENEMY_RANGE;
    end
    else if (LWord = 'range') and (Result.Kind in [skGoto, skHunt, skHeal]) then
    begin
      Result.EnemyRange := ReadNumber(AWords, LIndex, ALine, 1, COORDINATE_LIMIT);
      Inc(LIndex);
    end
    else if (LWord = 'fire') and (Result.Kind in [skHold, skGoto, skFace]) then
      Result.Command.Fire := True
    else if (LWord = 'use') and (LIsHold or LIsGoto) then
      Result.Command.Use := True
    else if (LWord = 'z') and LIsGoto then
    begin
      Result.Z := ReadNumber(AWords, LIndex, ALine, -COORDINATE_LIMIT, COORDINATE_LIMIT);
      Result.HasZ := True;
      Inc(LIndex);
    end
    else if (LWord = 'radius') and LIsGoto then
    begin
      Result.Radius := ReadNumber(AWords, LIndex, ALine, 1, COORDINATE_LIMIT);
      Inc(LIndex);
    end
    else if (LWord = 'speed') and LIsGoto then
    begin
      Result.Command.Forward := ReadNumber(AWords, LIndex, ALine, 1, MAX_FORWARD);
      Inc(LIndex);
    end
    else if (LWord = 'forward') and LIsHold then
    begin
      Result.Command.Forward := ReadNumber(AWords, LIndex, ALine, 0, MAX_FORWARD);
      Inc(LIndex);
    end
    else if (LWord = 'back') and LIsHold then
    begin
      Result.Command.Forward := -ReadNumber(AWords, LIndex, ALine, 0, MAX_FORWARD);
      Inc(LIndex);
    end
    else if (LWord = 'side') and LIsHold then
    begin
      Result.Command.Side := ReadNumber(AWords, LIndex, ALine, -MAX_SIDE, MAX_SIDE);
      Inc(LIndex);
    end
    else if (LWord = 'turn') and LIsHold then
    begin
      Result.Command.Turn := ReadNumber(AWords, LIndex, ALine, -MAX_TURN_STEPS, MAX_TURN_STEPS) * TURN_UNIT;
      Inc(LIndex);
    end
    else if (LWord = 'look') and LIsHold then
    begin
      Result.Command.Look := ReadNumber(AWords, LIndex, ALine, -MAX_LOOK, MAX_LOOK);
      Inc(LIndex);
    end
    else if (LWord = 'weapon') and LIsHold then
    begin
      Result.Command.Weapon := ReadNumber(AWords, LIndex, ALine, 1, MAX_WEAPON);
      Inc(LIndex);
    end
    else if (LWord = 'center') and LIsHold then
      Result.Command.LookCenter := True
    else if (LWord = 'jump') and LIsHold then
      Result.Command.Jump := True
    else if (LWord = 'crouch') and LIsHold then
      Result.Command.Crouch := True
    else
      raise EParityException.CreateFmt(SUnknownWord, [ALine, LWord]);
  end;
end;

class function TParityScriptParser.Parse(const AText: string): TArray<TParityScriptStep>;
var
  LLines: TArray<string>;
  LWords: TArray<string>;
  LIndex: Integer;
  LCount: Integer;
begin
  LLines := AText.Replace(#13, '').Split([#10]);
  SetLength(Result, Length(LLines));
  LCount := 0;
  for LIndex := 0 to High(LLines) do
  begin
    LWords := SplitWords(LLines[LIndex]);
    if Length(LWords) = 0 then
      Continue;
    Result[LCount] := ParseLine(LWords, LIndex + 1);
    Inc(LCount);
  end;
  SetLength(Result, LCount);
end;

end.
