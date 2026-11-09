{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - the emitter scripts of the harness  }
{                                                                              }
{  Runs the scripts of Tests\Data\Yaml\emit_*.corpus.txt (the format is        }
{  described in Tools\Verifica\176\yaml\emitcases.h) on the emitter of the     }
{  library and writes the same log as the harness writes for yaml-cpp          }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.EmitScript;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types;

type
  /// <summary>One script of emitter operations and the log it makes</summary>
  TYamlEmitScript = class
  strict private
    class function FromHex(const AHex: TYamlText): TYamlText; static;
    class function HexOf(const AText: TYamlText): TYamlText; static;
    class function ManipByName(const AName: TYamlText): TYamlManip; static;
    class function Words(const ALine: TYamlText): TArray<TYamlText>; static;
  public
    /// <summary>The log of the harness: the results of the setters, good or bad, the size and the lines (hex)</summary>
    class function Run(const AScript: TYamlText): TYamlText; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory;

const
  ManipNames: array[TYamlManip] of string = (
    'Auto', 'TagByKind', 'Newline', 'EmitNonAscii', 'EscapeNonAscii', 'EscapeAsJson', 'SingleQuoted',
    'DoubleQuoted', 'Literal', 'LowerNull', 'UpperNull', 'CamelNull', 'TildeNull', 'YesNoBool', 'TrueFalseBool',
    'OnOffBool', 'UpperCase', 'LowerCase', 'CamelCase', 'LongBool', 'ShortBool', 'Dec', 'Hex', 'Oct', 'BeginDoc',
    'EndDoc', 'BeginSeq', 'EndSeq', 'Flow', 'Block', 'BeginMap', 'EndMap', 'Key', 'Value', 'LongKey');

class function TYamlEmitScript.HexOf(const AText: TYamlText): TYamlText;
var
  I: Integer;
begin
  if AText = '' then
    Exit('-');
  Result := '';
  for I := 1 to Length(AText) do
    Result := Result + TYamlText(LowerCase(IntToHex(Byte(AText[I]), 2)));
end;

class function TYamlEmitScript.FromHex(const AHex: TYamlText): TYamlText;
var
  I: Integer;
begin
  Result := '';
  if AHex = '-' then
    Exit;
  I := 1;
  while I < Length(AHex) do
  begin
    Result := Result + AnsiChar(StrToInt('$' + string(Copy(AHex, I, 2))));
    Inc(I, 2);
  end;
end;

class function TYamlEmitScript.ManipByName(const AName: TYamlText): TYamlManip;
var
  M: TYamlManip;
begin
  for M := Low(TYamlManip) to High(TYamlManip) do
    if string(AName) = ManipNames[M] then
      Exit(M);
  Result := ymAuto;
end;

class function TYamlEmitScript.Words(const ALine: TYamlText): TArray<TYamlText>;
var
  I, LStart: Integer;
begin
  Result := nil;
  I := 1;
  while I <= Length(ALine) do
  begin
    while (I <= Length(ALine)) and (ALine[I] = ' ') do
      Inc(I);
    LStart := I;
    while (I <= Length(ALine)) and (ALine[I] <> ' ') do
      Inc(I);
    if I > LStart then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Copy(ALine, LStart, I - LStart);
    end;
  end;
end;

