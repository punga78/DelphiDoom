{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotScriptCompressor, COM_Compress                     }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): COM_Compress of     }
{  code\game\q_shared.c, which LoadScriptFile of l_script.c applies to every   }
{  file. Based on the Quake III Arena GPL Source Code (id Software).           }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ScriptCompressor;

interface

type
  /// <summary>
  ///   Takes out the comments and the extra white space of a script: line and block comments go, every
  ///   run of spaces and tabs is one space, every run of line ends is one line feed (so the line
  ///   numbers of the messages are those of the compressed text), quoted strings are copied as they are.
  /// </summary>
  TBotScriptCompressor = class
  public
    /// <summary>COM_Compress; the text stops at the first zero byte as the C string does</summary>
    class function Compress(const AText: AnsiString): AnsiString; static;
  end;

implementation

{ TBotScriptCompressor }

class function TBotScriptCompressor.Compress(const AText: AnsiString): AnsiString;
var
  LLength: Integer;
  LIn: Integer;
  LOut: Integer;
  LChar: AnsiChar;
  LNewLine: Boolean;
  LWhiteSpace: Boolean;

  function At(const AIndex: Integer): AnsiChar;
  begin
    if AIndex <= LLength then
      Result := AText[AIndex]
    else
      Result := #0;
  end;

begin
  LLength := Pos(#0, AText) - 1;
  if LLength < 0 then
    LLength := Length(AText);
  SetLength(Result, LLength);
  LIn := 1;
  LOut := 0;
  LNewLine := False;
  LWhiteSpace := False;
  while At(LIn) <> #0 do
  begin
    LChar := At(LIn);
    if (LChar = '/') and (At(LIn + 1) = '/') then
    begin
      while (At(LIn) <> #0) and (At(LIn) <> #10) do
        Inc(LIn);
    end
    else if (LChar = '/') and (At(LIn + 1) = '*') then
    begin
      while (At(LIn) <> #0) and ((At(LIn) <> '*') or (At(LIn + 1) <> '/')) do
        Inc(LIn);
      if At(LIn) <> #0 then
        Inc(LIn, 2);
    end
    else if (LChar = #10) or (LChar = #13) then
    begin
      LNewLine := True;
      Inc(LIn);
    end
    else if (LChar = ' ') or (LChar = #9) then
    begin
      LWhiteSpace := True;
      Inc(LIn);
    end
    else
    begin
      // a pending line end is written (and counts as white space)
      if LNewLine then
      begin
        Inc(LOut);
        Result[LOut] := #10;
        LNewLine := False;
        LWhiteSpace := False;
      end;
      if LWhiteSpace then
      begin
        Inc(LOut);
        Result[LOut] := ' ';
        LWhiteSpace := False;
      end;
      Inc(LOut);
      Result[LOut] := LChar;
      Inc(LIn);
      // quoted strings are copied as they are
      if LChar = '"' then
      begin
        while (At(LIn) <> #0) and (At(LIn) <> '"') do
        begin
          Inc(LOut);
          Result[LOut] := At(LIn);
          Inc(LIn);
        end;
        if At(LIn) = '"' then
        begin
          Inc(LOut);
          Result[LOut] := '"';
          Inc(LIn);
        end;
      end;
    end;
  end;
  SetLength(Result, LOut);
end;

end.
