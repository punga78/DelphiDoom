{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib text - the scenarios of codec.golden.txt     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Text.CodecCases;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>The same scenarios as the C++ harness for idBase64 and idCmdArgs (codec.golden.txt)</summary>
  TIdLibCodecCases = class
  public
    class procedure Base64(const ALines: TStrings); static;
    class procedure CmdArgs(const ALines: TStrings); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Base64, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Tests.IdLib.Fakes;

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

function Hex(const ABytes: TBytes): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(ABytes) do
    Result := Result + LowerCase(IntToHex(ABytes[LIndex], 2));
end;

class procedure TIdLibCodecCases.Base64(const ALines: TStrings);
const
  TEXTS: array[0..5] of AnsiString = ('', 'a', 'Man', 'hello world', 'Hello, World! '#$E9#$FF,
    'The quick brown fox jumps over the lazy dog');
  DECODES: array[0..13] of AnsiString = ('TWFu', 'TWE=', 'TQ==', 'TWFu TWFu'#10'TWFu', '!!!!', 'TW', 'T', '====',
    'TWFu=garbage', 'TWFuTWFu', 'AAAA', '////', '+/+/', 'TW Fu');
var
  LState: Cardinal;
  LBuf, LSub, LOut: TBytes;
  LIndex, LN: Integer;
  LCoder: TIdBase64;
begin
  ALines.Add('== base64');
  LState := 99;
  SetLength(LBuf, 300);
  for LIndex := 0 to 299 do
  begin
    LState := LState * 1664525 + 1013904223;
    LBuf[LIndex] := Byte(LState shr 24);
  end;
  for LN := 0 to 40 do
  begin
    LSub := Copy(LBuf, 0, LN);
    LCoder := TIdBase64.Create;
    try
      LCoder.Encode(LSub);
      ALines.Add(Format('enc %d %s', [LN, string(LCoder.Text)]));
      LOut := LCoder.Decode;
      ALines.Add(Format('dec %d %d %s dl=%d', [LN, Length(LOut), Hex(LOut), LCoder.DecodeLength]));
    finally
      LCoder.Free;
    end;
  end;
  LCoder := TIdBase64.Create;
  try
    LCoder.Encode(LBuf);
    ALines.Add('enc300 ' + string(LCoder.Text));
  finally
    LCoder.Free;
  end;
  for LIndex := 0 to 5 do
  begin
    LCoder := TIdBase64.Create;
    try
      LCoder.Encode(TEXTS[LIndex]);
      ALines.Add(Format('str %d %s %s', [LIndex, string(LCoder.Text), Esc(LCoder.DecodeToString)]));
    finally
      LCoder.Free;
    end;
  end;
  for LIndex := 0 to 13 do
  begin
    LCoder := TIdBase64.Create(DECODES[LIndex]);
    try
      LOut := LCoder.Decode;
      ALines.Add(Format('decode %d %d %s', [LIndex, Length(LOut), Hex(LOut)]));
    finally
      LCoder.Free;
    end;
  end;
end;

procedure PrintArgs(const ALines: TStrings; const APrefix: string; const AArgs: TIdCmdArgs);
var
  LLine: string;
  LIndex: Integer;
begin
  LLine := APrefix + Format(' argc=%d', [AArgs.Argc]);
  for LIndex := 0 to AArgs.Argc do
    LLine := LLine + ' ' + Esc(AArgs.Argv(LIndex));
  LLine := LLine + ' | args ' + Esc(AArgs.Args);
  LLine := LLine + ' | ' + Esc(AArgs.Args(0, 1, False));
  LLine := LLine + ' | ' + Esc(AArgs.Args(1, -1, True));
  LLine := LLine + ' | ' + Esc(AArgs.Args(0, 99, True));
  ALines.Add(LLine);
end;

class procedure TIdLibCodecCases.CmdArgs(const ALines: TStrings);
const
  COMMANDS: array[0..22] of AnsiString = ('map game/mp/d3dm1', 'set name "John Doe"', 'echo -5 +3 -x 12.5',
    'bind w "+forward"', 'connect 192.168.1.1:27960', 'exec some/path.cfg // comment', 'say $cvar_name rest',
    'a "quoted \n string" b', 'path c:\games\doom', '-1 - 2', 'x $', '', '   ', 'one', 'a /* c */ b',
    'x ''single quote'' y', '-', '- 5', '$ foo', 'name=value other:thing', '{ } ( ) ; ,', 'a "b" "c d" e',
    'tab'#9'sep'#9'here');
var
  LArgs, LCopy: TIdCmdArgs;
  LCVars: IIdLibCVars;
  LI, LKeep, LJ: Integer;
  LBig: AnsiString;
begin
  ALines.Add('== cmdargs');
  LCVars := TIdLibEchoCVars.Create;
  for LI := 0 to 22 do
    for LKeep := 0 to 1 do
    begin
      LArgs := TIdCmdArgs.Create(LCVars);
      try
        LArgs.TokenizeString(COMMANDS[LI], LKeep <> 0);
        PrintArgs(ALines, Format('cmd %d %d', [LI, LKeep]), LArgs);
      finally
        LArgs.Free;
      end;
    end;
  LBig := '';
  for LI := 0 to 79 do
    LBig := LBig + 'arg' + AnsiString(IntToStr(LI)) + ' ';
  LArgs := TIdCmdArgs.Create(LCVars);
  try
    LArgs.TokenizeString(LBig, False);
    ALines.Add(Format('many argc=%d last %s', [LArgs.Argc, Esc(LArgs.Argv(LArgs.Argc - 1))]));
    LBig := '';
    for LI := 0 to 2 do
    begin
      for LJ := 0 to 499 do
        LBig := LBig + 'x';
      LBig := LBig + ' ';
    end;
    LArgs.TokenizeString(LBig, False);
    ALines.Add(Format('long argc=%d', [LArgs.Argc]));
  finally
    LArgs.Free;
  end;
  LArgs := TIdCmdArgs.Create(LCVars);
  LCopy := TIdCmdArgs.Create(LCVars);
  try
    LArgs.AppendArg('first');
    LArgs.AppendArg('second one');
    LArgs.AppendArg('');
    LArgs.AppendArg('c:\x');
    PrintArgs(ALines, 'append', LArgs);
    LCopy.Assign(LArgs);
    PrintArgs(ALines, 'copy', LCopy);
    LArgs.Clear;
    ALines.Add(Format('cleared argc=%d', [LArgs.Argc]));
  finally
    LCopy.Free;
    LArgs.Free;
  end;
end;

end.
