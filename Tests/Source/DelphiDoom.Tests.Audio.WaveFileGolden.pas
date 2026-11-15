{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of TWaveFile with the real idWaveFile (DUnitX)           }
{                                                                              }
{  Tests\Data\Audio\waveio.golden.txt is the output of the REAL                }
{  snd_wavefile.cpp of Doom 3 (bcc32c, 32 bit; idlib real; a file system and   }
{  idFile in memory: Tests\Data\Audio\harness\driver_wave.cpp.txt) on the      }
{  scenarios of waveio.input.txt: Open, Read, Seek, ResetFile, Close and       }
{  OpenFromMemory. TWaveFile must give the same lines.                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveFileGolden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Audio.WaveFile.Types, DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.WaveFile,
  DelphiDoom.Tests.Audio.WaveFile;

type
  [TestFixture]
  [Category('audio')]
  TTestWaveFileGolden = class(TObject)
  strict private
    FLines: TStringList;
    FFiles: TFakeWaveFileSystem;
    FFilesIntf: IWaveFileSystem;
    FWave: TWaveFile;
    function DataFolder: string;
    class function Number(const AText: string): Int64; static;
    class procedure Append(var ABytes: TBytes; AValue: Int64; ACount: Integer); static;
    class procedure AddTokens(var ABytes: TBytes; const ALine: string); static;
    procedure Execute(const AOperation: string);
    function Run(const AInput: TStrings): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdWaveFile;
  end;

implementation

function TTestWaveFileGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Audio\');
end;

class function TTestWaveFileGolden.Number(const AText: string): Int64;
begin
  if AText.StartsWith('0x') then
    Result := StrToInt64('$' + Copy(AText, 3, MaxInt))
  else
    Result := StrToInt64(AText);
end;

class procedure TTestWaveFileGolden.Append(var ABytes: TBytes; AValue: Int64; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    SetLength(ABytes, Length(ABytes) + 1);
    ABytes[High(ABytes)] := (AValue shr (8 * LIndex)) and $FF;
  end;
end;

// the tokens of a line of bytes: T:abcd, B:n, W:n, D:n, Z:n, X:hex
class procedure TTestWaveFileGolden.AddTokens(var ABytes: TBytes; const ALine: string);
var
  LToken: string;
  LValue: string;
  LIndex: Integer;
begin
  for LToken in ALine.Split([' '], TStringSplitOptions.ExcludeEmpty) do
  begin
    LValue := Copy(LToken, 3, MaxInt);
    case LToken[1] of
      'T':
        for LIndex := 1 to Length(LValue) do
          if LValue[LIndex] = '_' then
            Append(ABytes, Ord(' '), 1)
          else
            Append(ABytes, Ord(LValue[LIndex]), 1);
      'B': Append(ABytes, Number(LValue), 1);
      'W': Append(ABytes, Number(LValue), 2);
      'D': Append(ABytes, Number(LValue), 4);
      'Z':
        for LIndex := 1 to Number(LValue) do
          Append(ABytes, 0, 1);
      'X':
        begin
          LIndex := 1;
          while LIndex < Length(LValue) do
          begin
            Append(ABytes, StrToInt('$' + Copy(LValue, LIndex, 2)), 1);
            Inc(LIndex, 2);
          end;
        end;
    end;
  end;
end;

procedure TTestWaveFileGolden.Execute(const AOperation: string);
var
  LWords: TArray<string>;
  LFormat: TWaveFormat;
  LRet: Integer;
  LCount: Integer;
  LBuffer: TBytes;
  LGot: Integer;
  LHash: Cardinal;
  LIndex: Integer;
  LData: TBytes;
begin
  LWords := AOperation.Split([' '], TStringSplitOptions.ExcludeEmpty);
  FLines.Add('> ' + string.Join(' ', LWords));
  if LWords[0] = 'open' then
  begin
    FreeAndNil(FWave);
    FWave := TWaveFile.Create(FFilesIntf);
    LRet := FWave.Open(LWords[1], LFormat);
    FLines.Add(Format('ret=%d', [LRet]));
    if LRet = 0 then
      FLines.Add(Format(' size=%d mem=%d base=%u cksize=%u', [FWave.OutputSize, FWave.MemorySize,
        Cardinal(FWave.SeekBase), Cardinal(FWave.MemorySize)]));
  end
  else if LWords[0] = 'mem' then
  begin
    LCount := Integer(Number(LWords[1]));
    SetLength(LData, LCount + 1);
    for LIndex := 0 to LCount - 1 do
      LData[LIndex] := Byte(LIndex * 7 + 3);
    FreeAndNil(FWave);
    FWave := TWaveFile.Create(FFilesIntf);
    LFormat := Default(TWaveFormat);
    LRet := FWave.OpenFromMemory(@LData[0], LCount, LFormat);
    FLines.Add(Format('ret=%d size=%d mem=%d', [LRet, FWave.OutputSize, FWave.MemorySize]));
  end
  else if (LWords[0] = 'read') and Assigned(FWave) then
  begin
    LCount := Integer(Number(LWords[1]));
    SetLength(LBuffer, LCount + 16);
    LGot := -777;
    LRet := FWave.Read(@LBuffer[0], LCount, LGot);
    LHash := 2166136261;
    if LRet > 0 then
      for LIndex := 0 to LRet - 1 do
        LHash := (LHash xor LBuffer[LIndex]) * 16777619;
    FLines.Add(Format('read ret=%d got=%d hash=%s', [LRet, LGot, IntToHex(LHash, 8)]));
  end
  else if (LWords[0] = 'seek') and Assigned(FWave) then
    FLines.Add(Format('seek ret=%d', [FWave.Seek(Integer(Number(LWords[1])))]))
  else if (LWords[0] = 'reset') and Assigned(FWave) then
    FLines.Add(Format('reset ret=%d', [FWave.ResetFile]))
  else if (LWords[0] = 'close') and Assigned(FWave) then
    FLines.Add(Format('close ret=%d', [FWave.Close]));
end;

function TTestWaveFileGolden.Run(const AInput: TStrings): TStringList;
var
  LLine: string;
  LFile: string;
  LInFile: Boolean;
  LBytes: TBytes;
begin
  Result := TStringList.Create;
  FLines := Result;
  FFiles := TFakeWaveFileSystem.Create;
  FFilesIntf := FFiles;
  LInFile := False;
  try
    for LLine in AInput do
    begin
      if LLine.StartsWith('@case ') then
      begin
        FFiles := TFakeWaveFileSystem.Create;
        FFilesIntf := FFiles;
        FreeAndNil(FWave);
        LInFile := False;
        FLines.Add('## ' + Copy(LLine, 7, MaxInt));
      end
      else if LLine = '@end' then
        LInFile := False
      else if LLine.StartsWith('@file ') then
      begin
        LFile := Copy(LLine, 7, MaxInt);
        FFiles.Add(LFile, nil);
        LBytes := nil;
        LInFile := True;
      end
      else if LLine.StartsWith('@op ') then
      begin
        LInFile := False;
        Execute(Copy(LLine, 5, MaxInt));
      end
      else if LInFile then
      begin
        AddTokens(LBytes, LLine);
        FFiles.Add(LFile, LBytes);
      end;
    end;
  finally
    FreeAndNil(FWave);
    FFilesIntf := nil;
    FFiles := nil;
    FLines := nil;
  end;
end;

procedure TTestWaveFileGolden.DovrebbeDareLeStesseRisposteDelVeroIdWaveFile;
var
  LInput, LGolden, LActual: TStringList;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'waveio.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'waveio.golden.txt', TEncoding.ANSI);
    LActual := Run(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (LGolden[LIndex] <> LActual[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.waveio.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWaveFileGolden);

end.
