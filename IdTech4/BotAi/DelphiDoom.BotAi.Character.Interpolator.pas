{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCharacterInterpolator, BotInterpolateCharacters    }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the interpolation   }
{  of BotInterpolateCharacters of code\botlib\be_ai_char.c. Based on the Quake }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.Interpolator;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Character.Data;

type
  /// <summary>The character between two skill levels</summary>
  TBotCharacterInterpolator = class
  public
    /// <summary>
    ///   Floats present in both are interpolated; an integer or a string is the one of the first. Two
    ///   levels with the same skill give a NaN scale as in the original (float division by zero is not
    ///   an error there), so the arithmetic is done with the floating point exceptions masked.
    /// </summary>
    class function Interpolate(const AFirst, ASecond: TBotCharacter; const ADesiredSkill: Single): TBotCharacter; static;
  end;

implementation

uses
  System.Math, DelphiDoom.BotAi.Character.Types;

{ TBotCharacterInterpolator }

class function TBotCharacterInterpolator.Interpolate(const AFirst, ASecond: TBotCharacter;
  const ADesiredSkill: Single): TBotCharacter;
var
  LMask: TArithmeticExceptionMask;
  LScale: Single;
  LDifference: Single;
  LRange: Single;
  LOffset: Single;
  LIndex: Integer;
begin
  Result := TBotCharacter.Create;
  Result.Skill := ADesiredSkill;
  Result.FileName := AFirst.FileName;
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    LDifference := ADesiredSkill - AFirst.Skill;
    LRange := ASecond.Skill - AFirst.Skill;
    LScale := LDifference / LRange;
    for LIndex := 0 to MAX_CHARACTERISTICS - 1 do
    begin
      if (AFirst.Characteristics[LIndex].CharType = CT_FLOAT) and (ASecond.Characteristics[LIndex].CharType = CT_FLOAT) then
      begin
        Result.Characteristics[LIndex].CharType := CT_FLOAT;
        LRange := ASecond.Characteristics[LIndex].FloatValue - AFirst.Characteristics[LIndex].FloatValue;
        LOffset := LRange * LScale;
        Result.Characteristics[LIndex].FloatValue := AFirst.Characteristics[LIndex].FloatValue + LOffset;
      end
      else if AFirst.Characteristics[LIndex].CharType = CT_INTEGER then
      begin
        Result.Characteristics[LIndex].CharType := CT_INTEGER;
        Result.Characteristics[LIndex].IntegerValue := AFirst.Characteristics[LIndex].IntegerValue;
      end
      else if AFirst.Characteristics[LIndex].CharType = CT_STRING then
      begin
        Result.Characteristics[LIndex].CharType := CT_STRING;
        Result.Characteristics[LIndex].StringValue := AFirst.Characteristics[LIndex].StringValue;
      end;
    end;
  finally
    SetExceptionMask(LMask);
  end;
end;

end.
