{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the "gridsize" of the worldspawn of a BSP    }
{                                                                              }
{  Port of the part of R_LoadEntities (tr_bsp.c) that sets lightGridSize, with  }
{  COM_ParseExt (q_shared.c), Quake III Arena GPL Source Code.                 }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. GPL v2 or later.                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.GridSizeReader;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   Reads the size of a light grid cell from the entities text with the tokenizer of the
  ///   engine (COM_ParseExt: words end at any character up to the space, a quoted string may be
  ///   empty and then ends the parsing, "//" and "/*" are comments). Only the world spawn is
  ///   read: the first block. The remap keys do not set the size but the original stops reading
  ///   at one without a semicolon in its value, so a "gridsize" after it is not used
  /// </summary>
  TBspGridSizeReader = class
  strict private
    class function NextToken(const AText: AnsiString; var APosition: Integer): AnsiString; static;
  public
    /// <summary>64 x 64 x 128 unless the worldspawn says otherwise</summary>
    class function Read(const AEntityText: AnsiString): TGeoVec3; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdCNumbers;

const
  MAX_TOKEN_CHARS = 1024;

{ TBspGridSizeReader }

class function TBspGridSizeReader.NextToken(const AText: AnsiString; var APosition: Integer): AnsiString;
var
  LLength: Integer;
  LChar: AnsiChar;
begin
  Result := '';
  LLength := Length(AText);
  // skip whitespace and comments
  while True do
  begin
    while (APosition <= LLength) and (AText[APosition] <= ' ') do
      Inc(APosition);
    if APosition > LLength then
      Exit;
    if (AText[APosition] = '/') and (APosition < LLength) and (AText[APosition + 1] = '/') then
    begin
      while (APosition <= LLength) and (AText[APosition] <> #10) do
        Inc(APosition);
    end
    else if (AText[APosition] = '/') and (APosition < LLength) and (AText[APosition + 1] = '*') then
    begin
      while (APosition <= LLength) and not ((AText[APosition] = '*') and (APosition < LLength) and
        (AText[APosition + 1] = '/')) do
        Inc(APosition);
      if APosition <= LLength then
        Inc(APosition, 2);
    end
    else
      Break;
  end;
  LChar := AText[APosition];
  // handle quoted strings specially
  if LChar = '"' then
  begin
    Inc(APosition);
    while APosition <= LLength do
    begin
      LChar := AText[APosition];
      Inc(APosition);
      if (LChar = '"') or (LChar = #0) then
        Exit;
      if Length(Result) < MAX_TOKEN_CHARS then
        Result := Result + LChar;
    end;
    Exit;
  end;
  // parse a regular word
  while (APosition <= LLength) and (AText[APosition] > ' ') do
  begin
    if Length(Result) < MAX_TOKEN_CHARS then
      Result := Result + AText[APosition];
    Inc(APosition);
  end;
  // a word that fills the buffer is discarded
  if Length(Result) = MAX_TOKEN_CHARS then
    Result := '';
end;

class function TBspGridSizeReader.Read(const AEntityText: AnsiString): TGeoVec3;
var
  LPosition: Integer;
  LKey, LValue: AnsiString;
  LValues: array[0..2] of Single;
begin
  LValues[0] := 64;
  LValues[1] := 64;
  LValues[2] := 128;
  LPosition := 1;
  LKey := NextToken(AEntityText, LPosition);
  if (LKey = '') or (LKey[1] <> '{') then
  begin
    Result := TGeoVec3.Make(LValues[0], LValues[1], LValues[2]);
    Exit;
  end;
  // only parse the world spawn
  while True do
  begin
    LKey := NextToken(AEntityText, LPosition);
    if (LKey = '') or (LKey[1] = '}') then
      Break;
    LValue := NextToken(AEntityText, LPosition);
    if (LValue = '') or (LValue[1] = '}') then
      Break;
    // check for remapping of shaders for vertex lighting and of shaders
    if Copy(LKey, 1, Length('vertexremapshader')) = 'vertexremapshader' then
    begin
      if Pos(';', string(LValue)) = 0 then
        Break;
      Continue;
    end;
    if Copy(LKey, 1, Length('remapshader')) = 'remapshader' then
    begin
      if Pos(';', string(LValue)) = 0 then
        Break;
      Continue;
    end;
    // check for a different grid size
    if SameText(string(LKey), 'gridsize') then
      TIdCNumbers.ScanFloats(LValue, LValues);
  end;
  Result := TGeoVec3.Make(LValues[0], LValues[1], LValues[2]);
end;

end.
