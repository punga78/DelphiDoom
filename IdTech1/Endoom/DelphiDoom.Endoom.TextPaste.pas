{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text pasted on the screen                       }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextPaste;

interface

uses
  System.SysUtils, System.Types,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   What the old editor did with a text on the clipboard (Paste1Click of ENDEDIT): each line
  ///   goes to a row from the cell where the cursor was, cut at the 80th column, with the
  ///   foreground color in use; the background is left as it is. The text that does not fit under
  ///   the last row is dropped
  /// </summary>
  TEndoomTextPaste = class
  public
    /// <summary>
    ///   The character of the DOS font for a character of the text: the code of the ANSI character
    ///   (as the old tool, which did not convert it), "?" for what has no code in 0..255
    /// </summary>
    class function CodeOf(ACharacter: Char): Byte; static;
    /// <summary>Pastes the text from the cell (AX, AY); gives the cell where the cursor goes</summary>
    class function Apply(const AScreen: IEndoomScreen; const AText: string; AX, AY,
      AForeground: Integer): TPoint; static;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Endoom.Types;

{ TEndoomTextPaste }

class function TEndoomTextPaste.CodeOf(ACharacter: Char): Byte;
begin
  if Ord(ACharacter) < 256 then
    Result := Byte(Ord(ACharacter))
  else
    Result := Ord('?');
end;

class function TEndoomTextPaste.Apply(const AScreen: IEndoomScreen; const AText: string; AX, AY,
  AForeground: Integer): TPoint;
var
  LLines: TStringList;
  LLine: string;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LIndex: Integer;
begin
  LX := AX;
  LY := AY;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LRow := 0 to LLines.Count - 1 do
    begin
      if LY >= ENDOOM_ROWS then
        Break;
      LLine := LLines[LRow];
      if Length(LLine) > ENDOOM_COLUMNS then
        SetLength(LLine, ENDOOM_COLUMNS);
      for LIndex := 1 to Length(LLine) do
      begin
        if LX >= ENDOOM_COLUMNS then
          Break;
        AScreen.SetForeground(LX, LY, AForeground);
        AScreen.SetCharacter(LX, LY, CodeOf(LLine[LIndex]));
        Inc(LX);
      end;
      if LRow < LLines.Count - 1 then
      begin
        LX := 0;
        Inc(LY);
      end;
    end;
  finally
    LLines.Free;
  end;
  Result.X := LX;
  if Result.X > ENDOOM_COLUMNS - 1 then
    Result.X := ENDOOM_COLUMNS - 1;
  Result.Y := LY;
  if Result.Y > ENDOOM_ROWS - 1 then
    Result.Y := ENDOOM_ROWS - 1;
  if Result.X < 0 then
    Result.X := 0;
  if Result.Y < 0 then
    Result.Y := 0;
end;

end.
