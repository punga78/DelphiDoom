{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - the dump of the parity harness      }
{                                                                              }
{  Writes exactly what Tools\Verifica\176\yaml\harness.cpp (Dump, Num, Esc,    }
{  RunCase) writes for the real yaml-cpp 0.7.0: the golden files are compared  }
{  with this text, byte by byte                                                }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.Dumper;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf;

type
  /// <summary>The canonical dump of a document used for the parity with yaml-cpp</summary>
  TYamlParityDumper = class
  public
    /// <summary>Esc() of the harness: backslash, \n \r \t and \xHH for the other control and non ASCII bytes</summary>
    class function Esc(const AText: TYamlText): TYamlText; static;
    /// <summary>The cases of a corpus file: separated by a line %%%% (every case ends with a line end)</summary>
    class function SplitCases(const ABytes: TBytes): TArray<TYamlText>; static;
    /// <summary>The conversions of a scalar (Num of the harness)</summary>
    class function Num(const ANode: IYamlNode): TYamlText; static;
    class procedure Dump(const ANode: IYamlNode; AIndent: Integer; var AOut: TYamlText; const APrefix: TYamlText); static;
    /// <summary>RunCase of the harness: parses a text and writes the documents and what the emitter makes of them</summary>
    class function RunCase(const AText: TYamlText): TYamlText; static;
    /// <summary>The text after the case number lines: the lines of one case of a golden file</summary>
    class function CaseSeparator(AIndex: Integer): TYamlText; static;
  end;

implementation

uses
  DelphiDoom.Yaml.Convert,
  DelphiDoom.Yaml.Factory;

class function TYamlParityDumper.Esc(const AText: TYamlText): TYamlText;
var
  I: Integer;
  C: Byte;
