{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the command line tool                          }
{  (compare two logs, pack and unpack the golden files)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program ParityTool;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  System.ZLib,
  DelphiDoom.Parity.Types in 'DelphiDoom.Parity.Types.pas',
  DelphiDoom.Parity.LogComparer in 'DelphiDoom.Parity.LogComparer.pas';

const
  GZIP_WINDOW_BITS = 15 + 16;
  EXIT_EQUAL = 0;
  EXIT_DIFFERENT = 1;
  EXIT_ERROR = 2;
  SUsage =
    'ParityTool compare <golden> <log>   first line where two logs differ (.gz files are unpacked); exit 0 = equal, 1 = different'#13#10 +
    'ParityTool pack <log> <log.gz>       packs a log (gzip)'#13#10 +
    'ParityTool unpack <log.gz> <log>     unpacks a log'#13#10 +
    'ParityTool count <log>               number of lines of a log (comments left out)';

function IsPacked(const AFileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(AFileName), '.gz');
end;

/// <summary>The bytes of a file; a .gz file is unpacked</summary>
function ReadBytes(const AFileName: string): TBytes;
var
  LFile: TFileStream;
  LUnpacked: TZDecompressionStream;
  LOutput: TBytesStream;
begin
  LFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    if IsPacked(AFileName) then
    begin
      LUnpacked := TZDecompressionStream.Create(LFile, GZIP_WINDOW_BITS);
      try
        LOutput := TBytesStream.Create;
        try
          LOutput.CopyFrom(LUnpacked, 0);
          Result := Copy(LOutput.Bytes, 0, LOutput.Size);
        finally
          LOutput.Free;
        end;
      finally
        LUnpacked.Free;
      end;
    end
    else
    begin
      SetLength(Result, LFile.Size);
      if LFile.Size > 0 then
        LFile.ReadBuffer(Result[0], LFile.Size);
    end;
  finally
    LFile.Free;
  end;
end;

function ReadLines(const AFileName: string): TArray<string>;
var
  LBytes: TBytes;
  LText: string;
begin
  LBytes := ReadBytes(AFileName);
  LText := TEncoding.ANSI.GetString(LBytes);
  Result := LText.Replace(#13, '').Split([#10]);
  // the last line ends with a line feed: the empty piece after it is not a line
  if (Length(Result) > 0) and (Result[High(Result)] = '') then
    SetLength(Result, Length(Result) - 1);
end;

procedure Pack(const AInput, AOutput: string);
var
  LBytes: TBytes;
  LFile: TFileStream;
  LPacker: TZCompressionStream;
begin
  LBytes := ReadBytes(AInput);
  LFile := TFileStream.Create(AOutput, fmCreate);
  try
    LPacker := TZCompressionStream.Create(LFile, zcMax, GZIP_WINDOW_BITS);
    try
      if Length(LBytes) > 0 then
        LPacker.WriteBuffer(LBytes[0], Length(LBytes));
    finally
      LPacker.Free;
    end;
  finally
    LFile.Free;
  end;
end;

procedure Unpack(const AInput, AOutput: string);
var
  LBytes: TBytes;
  LFile: TFileStream;
begin
  LBytes := ReadBytes(AInput);
  LFile := TFileStream.Create(AOutput, fmCreate);
  try
    if Length(LBytes) > 0 then
      LFile.WriteBuffer(LBytes[0], Length(LBytes));
  finally
    LFile.Free;
  end;
end;

function Run: Integer;
var
  LDifference: TParityDifference;
  LLines: TArray<string>;
  LLine: string;
  LCount: Integer;
begin
  Result := EXIT_ERROR;
  if ParamCount < 2 then
  begin
    Writeln(SUsage);
    Exit;
  end;
  if SameText(ParamStr(1), 'compare') and (ParamCount = 3) then
  begin
    LDifference := TParityLogComparer.Compare(ReadLines(ParamStr(2)), ReadLines(ParamStr(3)));
    Writeln(LDifference.Describe);
    if LDifference.Found then
      Exit(EXIT_DIFFERENT);
    Exit(EXIT_EQUAL);
  end;
  if SameText(ParamStr(1), 'pack') and (ParamCount = 3) then
  begin
    Pack(ParamStr(2), ParamStr(3));
    Exit(EXIT_EQUAL);
  end;
  if SameText(ParamStr(1), 'unpack') and (ParamCount = 3) then
  begin
    Unpack(ParamStr(2), ParamStr(3));
    Exit(EXIT_EQUAL);
  end;
  if SameText(ParamStr(1), 'count') and (ParamCount = 2) then
  begin
    LCount := 0;
    LLines := ReadLines(ParamStr(2));
    for LLine in LLines do
      if (LLine <> '') and (LLine[1] <> '#') then
        Inc(LCount);
    Writeln(LCount);
    Exit(EXIT_EQUAL);
  end;
  Writeln(SUsage);
end;

begin
  try
    ExitCode := Run;
  except
    on E: Exception do
    begin
      Writeln('ParityTool: ', E.Message);
      ExitCode := EXIT_ERROR;
    end;
  end;
end.
