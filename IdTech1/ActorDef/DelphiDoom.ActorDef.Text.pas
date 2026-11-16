{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the small text functions                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.Text;

interface

type
  /// <summary>The functions of d_delphi that the parser used, with the same results</summary>
  TActorDefText = class
  public
    /// <summary>
    ///   Only digits, with a - in front: the old StrIsInteger. An empty text is not a number, and
    ///   neither is a + in front
    /// </summary>
    class function IsInteger(const AText: string): Boolean; static;
    /// <summary>The text up to the first space (or all of it)</summary>
    class function FirstWord(const AText: string): string; static;
    /// <summary>The text after the last space (or all of it)</summary>
    class function LastWord(const AText: string): string; static;
    /// <summary>The text without its spaces (the old strremovespaces)</summary>
    class function RemoveSpaces(const AText: string): string; static;
  end;

implementation

{ TActorDefText }

class function TActorDefText.IsInteger(const AText: string): Boolean;
var
  LStart: Integer;
  LIndex: Integer;
begin
  LStart := 1;
  if (AText <> '') and (AText[1] = '-') then
    LStart := 2;
  if LStart > Length(AText) then
    Exit(False);
  for LIndex := LStart to Length(AText) do
    if (AText[LIndex] < '0') or (AText[LIndex] > '9') then
      Exit(False);
  Result := True;
end;

class function TActorDefText.FirstWord(const AText: string): string;
var
  LPosition: Integer;
begin
  LPosition := Pos(' ', AText);
  if LPosition = 0 then
    Result := AText
  else
    Result := Copy(AText, 1, LPosition - 1);
end;

class function TActorDefText.LastWord(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := Length(AText);
  while LIndex > 0 do
  begin
    if AText[LIndex] = ' ' then
      Exit;
    Result := AText[LIndex] + Result;
    Dec(LIndex);
  end;
end;

class function TActorDefText.RemoveSpaces(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] <> ' ' then
      Result := Result + AText[LIndex];
end;

end.
