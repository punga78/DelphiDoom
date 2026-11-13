{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotStructReader, ReadStructure                        }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): ReadStructure,      }
{  ReadNumber, ReadChar and ReadString of code\botlib\l_struct.c. Based on the }
{  Quake III Arena GPL Source Code (id Software).                              }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Struct.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Struct.Types;

type
  /// <summary>
  ///   Reads <c>{ field value; ... }</c> into a buffer of bytes laid out as the C structure. Every
  ///   problem is reported by the source (<c>SourceError</c>) and gives false, as the original returns
  ///   0 after printing.
  /// </summary>
  TBotStructReader = class
  strict private
    class procedure Check(const ABuffer: TBytes; const APosition, ASize: Integer); static;
    class procedure StoreInteger(var ABuffer: TBytes; const APosition, AValue: Integer); static;
    class procedure StoreFloat(var ABuffer: TBytes; const APosition: Integer; const AValue: Single); static;
    class procedure ReadNumber(const ASource: TBotChatSource; const AField: TBotFieldDefinition;
      var ABuffer: TBytes; const APosition: Integer); static;
    class procedure ReadChar(const ASource: TBotChatSource; const AField: TBotFieldDefinition;
      var ABuffer: TBytes; const APosition: Integer); static;
    class procedure ReadString(const ASource: TBotChatSource; var ABuffer: TBytes; const APosition: Integer); static;
    class procedure ReadFields(const ASource: TBotChatSource; const ADefinition: TBotStructDefinition;
      var ABuffer: TBytes; const AOffset: Integer); static;
  public
    /// <summary>
    ///   ReadStructure: the structure starts at <c>AOffset</c> of the buffer. A field that the C code would
    ///   write outside the structure raises EBotAiException (the original writes outside its memory).
    /// </summary>
    class function ReadStructure(const ASource: TBotChatSource; const ADefinition: TBotStructDefinition;
      var ABuffer: TBytes; const AOffset: Integer = 0): Boolean; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Exceptions,
  DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Text.CFormat;

{ TBotStructReader }

class procedure TBotStructReader.Check(const ABuffer: TBytes; const APosition, ASize: Integer);
begin
  if (APosition < 0) or (APosition + ASize > Length(ABuffer)) then
    raise EBotAiException.CreateFmt('structure field outside of its buffer (position %d, size %d, buffer %d)',
      [APosition, ASize, Length(ABuffer)]);
end;

class procedure TBotStructReader.StoreInteger(var ABuffer: TBytes; const APosition, AValue: Integer);
begin
  Check(ABuffer, APosition, SizeOf(Integer));
  Move(AValue, ABuffer[APosition], SizeOf(Integer));
end;

class procedure TBotStructReader.StoreFloat(var ABuffer: TBytes; const APosition: Integer; const AValue: Single);
begin
  Check(ABuffer, APosition, SizeOf(Single));
  Move(AValue, ABuffer[APosition], SizeOf(Single));
end;

class procedure TBotStructReader.ReadNumber(const ASource: TBotChatSource; const AField: TBotFieldDefinition;
  var ABuffer: TBytes; const APosition: Integer);
var
  LToken: TIdToken;
  LNegative: Boolean;
  LType: Integer;
  LIntValue: Integer;
  LIntMin: Integer;
  LIntMax: Integer;
  LFloatValue: Double;
  LBound: Single;
