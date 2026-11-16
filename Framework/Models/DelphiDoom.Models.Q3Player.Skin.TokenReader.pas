{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the words of a     }
{  .skin file                                                                  }
{                                                                              }
{  Port of CommaParse of renderer\tr_image.c. Based on the Quake III Arena GPL }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.TokenReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   CommaParse: the words of a .skin file. Blanks (bytes up to 32; the bytes from 128 are
  ///   negative in the signed char of the original, so they count as blanks too) and "//" and
  ///   "/* */" comments separate words, and so does a comma, which is not part of any word; a word
  ///   in quotes keeps everything up to the closing quote. Never fails: at the end of the text the
  ///   word is empty.
  /// </summary>
  TQ3SkinTokenReader = class
  strict private
    FText: AnsiString;
    FPosition: Integer;
    function CharAt(const APosition: Integer): Integer;
  public
    constructor Create(const AText: AnsiString);
    /// <summary>The next word</summary>
    function Next: AnsiString;
    /// <summary>"if (*text_p == ',') text_p++"</summary>
    procedure SkipComma;
    /// <summary>"*text_p" is the NUL of the end: there is nothing more to read</summary>
    function AtEnd: Boolean;
  end;

implementation

const
  // MAX_TOKEN_CHARS
  MAX_TOKEN_CHARS = 1024;

constructor TQ3SkinTokenReader.Create(const AText: AnsiString);
begin
  inherited Create;
  FText := AText;
  FPosition := 1;
end;

// the byte as a signed char; zero at and after the end of the text
function TQ3SkinTokenReader.CharAt(const APosition: Integer): Integer;
begin
  if (APosition < 1) or (APosition > System.Length(FText)) then
    Exit(0);
  Result := ShortInt(Byte(FText[APosition]));
end;

function TQ3SkinTokenReader.AtEnd: Boolean;
begin
  Result := CharAt(FPosition) = 0;
end;

procedure TQ3SkinTokenReader.SkipComma;
begin
  if CharAt(FPosition) = Ord(',') then
    Inc(FPosition);
end;

function TQ3SkinTokenReader.Next: AnsiString;
var
  LPosition, LChar: Integer;
begin
  Result := '';
  LPosition := FPosition;
  while True do
  begin
    // skip white space
    LChar := CharAt(LPosition);
    while LChar <= 32 do
    begin
      if LChar = 0 then
        Break;
      Inc(LPosition);
      LChar := CharAt(LPosition);
    end;
    LChar := CharAt(LPosition);
    if (LChar = Ord('/')) and (CharAt(LPosition + 1) = Ord('/')) then
    begin
      while (CharAt(LPosition) <> 0) and (CharAt(LPosition) <> 10) do
        Inc(LPosition);
    end
    else if (LChar = Ord('/')) and (CharAt(LPosition + 1) = Ord('*')) then
    begin
      while (CharAt(LPosition) <> 0) and ((CharAt(LPosition) <> Ord('*')) or (CharAt(LPosition + 1) <> Ord('/'))) do
        Inc(LPosition);
      if CharAt(LPosition) <> 0 then
        Inc(LPosition, 2);
    end
    else
      Break;
  end;

  // the end of the text: the original returns the empty word and leaves its pointer where it was
  if LChar = 0 then
    Exit;

  // a word in quotes
  if LChar = Ord('"') then
  begin
    Inc(LPosition);
    while True do
    begin
      LChar := CharAt(LPosition);
      Inc(LPosition);
      if (LChar = Ord('"')) or (LChar = 0) then
      begin
        FPosition := LPosition;
        Exit;
      end;
      if System.Length(Result) < MAX_TOKEN_CHARS then
        Result := Result + AnsiChar(Byte(LChar));
    end;
  end;

  // a regular word
  repeat
    if System.Length(Result) < MAX_TOKEN_CHARS then
      Result := Result + AnsiChar(Byte(LChar));
    Inc(LPosition);
    LChar := CharAt(LPosition);
  until (LChar <= 32) or (LChar = Ord(','));
  if System.Length(Result) = MAX_TOKEN_CHARS then
    Result := '';
  FPosition := LPosition;
end;

end.
