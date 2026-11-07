{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib text - the scenarios of str.golden.txt       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Text.StrCases;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The same scenarios as the C++ harness that wrote str.golden.txt, run with TIdStr and
  ///   TIdStrings: every line has the same text as the line of the C++ run
  /// </summary>
  TIdLibStrCases = class
  public
    class procedure Run(const ALines: TStrings); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Str;

function Esc(const AText: AnsiString): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '"';
  for LIndex := 1 to Length(AText) do
  begin
    LByte := Byte(AText[LIndex]);
    if (LByte >= 32) and (LByte < 127) and (LByte <> Ord('\')) and (LByte <> Ord('"')) then
      Result := Result + Char(LByte)
    else
      Result := Result + '\x' + LowerCase(IntToHex(LByte, 2));
  end;
  Result := Result + '"';
end;

function B(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

function Samples: TArray<AnsiString>;
begin
  SetLength(Result, 20);
  Result[0] := '';
  Result[1] := 'hello';
  Result[2] := 'Hello World';
  Result[3] := 'c:\Games\doom3\base\maps\game\mp\file.map';
  Result[4] := 'textures/common/caulk.tga';
  Result[5] := '^1red^2green ^ ^3';
  Result[6] := '  trim me ' + #9#13#10;
  Result[7] := '"quoted"';
  Result[8] := 'a.b.c';
  Result[9] := '/base/models/./x.ase.bak';
  Result[10] := '123.45';
  Result[11] := '-12';
  Result[12] := '12.3.4';
  Result[13] := 'UPPER lower MiXeD';
  Result[14] := AnsiChar($E9) + 't' + AnsiChar($E9) + ' ' + AnsiChar($C9) + 'T' + AnsiChar($C9);
  Result[15] := 'x';
  Result[16] := 'abcabcabc';
  Result[17] := '.hidden';
  Result[18] := 'dir/';
  Result[19] := 'name.';
end;

const
  PATTERNS: array[0..10] of AnsiString = ('*', 'h*o', '*.tga', '?ello', '[a-z]*', '[H]ello*', '*/*/*',
    '[[]*', '*c*c*', 'H?llo*', '*[0-9]*');

class procedure TIdLibStrCases.Run(const ALines: TStrings);
var
  LSamples: TArray<AnsiString>;
  I, J, P, C: Integer;
  LText: AnsiString;
  A, T: TIdStr;
  LFloats: array[0..13] of Single;
  LInts: array[0..11] of Integer;
  LRemoved: Boolean;

  procedure Int(const AName: string; const AValue: Integer);
  begin
    ALines.Add(Format('%s %d %d', [AName, I, AValue]));
  end;

  procedure Mut(const AName: string; const AValue: TIdStr);
  begin
    ALines.Add(Format('%s %d %s', [AName, I, Esc(AValue.Text)]));
  end;

  procedure Fresh;
  begin
    T := TIdStr.Create(LText);
  end;

begin
  LSamples := Samples;
  for I := 0 to 19 do
  begin
    LText := LSamples[I];
    A := TIdStr.Create(LText);
    Int('len', A.Length);
    Int('IsNumeric', B(A.IsNumeric));
    Int('IsColor', B(A.IsColor));
    Int('HasLower', B(A.HasLower));
    Int('HasUpper', B(A.HasUpper));
    Int('LengthWithoutColors', A.LengthWithoutColors);
    Int('Hash', TIdStrings.Hash(LText));
    Int('IHash', TIdStrings.IHash(LText));
    if A.Length > 3 then
      Int('Hash3', TIdStrings.Hash(LText, 3))
    else
      Int('Hash3', TIdStrings.Hash(LText, A.Length));
    Int('FileNameHash', A.FileNameHash);
    Int('Last.', A.Last('.'));
    Int('Last/', A.Last('/'));
    Int('FindChar', A.Find('l'));
    Int('FindCharRange', A.Find('l', 3, 6));
    Int('FindText', A.Find('o'));
    Int('FindTextI', A.Find('O', False));
    Int('FindTextRange', A.Find('a', True, 1, 5));
    Int('CheckExt1', B(TIdStrings.CheckExtension(LText, 'map')));
    Int('CheckExt2', B(TIdStrings.CheckExtension(LText, 'MAP')));
    Int('CheckExt3', B(TIdStrings.CheckExtension(LText, 'e')));
    Int('CheckExt4', B(TIdStrings.CheckExtension(LText, 'tga')));
    Int('IsEmpty', B(A.IsEmpty));
    Fresh; T.RemoveColors; Mut('RemoveColors', T);
    Fresh; T.ToLower; Mut('ToLower', T);
    Fresh; T.ToUpper; Mut('ToUpper', T);
    ALines.Add(Format('StripMediaName %d %s', [I, Esc(TIdStrings.StripMediaName(LText))]));
    Mut('Left3', A.Left(3));
    Mut('Right3', A.Right(3));
    Mut('Right100', A.Right(100));
    Mut('Mid2_4', A.Mid(2, 4));
    Mut('Mid0_100', A.Mid(0, 100));
    Mut('Mid50_2', A.Mid(50, 2));
    Fresh; T.StripLeading('a'); Mut('StripLeadingC', T);
    Fresh; T.StripLeading('ab'); Mut('StripLeadingS', T);
    Fresh; T.StripLeading(' '); Mut('StripLeadingSpace', T);
    Fresh; LRemoved := T.StripLeadingOnce('ab');
    ALines.Add(Format('StripLeadingOnce %d %d %s', [I, B(LRemoved), Esc(T.Text)]));
    Fresh; T.StripTrailing('c'); Mut('StripTrailingC', T);
    Fresh; T.StripTrailing('bc'); Mut('StripTrailingS', T);
    Fresh; LRemoved := T.StripTrailingOnce('bc');
    ALines.Add(Format('StripTrailingOnce %d %d %s', [I, B(LRemoved), Esc(T.Text)]));
    Fresh; T.Strip(' '); Mut('StripSpace', T);
    Fresh; T.Strip('abc'); Mut('StripAbc', T);
    Fresh; T.StripTrailingWhitespace; Mut('StripTrailingWhitespace', T);
    Fresh; T.StripQuotes; Mut('StripQuotes', T);
    Fresh; T.BackSlashesToSlashes; Mut('BackSlashesToSlashes', T);
    Fresh; T.SetFileExtension('txt'); Mut('SetFileExtension1', T);
    Fresh; T.SetFileExtension('.xyz'); Mut('SetFileExtension2', T);
    Fresh; T.StripFileExtension; Mut('StripFileExtension', T);
    Fresh; T.StripAbsoluteFileExtension; Mut('StripAbsoluteFileExtension', T);
    Fresh; T.DefaultFileExtension('def'); Mut('DefaultFileExtension', T);
    Fresh; T.DefaultPath('base/'); Mut('DefaultPath', T);
    Fresh; T.AppendPath('sub\x.tga'); Mut('AppendPath1', T);
    Fresh; T.AppendPath('/y'); Mut('AppendPath2', T);
    Fresh; T.AppendPath(''); Mut('AppendPath3', T);
    Fresh; T.StripFilename; Mut('StripFilename', T);
    Fresh; T.StripPath; Mut('StripPath', T);
    Mut('ExtractFilePath', A.ExtractFilePath);
    Mut('ExtractFileName', A.ExtractFileName);
    Mut('ExtractFileBase', A.ExtractFileBase);
    Mut('ExtractFileExtension', A.ExtractFileExtension);
    Fresh; T.Insert('XY', 2); Mut('InsertS', T);
    Fresh; T.Insert('Z', -5); Mut('InsertC', T);
    Fresh; T.Insert('!!', 100); Mut('InsertEnd', T);
    Fresh; T.CapLength(4); Mut('CapLength4', T);
    Fresh; T.CapLength(100); Mut('CapLength100', T);
    Fresh; T.Replace('a', 'XX'); Mut('ReplaceA', T);
    Fresh; T.Replace('abc', '-'); Mut('ReplaceAbc', T);
    Fresh; T.Replace('l', ''); Mut('ReplaceL', T);
    Fresh; T.Replace('o', '0000000000'); Mut('ReplaceLong', T);
    Fresh; T.Append('123456', 3); Mut('AppendN', T);
    Fresh; T.Append('#'); Mut('AppendC', T);
    Fresh; T.Fill('*', 5); Mut('Fill', T);
    Fresh; T := A + '+' + A; Mut('Plus', T);
    Int('Cmp0', B(A = TIdStr.Create('hello')));
  end;

  for I := 0 to 19 do
    for J := 0 to 19 do
      ALines.Add(Format('pair %d %d %d %d %d %d %d %d %d %d', [I, J, TIdStrings.Cmp(LSamples[I], LSamples[J]),
        TIdStrings.Icmp(LSamples[I], LSamples[J]), TIdStrings.Cmpn(LSamples[I], LSamples[J], 5),
        TIdStrings.Icmpn(LSamples[I], LSamples[J], 5), TIdStrings.IcmpNoColor(LSamples[I], LSamples[J]),
        TIdStrings.IcmpPath(LSamples[I], LSamples[J]), TIdStrings.IcmpnPath(LSamples[I], LSamples[J], 6),
        TIdStr.Create(LSamples[I]).CmpPrefix(LSamples[J])]));

  for P := 0 to 10 do
    for I := 0 to 19 do
      ALines.Add(Format('filter %d %d %d %d', [P, I, B(TIdStrings.Filter(PATTERNS[P], LSamples[I], True)),
        B(TIdStrings.Filter(PATTERNS[P], LSamples[I], False))]));

  LFloats[0] := 0.0; LFloats[1] := 1.0; LFloats[2] := -1.5; LFloats[3] := 0.1; LFloats[4] := 3.14159274;
  LFloats[5] := 100.0; LFloats[6] := 1e-7; LFloats[7] := 1234.5678; LFloats[8] := 16777216.0;
  LFloats[9] := 0.5; LFloats[10] := 40000.25; LFloats[11] := 1e9; LFloats[12] := -0.000001; LFloats[13] := 2.5;
  for I := 0 to 13 do
  begin
    A := TIdStr.FromFloat(LFloats[I]);
    ALines.Add(Format('ctorfloat %d %s', [I, Esc(A.Text)]));
    T := 'v=';
    T.AppendFloat(LFloats[I]);
    ALines.Add(Format('pluseqfloat %d %s', [I, Esc(T.Text)]));
    for P := 0 to 3 do
      ALines.Add(Format('floatarray %d %d %s', [I, P, Esc(TIdStrings.FloatArrayToString([LFloats[I]], P))]));
  end;
  ALines.Add('floatarray3 ' + Esc(TIdStrings.FloatArrayToString([LFloats[0], LFloats[1], LFloats[2]], 2)));
  ALines.Add('floatarray5 ' + Esc(TIdStrings.FloatArrayToString([LFloats[2], LFloats[3], LFloats[4], LFloats[5],
    LFloats[6]], 3)));
  LInts[0] := 0; LInts[1] := 5; LInts[2] := 999; LInts[3] := 1000; LInts[4] := 1234; LInts[5] := 99999;
  LInts[6] := 1000000; LInts[7] := 12345678; LInts[8] := 1000000000; LInts[9] := 2147483647; LInts[10] := -5;
  LInts[11] := -1000;
  for I := 0 to 11 do
  begin
    ALines.Add(Format('formatnumber %d %s', [I, Esc(TIdStrings.FormatNumber(LInts[I]))]));
    ALines.Add(Format('ctorint %d %s', [I, Esc(TIdStr.FromInteger(LInts[I]).Text)]));
    ALines.Add(Format('ctoruint %d %s', [I, Esc(TIdStr.FromCardinal(Cardinal(LInts[I])).Text)]));
    T := 'n';
    T.AppendInteger(LInts[I]);
    T.AppendCardinal(Cardinal(LInts[I]));
    T.AppendBoolean(True);
    T.Append('c');
    ALines.Add(Format('pluseq %d %s', [I, Esc(T.Text)]));
  end;
  ALines.Add('ctorbool ' + Esc(TIdStr.FromBoolean(True).Text));
  ALines.Add('ctorchar ' + Esc(TIdStr.FromChar('q').Text));
  ALines.Add('ctorrange1 ' + Esc(TIdStr.Create('hello world', 2, 7).Text));
  ALines.Add('ctorrange2 ' + Esc(TIdStr.Create('hello world', -4, 100).Text));
  ALines.Add('ctorrange3 ' + Esc(TIdStr.Create('hello world', 9, 3).Text));
  C := 0;
  while C < 256 do
  begin
    ALines.Add(Format('chars %d %d%d%d%d%d%d%d%d %d %d', [C, B(TIdStrings.CharIsPrintable(C)),
      B(TIdStrings.CharIsLower(C)), B(TIdStrings.CharIsUpper(C)), B(TIdStrings.CharIsAlpha(C)),
      B(TIdStrings.CharIsNumeric(C)), B(TIdStrings.CharIsNewLine(AnsiChar(C))), B(TIdStrings.CharIsTab(AnsiChar(C))),
      TIdStrings.ColorIndex(C), Ord(TIdStrings.ToLower(AnsiChar(C))), Ord(TIdStrings.ToUpper(AnsiChar(C)))]));
    Inc(C, 5);
  end;
end;

end.