begin
  ASource.ExpectAnyToken(LToken);
  LNegative := False;
  // check for a minus sign
  if LToken.TokenType = TT_PUNCTUATION then
  begin
    if (AField.FieldType and FT_UNSIGNED) <> 0 then
      ASource.Fail('expected unsigned value, found ' + string(TBotChatSource.CText(LToken)));
    if TBotChatSource.CText(LToken) <> '-' then
      ASource.Fail('unexpected punctuation ' + string(TBotChatSource.CText(LToken)));
    LNegative := True;
    ASource.ExpectAnyToken(LToken);
  end;
  if LToken.TokenType <> TT_NUMBER then
    ASource.Fail('expected number, found ' + string(TBotChatSource.CText(LToken)));
  LType := AField.FieldType and FT_TYPE;
  // a float value
  if (LToken.SubType and TT_FLOAT) <> 0 then
  begin
    if LType <> FT_FLOAT then
      ASource.Fail('unexpected float');
    LFloatValue := LToken.GetDoubleValue;
    if LNegative then
      LFloatValue := -LFloatValue;
    if (AField.FieldType and FT_BOUNDED) <> 0 then
    begin
      if (LFloatValue < AField.FloatMin) or (LFloatValue > AField.FloatMax) then
        ASource.Fail('float out of range [' + string(TBotCFormat.Fixed6(AField.FloatMin)) + ', ' +
          string(TBotCFormat.Fixed6(AField.FloatMax)) + ']');
    end;
    StoreFloat(ABuffer, APosition, LFloatValue);
    Exit;
  end;
  // "long" is 32 bit as in the Windows build of the original
  LIntValue := LToken.GetIntValue;
  if LNegative then
    LIntValue := -LIntValue;
  LIntMin := 0;
  LIntMax := 0;
  if LType = FT_CHAR then
  begin
    if (AField.FieldType and FT_UNSIGNED) <> 0 then
    begin
      LIntMin := 0;
      LIntMax := 255;
    end
    else
    begin
      LIntMin := -128;
      LIntMax := 127;
    end;
  end;
  if LType = FT_INT then
  begin
    if (AField.FieldType and FT_UNSIGNED) <> 0 then
    begin
      LIntMin := 0;
      LIntMax := 65535;
    end
    else
    begin
      LIntMin := -32768;
      LIntMax := 32767;
    end;
  end;
  if (LType = FT_CHAR) or (LType = FT_INT) then
  begin
    if (AField.FieldType and FT_BOUNDED) <> 0 then
    begin
      // Maximum() and Minimum() of l_utils.h compare a long with a float: the result is a float
      if Single(LIntMin) > AField.FloatMin then
        LBound := LIntMin
      else
        LBound := AField.FloatMin;
      LIntMin := Trunc(LBound);
      if Single(LIntMax) < AField.FloatMax then
        LBound := LIntMax
      else
        LBound := AField.FloatMax;
      LIntMax := Trunc(LBound);
    end;
    if (LIntValue < LIntMin) or (LIntValue > LIntMax) then
      ASource.Fail(Format('value %d out of range [%d, %d]', [LIntValue, LIntMin, LIntMax]));
  end
  else if LType = FT_FLOAT then
  begin
    if (AField.FieldType and FT_BOUNDED) <> 0 then
    begin
      if (LIntValue < AField.FloatMin) or (LIntValue > AField.FloatMax) then
        ASource.Fail(Format('value %d out of range [%s, %s]', [LIntValue,
          string(TBotCFormat.Fixed6(AField.FloatMin)), string(TBotCFormat.Fixed6(AField.FloatMax))]));
    end;
  end;
  // store the value
  if LType = FT_CHAR then
  begin
    Check(ABuffer, APosition, 1);
    ABuffer[APosition] := Byte(LIntValue and $FF);
  end
  else if LType = FT_INT then
    StoreInteger(ABuffer, APosition, LIntValue)
  else if LType = FT_FLOAT then
    StoreFloat(ABuffer, APosition, LIntValue);
end;

class procedure TBotStructReader.ReadChar(const ASource: TBotChatSource; const AField: TBotFieldDefinition;
  var ABuffer: TBytes; const APosition: Integer);
var
  LToken: TIdToken;
begin
  ASource.ExpectAnyToken(LToken);
  // take literals into account
  if LToken.TokenType = TT_LITERAL then
  begin
    Check(ABuffer, APosition, 1);
    if LToken.Text = '' then
      ABuffer[APosition] := 0
    else
      ABuffer[APosition] := Byte(LToken.Text[1]);
  end
  else
  begin
    ASource.UnreadLastToken;
    ReadNumber(ASource, AField, ABuffer, APosition);
  end;