begin
  Result := '';
  for I := 1 to Length(AText) do
  begin
    C := Byte(AText[I]);
    if C = Ord('\') then
      Result := Result + '\\'
    else if C = 10 then
      Result := Result + '\n'
    else if C = 13 then
      Result := Result + '\r'
    else if C = 9 then
      Result := Result + '\t'
    else if (C < 32) or (C >= 127) then
      Result := Result + '\x' + TYamlText(IntToHex(C, 2))
    else
      Result := Result + AnsiChar(C);
  end;
end;

class function TYamlParityDumper.SplitCases(const ABytes: TBytes): TArray<TYamlText>;
var
  LCurrent: TYamlText;
  LLine: TYamlText;
  I, LStart: Integer;
  LCases: TArray<TYamlText>;

  procedure TakeLine(AFrom, ATo: Integer);
  begin
    SetLength(LLine, ATo - AFrom);
    if ATo > AFrom then
      Move(ABytes[AFrom], LLine[1], ATo - AFrom);
    if LLine = '%%%%' then
    begin
      SetLength(LCases, Length(LCases) + 1);
      LCases[High(LCases)] := LCurrent;
      LCurrent := '';
    end
    else
      LCurrent := LCurrent + LLine + #10;
  end;

begin
  LCases := nil;
  LCurrent := '';
  LStart := 0;
  for I := 0 to High(ABytes) do
    if ABytes[I] = 10 then
    begin
      TakeLine(LStart, I);
      LStart := I + 1;
    end;
  if LStart < Length(ABytes) then
    TakeLine(LStart, Length(ABytes));
  SetLength(LCases, Length(LCases) + 1);
  LCases[High(LCases)] := LCurrent;
  Result := LCases;
end;

class function TYamlParityDumper.CaseSeparator(AIndex: Integer): TYamlText;
begin
  Result := '#' + TYamlText(IntToStr(AIndex)) + #10;
end;

class function TYamlParityDumper.Num(const ANode: IYamlNode): TYamlText;
var
  LInteger: Integer;
  LCardinal: Cardinal;
  LInt64: Int64;
  LSmall: SmallInt;
  LChar: AnsiChar;
  LDouble: Double;
  LSingle: Single;
  LBool: Boolean;
begin
  Result := 'i=';
  if ANode.TryAsInteger(LInteger) then
    Result := Result + TYamlText(IntToStr(LInteger))
  else
    Result := Result + '!';
  Result := Result + ' u=';
  if ANode.TryAsCardinal(LCardinal) then
    Result := Result + TYamlText(UIntToStr(LCardinal))
  else
    Result := Result + '!';
  Result := Result + ' l=';
  if ANode.TryAsInt64(LInt64) then
    Result := Result + TYamlText(IntToStr(LInt64))
  else
    Result := Result + '!';
  Result := Result + ' s=';
  if ANode.TryAsSmallInt(LSmall) then
    Result := Result + TYamlText(IntToStr(LSmall))
  else
    Result := Result + '!';
  Result := Result + ' c=';
  if ANode.TryAsChar(LChar) then
    Result := Result + LChar
  else
    Result := Result + '!';
  Result := Result + ' d=';
  if ANode.TryAsDouble(LDouble) then
    Result := Result + TYamlConvert.FormatGeneral(LDouble, 17)
  else
    Result := Result + '!';
  Result := Result + ' f=';
  if ANode.TryAsSingle(LSingle) then
    Result := Result + TYamlConvert.FormatGeneral(LSingle, 17)
  else
    Result := Result + '!';
  if ANode.TryAsBoolean(LBool) then
  begin
    if LBool then
      Result := Result + ' b=T'
    else
      Result := Result + ' b=F';
  end
  else
    Result := Result + ' b=!';
end;

class procedure TYamlParityDumper.Dump(const ANode: IYamlNode; AIndent: Integer; var AOut: TYamlText;
  const APrefix: TYamlText);
var
  LSpace: TYamlText;
  LStyle: TYamlText;
  LItem: IYamlNode;
  LPair: TYamlPair;
begin
  LSpace := TYamlText(StringOfChar(' ', AIndent * 2));
  if AIndent > 30 then
  begin
    AOut := AOut + LSpace + APrefix + 'CYCLE'#10;
    Exit;
  end;
  case ANode.NodeType of
    ntUndefined:
      AOut := AOut + LSpace + APrefix + 'UNDEF'#10;
    ntNull:
      AOut := AOut + LSpace + APrefix + 'NULL tag=' + Esc(ANode.Tag) + #10;
    ntScalar:
      AOut := AOut + LSpace + APrefix + 'S "' + Esc(ANode.Scalar) + '" tag=' + Esc(ANode.Tag) + ' ' + Num(ANode) + #10;
    ntSequence:
      begin
        if ANode.Style = esFlow then
          LStyle := 'F'
        else
          LStyle := 'B';
        AOut := AOut + LSpace + APrefix + 'Q ' + LStyle + ' tag=' + Esc(ANode.Tag) + ' n=' +
          TYamlText(IntToStr(ANode.Size)) + #10;
        for LItem in ANode.Items do
          Dump(LItem, AIndent + 1, AOut, '- ');
      end;
    ntMap:
      begin
        if ANode.Style = esFlow then
          LStyle := 'F'
        else
          LStyle := 'B';
        AOut := AOut + LSpace + APrefix + 'M ' + LStyle + ' tag=' + Esc(ANode.Tag) + ' n=' +
          TYamlText(IntToStr(ANode.Size)) + #10;
        for LPair in ANode.Pairs do
        begin
          Dump(LPair.Key, AIndent + 1, AOut, 'K ');
          Dump(LPair.Value, AIndent + 1, AOut, 'V ');
        end;
      end;
  end;
end;

class function TYamlParityDumper.RunCase(const AText: TYamlText): TYamlText;
var
  LParser: IYamlParser;
  LDocs: TArray<IYamlNode>;
  LDoc: IYamlNode;
  LEmitter: IYamlEmitter;
  LEmitted: TYamlText;
  LStart, LNul, I: Integer;
begin
  LParser := TYamlFactory.CreateParser;
  try
    LDocs := LParser.LoadAll(AText);
  except
    on E: EYamlException do
      Exit('ERR ' + Esc(E.Msg) + ' @' + TYamlText(IntToStr(E.Mark.Line)) + ':' + TYamlText(IntToStr(E.Mark.Column)) + #10);
    on EYamlEndlessDocumentsException do
      Exit('ERR other'#10);
  end;
  Result := 'OK docs=' + TYamlText(IntToStr(Length(LDocs))) + #10;
  for LDoc in LDocs do
  begin
    Result := Result + 'DOC'#10;
    Dump(LDoc, 0, Result, '');
    LEmitter := TYamlFactory.CreateEmitter;
    LEmitter.WriteNode(LDoc);
    if LEmitter.Good then
      Result := Result + 'EMIT good'#10
    else
      Result := Result + 'EMIT bad:' + Esc(LEmitter.LastError) + #10;
    // c_str() ends at the first zero byte
    LEmitted := LEmitter.Text;
    LNul := 0;
    for I := 1 to Length(LEmitted) do
      if LEmitted[I] = #0 then
      begin
        LNul := I;
        Break;
      end;
    if LNul > 0 then
      LEmitted := Copy(LEmitted, 1, LNul - 1);
    // getline: the lines, and a last one without line end
    LStart := 1;
    for I := 1 to Length(LEmitted) do
      if LEmitted[I] = #10 then
      begin
        Result := Result + '| ' + Esc(Copy(LEmitted, LStart, I - LStart)) + #10;
        LStart := I + 1;
      end;
    if LStart <= Length(LEmitted) then
      Result := Result + '| ' + Esc(Copy(LEmitted, LStart, MaxInt)) + #10;
    Result := Result + '|.'#10;
  end;
end;

end.