class function TYamlEmitScript.Run(const AScript: TYamlText): TYamlText;
var
  LEmitter: IYamlEmitter;
  LStart, I, LNul: Integer;
  LLine, LOp, LArg1, LArg2: TYamlText;
  LWords: TArray<TYamlText>;
  LOk: Boolean;
  LBits: UInt64;
  LFloatBits: Cardinal;
  LDouble: Double;
  LSingle: Single;
  LData: TYamlText;
  LBytes: TBytes;
  LText: TYamlText;

  function Arg(AIndex: Integer): TYamlText;
  begin
    if AIndex < Length(LWords) then
      Result := LWords[AIndex]
    else
      Result := '-';
  end;

  function IntArg(AIndex: Integer): Int64;
  begin
    Result := StrToInt64Def(string(Arg(AIndex)), 0);
  end;

  procedure Execute(const ALineText: TYamlText);
  begin
    LWords := Words(ALineText);
    if Length(LWords) = 0 then
      Exit;
    LOp := LWords[0];
    LArg1 := Arg(1);
    LArg2 := Arg(2);
    if LOp = 'S' then
      LEmitter.WriteString(FromHex(LArg1))
    else if LOp = 'B' then
      LEmitter.WriteBool(LArg1 = '1')
    else if (LOp = 'C') or (LOp = 'UC') then
      LEmitter.WriteChar(Byte(IntArg(1) and $FF))
    else if LOp = 'N' then
      LEmitter.WriteNull
    else if LOp = 'I' then
      LEmitter.WriteInteger(Integer(IntArg(1)))
    else if LOp = 'U' then
      LEmitter.WriteCardinal(Cardinal(StrToUInt64Def(string(LArg1), 0)))
    else if LOp = 'H' then
      LEmitter.WriteSmallInt(SmallInt(IntArg(1)))
    else if LOp = 'W' then
      LEmitter.WriteWord(Word(StrToUInt64Def(string(LArg1), 0)))
    else if LOp = 'L' then
      LEmitter.WriteInt64(IntArg(1))
    else if LOp = 'Q' then
      LEmitter.WriteUInt64(StrToUInt64Def(string(LArg1), 0))
    else if LOp = 'D' then
    begin
      LBits := StrToUInt64('$' + string(LArg1));
      LDouble := PDouble(@LBits)^;
      LEmitter.WriteDouble(LDouble);
    end
    else if LOp = 'F' then
    begin
      LFloatBits := Cardinal(StrToUInt64('$' + string(LArg1)));
      LSingle := PSingle(@LFloatBits)^;
      LEmitter.WriteSingle(LSingle);
    end
    else if LOp = 'BIN' then
    begin
      LData := FromHex(LArg1);
      SetLength(LBytes, Length(LData));
      if Length(LData) > 0 then
        Move(LData[1], LBytes[0], Length(LData));
      LEmitter.WriteBinary(LBytes);
    end
    else if LOp = 'M' then
      LEmitter.Manip(ManipByName(LArg1))
    else if LOp = 'IND' then
      LEmitter.LocalIndent(Integer(IntArg(1)))
    else if LOp = 'PF' then
      LEmitter.LocalPrecision(Integer(IntArg(1)), -1)
    else if LOp = 'PD' then
      LEmitter.LocalPrecision(-1, Integer(IntArg(1)))
    else if LOp = 'PB' then
      LEmitter.LocalPrecision(Integer(IntArg(1)), Integer(IntArg(1)))
    else if LOp = 'AL' then
      LEmitter.WriteAlias(FromHex(LArg1))
    else if LOp = 'AN' then
      LEmitter.WriteAnchor(FromHex(LArg1))
    else if LOp = 'TV' then
      LEmitter.WriteTag(etVerbatim, '', FromHex(LArg1))
    else if LOp = 'TP' then
      LEmitter.WriteTag(etPrimaryHandle, '', FromHex(LArg1))
    else if LOp = 'TN' then
      LEmitter.WriteTag(etNamedHandle, FromHex(LArg1), FromHex(LArg2))
    else if LOp = 'CM' then
      LEmitter.WriteComment(FromHex(LArg1))
    else if LOp[1] = 'G' then
    begin
      LOk := False;
      if LOp = 'GSetOutputCharset' then
        LOk := LEmitter.SetOutputCharset(ManipByName(LArg1))
      else if LOp = 'GSetStringFormat' then
        LOk := LEmitter.SetStringFormat(ManipByName(LArg1))
      else if LOp = 'GSetBoolFormat' then
        LOk := LEmitter.SetBoolFormat(ManipByName(LArg1))
      else if LOp = 'GSetNullFormat' then
        LOk := LEmitter.SetNullFormat(ManipByName(LArg1))
      else if LOp = 'GSetIntBase' then
        LOk := LEmitter.SetIntBase(ManipByName(LArg1))
      else if LOp = 'GSetSeqFormat' then
        LOk := LEmitter.SetSeqFormat(ManipByName(LArg1))
      else if LOp = 'GSetMapFormat' then
        LOk := LEmitter.SetMapFormat(ManipByName(LArg1))
      else if LOp = 'GSetIndent' then
        LOk := LEmitter.SetIndent(NativeUInt(IntArg(1)))
      else if LOp = 'GSetPreCommentIndent' then
        LOk := LEmitter.SetPreCommentIndent(NativeUInt(IntArg(1)))
      else if LOp = 'GSetPostCommentIndent' then
        LOk := LEmitter.SetPostCommentIndent(NativeUInt(IntArg(1)))
      else if LOp = 'GSetFloatPrecision' then
        LOk := LEmitter.SetFloatPrecision(NativeUInt(IntArg(1)))
      else if LOp = 'GSetDoublePrecision' then
        LOk := LEmitter.SetDoublePrecision(NativeUInt(IntArg(1)))
      else if LOp = 'GRestore' then
      begin
        LEmitter.RestoreGlobalModifiedSettings;
        LOk := True;
      end;
      Result := Result + 'set ' + LOp + ' ' + LArg1 + ' -> ' + TYamlText(IntToStr(Ord(LOk))) + #10;
    end;
  end;

begin
  Result := '';
  LEmitter := TYamlFactory.CreateEmitter;
  LStart := 1;
  for I := 1 to Length(AScript) do
    if AScript[I] = #10 then
    begin
      LLine := Copy(AScript, LStart, I - LStart);
      Execute(LLine);
      LStart := I + 1;
    end;
  if LStart <= Length(AScript) then
    Execute(Copy(AScript, LStart, MaxInt));
  if LEmitter.Good then
    Result := Result + 'good'
  else
    Result := Result + 'bad:' + HexOf(LEmitter.LastError);
  Result := Result + ' size=' + TYamlText(IntToStr(LEmitter.Size)) + #10;
  LText := LEmitter.Text;
  LNul := 0;
  for I := 1 to Length(LText) do
    if LText[I] = #0 then
    begin
      LNul := I;
      Break;
    end;
  if LNul > 0 then
    LText := Copy(LText, 1, LNul - 1);
  LStart := 1;
  for I := 1 to Length(LText) do
    if LText[I] = #10 then
    begin
      Result := Result + '| ' + HexOf(Copy(LText, LStart, I - LStart)) + #10;
      LStart := I + 1;
    end;
  if LStart <= Length(LText) then
    Result := Result + '| ' + HexOf(Copy(LText, LStart, MaxInt)) + #10;
  Result := Result + '|.'#10;
end;

end.
