{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotStructWriter, WriteStructure                       }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): WriteStructure,     }
{  WriteStructWithIndent, WriteIndent and WriteFloat of code\botlib\l_struct.c.}
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Struct.Writer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Struct.Types;

type
  /// <summary>
  ///   Writes a structure laid out as the C structure as the text a configuration file has: the text
  ///   goes to a string instead of a <c>FILE *</c> (the lines end with CR LF as in the original).
  /// </summary>
  TBotStructWriter = class
  strict private
    class function WriteStructWithIndent(const ADefinition: TBotStructDefinition; const ABuffer: TBytes;
      const AOffset, AIndent: Integer): AnsiString; static;
  public
    /// <summary>WriteIndent: the tabs</summary>
    class function WriteIndent(const AIndent: Integer): AnsiString; static;
    /// <summary>WriteFloat: "%f" without the trailing zeros (and without the point of a whole number)</summary>
    class function WriteFloat(const AValue: Single): AnsiString; static;
    /// <summary>WriteStructure</summary>
    class function WriteStructure(const ADefinition: TBotStructDefinition; const ABuffer: TBytes;
      const AOffset: Integer = 0): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Text.CFormat;

{ TBotStructWriter }

class function TBotStructWriter.WriteIndent(const AIndent: Integer): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to AIndent do
    Result := Result + #9;
end;

class function TBotStructWriter.WriteFloat(const AValue: Single): AnsiString;
var
  LLength: Integer;
begin
  Result := TBotCFormat.Fixed6(AValue);
  LLength := Length(Result);
  // strip any trailing zeros
  while LLength > 1 do
  begin
    Dec(LLength);
    if (Result[LLength + 1] <> '0') and (Result[LLength + 1] <> '.') then
      Break;
    if Result[LLength + 1] = '.' then
    begin
      SetLength(Result, LLength);
      Break;
    end;
    SetLength(Result, LLength);
  end;
end;

class function TBotStructWriter.WriteStructWithIndent(const ADefinition: TBotStructDefinition; const ABuffer: TBytes;
  const AOffset, AIndent: Integer): AnsiString;
var
  LIndent: Integer;
  LField: TBotFieldDefinition;
  LCount: Integer;
  LPosition: Integer;
  LInteger: Integer;
  LSingle: Single;
  LText: AnsiString;
  LIndex: Integer;
begin
  Result := WriteIndent(AIndent) + '{'#13#10;
  LIndent := AIndent + 1;
  for LIndex := 0 to High(ADefinition.Fields) do
  begin
    LField := ADefinition.Fields[LIndex];
    Result := Result + WriteIndent(LIndent) + LField.Name + #9;
    LPosition := AOffset + LField.Offset;
    if (LField.FieldType and FT_ARRAY) <> 0 then
    begin
      LCount := LField.MaxArray;
      Result := Result + '{';
    end
    else
      LCount := 1;
    while LCount > 0 do
    begin
      Dec(LCount);
      if LPosition < 0 then
        raise EBotAiException.Create('structure field outside of its buffer');
      case LField.FieldType and FT_TYPE of
        FT_CHAR:
          begin
            if LPosition + 1 > Length(ABuffer) then
              raise EBotAiException.Create('structure field outside of its buffer');
            Result := Result + TBotCFormat.Int(ShortInt(ABuffer[LPosition]));
            Inc(LPosition, 1);
          end;
        FT_INT:
          begin
            if LPosition + SizeOf(Integer) > Length(ABuffer) then
              raise EBotAiException.Create('structure field outside of its buffer');
            Move(ABuffer[LPosition], LInteger, SizeOf(Integer));
            Result := Result + TBotCFormat.Int(LInteger);
            Inc(LPosition, SizeOf(Integer));
          end;
        FT_FLOAT:
          begin
            if LPosition + SizeOf(Single) > Length(ABuffer) then
              raise EBotAiException.Create('structure field outside of its buffer');
            Move(ABuffer[LPosition], LSingle, SizeOf(Single));
            Result := Result + WriteFloat(LSingle);
            Inc(LPosition, SizeOf(Single));
          end;
        FT_STRING:
          begin
            if LPosition + MAX_STRINGFIELD > Length(ABuffer) then
              raise EBotAiException.Create('structure field outside of its buffer');
            // %s stops at the first zero
            LText := '';
            LInteger := 0;
            while (LInteger < MAX_STRINGFIELD) and (ABuffer[LPosition + LInteger] <> 0) do
            begin
              LText := LText + AnsiChar(ABuffer[LPosition + LInteger]);
              Inc(LInteger);
            end;
            Result := Result + '"' + LText + '"';
            Inc(LPosition, MAX_STRINGFIELD);
          end;
        FT_STRUCT:
          begin
            // the original passes the start of the outer structure, not the field: kept
            Result := Result + WriteStructWithIndent(LField.SubStruct, ABuffer, AOffset, LIndent);
            Inc(LPosition, LField.SubStruct.Size);
          end;
      end;
      if (LField.FieldType and FT_ARRAY) <> 0 then
      begin
        if LCount > 0 then
          Result := Result + ','
        else
          Result := Result + '}';
      end;
    end;
    Result := Result + #13#10;
  end;
  Result := Result + WriteIndent(AIndent) + '}'#13#10;
end;

class function TBotStructWriter.WriteStructure(const ADefinition: TBotStructDefinition; const ABuffer: TBytes;
  const AOffset: Integer): AnsiString;
begin
  Result := WriteStructWithIndent(ADefinition, ABuffer, AOffset, 0);
end;

end.