end;

class procedure TBotStructReader.ReadString(const ASource: TBotChatSource; var ABuffer: TBytes;
  const APosition: Integer);
var
  LToken: TIdToken;
  LLength: Integer;
begin
  ASource.ExpectTokenType(TT_STRING, 0, LToken);
  Check(ABuffer, APosition, MAX_STRINGFIELD);
  // strncpy pads with zeros; the last byte is always a zero
  FillChar(ABuffer[APosition], MAX_STRINGFIELD, 0);
  LLength := Length(LToken.Text);
  if LLength > MAX_STRINGFIELD then
    LLength := MAX_STRINGFIELD;
  if LLength > 0 then
    Move(LToken.Text[1], ABuffer[APosition], LLength);
  ABuffer[APosition + MAX_STRINGFIELD - 1] := 0;
end;

class procedure TBotStructReader.ReadFields(const ASource: TBotChatSource; const ADefinition: TBotStructDefinition;
  var ABuffer: TBytes; const AOffset: Integer);
var
  LToken: TIdToken;
  LField: TBotFieldDefinition;
  LCount: Integer;
  LPosition: Integer;
  LIsArray: Boolean;
begin
  ASource.ExpectTokenString('{');
  while True do
  begin
    ASource.ExpectAnyToken(LToken);
    // end of the structure
    if TBotChatSource.CText(LToken) = '}' then
      Break;
    if not ADefinition.FindField(TBotChatSource.CText(LToken), LField) then
      ASource.Fail('unknown structure field ' + string(TBotChatSource.CText(LToken)));
    LIsArray := (LField.FieldType and FT_ARRAY) <> 0;
    if LIsArray then
    begin
      LCount := LField.MaxArray;
      ASource.ExpectTokenString('{');
    end
    else
      LCount := 1;
    LPosition := AOffset + LField.Offset;
    while LCount > 0 do
    begin
      Dec(LCount);
      if LIsArray and ASource.CheckTokenString('}') then
        Break;
      case LField.FieldType and FT_TYPE of
        FT_CHAR:
          begin
            ReadChar(ASource, LField, ABuffer, LPosition);
            Inc(LPosition, SizeOf(AnsiChar));
          end;
        FT_INT:
          begin
            ReadNumber(ASource, LField, ABuffer, LPosition);
            Inc(LPosition, SizeOf(Integer));
          end;
        FT_FLOAT:
          begin
            ReadNumber(ASource, LField, ABuffer, LPosition);
            Inc(LPosition, SizeOf(Single));
          end;
        FT_STRING:
          begin
            ReadString(ASource, ABuffer, LPosition);
            Inc(LPosition, MAX_STRINGFIELD);
          end;
        FT_STRUCT:
          begin
            if not Assigned(LField.SubStruct) then
              ASource.Fail('BUG: no sub structure defined');
            // the original ignores the result of the nested read
            ReadStructure(ASource, LField.SubStruct, ABuffer, LPosition);
            Inc(LPosition, LField.SubStruct.Size);
          end;
      end;
      if LIsArray then
      begin
        ASource.ExpectAnyToken(LToken);
        if TBotChatSource.CText(LToken) = '}' then
          Break;
        if TBotChatSource.CText(LToken) <> ',' then
          ASource.Fail('expected a comma, found ' + string(TBotChatSource.CText(LToken)));
      end;
    end;
  end;
end;

class function TBotStructReader.ReadStructure(const ASource: TBotChatSource; const ADefinition: TBotStructDefinition;
  var ABuffer: TBytes; const AOffset: Integer): Boolean;
begin
  try
    ReadFields(ASource, ADefinition, ABuffer, AOffset);
    Result := True;
  except
    // the source already printed the error (SourceError); the original returns false
    on EBotChatParseException do
      Result := False;
  end;
end;

end.
