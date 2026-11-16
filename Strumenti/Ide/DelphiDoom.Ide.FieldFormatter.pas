{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - how the fields of a state are written             }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.FieldFormatter;

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The fields "Sprite Number", "Sprite Subnumber" and "Next Frame" of a state are numbers in
  ///   the tables of the compiler; the panels write the sprite name, the letter of the frame and
  ///   the name of the next state instead. The tree and the list of a panel differ in what they
  ///   write for a number that is not valid, and both ways are kept
  /// </summary>
  TIdeFieldFormatter = class
  public
    /// <summary>How the tree of a panel writes a value; an unknown number is written as it is</summary>
    class function ForTree(const AFieldName, AFieldValue: string; const ASpriteNames,
      AStateNames: TStrings): string; static;
    /// <summary>How the list of a panel writes a value; an unknown number is written in decimal</summary>
    class function ForList(const AFieldName, AFieldValue: string; const ASpriteNames,
      AStateNames: TStrings): string; static;
  end;

implementation

uses
  System.SysUtils;

const
  FIELD_SPRITE_NUMBER = 'Sprite Number';
  FIELD_SPRITE_SUBNUMBER = 'Sprite Subnumber';
  FIELD_NEXT_FRAME = 'Next Frame';
  BRIGHT_BIT = 32768;
  LAST_FRAME = 28;

function FrameLetter(const ANumber: Integer; out AText: string): Boolean;
var
  LBright: string;
  LFrame: Integer;
begin
  LFrame := ANumber;
  if LFrame and BRIGHT_BIT <> 0 then
  begin
    LFrame := LFrame and (BRIGHT_BIT - 1);
    LBright := ' BRIGHT';
  end
  else
    LBright := '';
  Result := (LFrame >= 0) and (LFrame <= LAST_FRAME);
  if Result then
    AText := Chr(Ord('A') + LFrame) + LBright
  else
    AText := IntToStr(LFrame);
end;

{ TIdeFieldFormatter }

class function TIdeFieldFormatter.ForTree(const AFieldName, AFieldValue: string;
  const ASpriteNames, AStateNames: TStrings): string;
var
  LNumber: Integer;
  LText: string;
begin
  Result := AFieldValue;
  if AFieldName = FIELD_SPRITE_NUMBER then
  begin
    if TryStrToInt(AFieldValue, LNumber) and (LNumber >= 0) and (LNumber < ASpriteNames.Count) then
      Result := ASpriteNames[LNumber]
    else
      Result := 'Unknown sprite number #' + AFieldValue;
  end
  else if AFieldName = FIELD_SPRITE_SUBNUMBER then
  begin
    if TryStrToInt(AFieldValue, LNumber) and FrameLetter(LNumber, LText) then
      Result := LText
    else
      Result := 'Unknown sprite subnumber #' + AFieldValue;
  end
  else if AFieldName = FIELD_NEXT_FRAME then
  begin
    LNumber := StrToIntDef(AFieldValue, -1);
    if (LNumber >= 0) and (LNumber < AStateNames.Count - 1) then
      Result := AStateNames[LNumber];
  end;
end;

class function TIdeFieldFormatter.ForList(const AFieldName, AFieldValue: string;
  const ASpriteNames, AStateNames: TStrings): string;
var
  LNumber: Integer;
  LText: string;
begin
  Result := AFieldValue;
  if AFieldName = FIELD_SPRITE_NUMBER then
  begin
    LNumber := StrToIntDef(AFieldValue, 0);
    if (LNumber >= 0) and (LNumber < ASpriteNames.Count) then
      Result := ASpriteNames[LNumber]
    else
      Result := 'Unknown sprite number #' + IntToStr(LNumber);
  end
  else if AFieldName = FIELD_SPRITE_SUBNUMBER then
  begin
    if FrameLetter(StrToIntDef(AFieldValue, 0), LText) then
      Result := LText
    else
      Result := 'Unknown sprite subnumber #' + LText;
  end
  else if AFieldName = FIELD_NEXT_FRAME then
  begin
    LNumber := StrToIntDef(AFieldValue, -1);
    if (LNumber >= 0) and (LNumber < AStateNames.Count - 1) then
      Result := AStateNames[LNumber];
  end;
end;

end.
