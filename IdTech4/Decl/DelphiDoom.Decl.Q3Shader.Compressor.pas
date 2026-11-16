{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the compression of a shader file            }
{                                                                              }
{  Port of COM_Compress (game\q_shared.c) of Quake III Arena (id Software,     }
{  GPL v2 or later), which ScanAndLoadShaderFiles applies to every file        }
{  before anything is read from it. Based on the Quake III Arena GPL Source    }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Compressor;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   COM_Compress: drops the comments and keeps one blank or one new line where there were several. It matters:
  ///   a lone CR is a new line after it (the original reads files made with it), a comment glued to a word cuts
  ///   the word, and a comment between two words joins them.
  /// </summary>
  TQ3ShaderCompressor = class sealed
  public
    /// <summary>
    ///   The compressed text. <c>AMap</c> has one entry per character of the result: the 1 based position in
    ///   <c>AText</c> of the character it came from (of the first character of the word for the blank or the new
    ///   line that comes before it). The text ends at the first NUL, as the C string does.
    /// </summary>
    class function Compress(const AText: AnsiString; out AMap: TArray<Integer>): AnsiString; static;
  end;

implementation

class function TQ3ShaderCompressor.Compress(const AText: AnsiString; out AMap: TArray<Integer>): AnsiString;
var
  LIn, LOut, LLength: Integer;
  LChar: AnsiChar;
  LBuffer: AnsiString;
  LNewLine, LWhitespace: Boolean;

  function CharAt(const APosition: Integer): AnsiChar;
  begin
    if (APosition < 1) or (APosition > LLength) then
      Result := #0
    else
      Result := AText[APosition];
  end;

  procedure Emit(const ACharacter: AnsiChar; const ASource: Integer);
  begin
    Inc(LOut);
    LBuffer[LOut] := ACharacter;
    AMap[LOut - 1] := ASource;
  end;

begin
  LLength := Length(AText);
  SetLength(LBuffer, LLength + 2);
  SetLength(AMap, LLength + 2);
  LOut := 0;
  LIn := 1;
  LNewLine := False;
  LWhitespace := False;
  while CharAt(LIn) <> #0 do
  begin
    LChar := CharAt(LIn);
    // skip double slash comments
    if (LChar = '/') and (CharAt(LIn + 1) = '/') then
    begin
      while (CharAt(LIn) <> #0) and (CharAt(LIn) <> #10) do
        Inc(LIn);
    end
    // skip /* */ comments
    else if (LChar = '/') and (CharAt(LIn + 1) = '*') then
    begin
      while (CharAt(LIn) <> #0) and ((CharAt(LIn) <> '*') or (CharAt(LIn + 1) <> '/')) do
        Inc(LIn);
      if CharAt(LIn) <> #0 then
        Inc(LIn, 2);
    end
    // record when we hit a newline
    else if (LChar = #10) or (LChar = #13) then
    begin
      LNewLine := True;
      Inc(LIn);
    end
    // record when we hit whitespace
    else if (LChar = ' ') or (LChar = #9) then
    begin
      LWhitespace := True;
      Inc(LIn);
    end
    // an actual token
    else
    begin
      // if we have a pending newline, emit it (and it counts as whitespace)
      if LNewLine then
      begin
        Emit(#10, LIn);
        LNewLine := False;
        LWhitespace := False;
      end;
      if LWhitespace then
      begin
        Emit(' ', LIn);
        LWhitespace := False;
      end;
      // copy quoted strings unmolested
      if LChar = '"' then
      begin
        Emit(LChar, LIn);
        Inc(LIn);
        while True do
        begin
          LChar := CharAt(LIn);
          if (LChar <> #0) and (LChar <> '"') then
          begin
            Emit(LChar, LIn);
            Inc(LIn);
          end
          else
            Break;
        end;
        if LChar = '"' then
        begin
          Emit(LChar, LIn);
          Inc(LIn);
        end;
      end
      else
      begin
        Emit(LChar, LIn);
        Inc(LIn);
      end;
    end;
  end;
  SetLength(LBuffer, LOut);
  Result := LBuffer;
  SetLength(AMap, LOut);
end;

end.
