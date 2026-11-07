{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib hashing - the input buffers of the goldens   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Hashing.Cases;

interface

uses
  System.SysUtils;

type
  /// <summary>The buffers of hashing.golden.txt: the same as in the C++ harness</summary>
  TIdLibHashingCases = class
  public
    /// <summary>Calls the procedure for every case: name (std0..std6, rnd1..rnd70000) and bytes</summary>
    class procedure ForEach(const AProc: TProc<string, TBytes>); static;
    /// <summary>A valid pointer to the bytes, also for an empty array (never nil)</summary>
    class function Ptr(const ABytes: TBytes): PByte; static;
  end;

implementation

uses
  DelphiDoom.Tests.IdLib.Golden;

const
  STANDARD_TEXTS: array[0..6] of AnsiString = (
    '',
    'a',
    'abc',
    'message digest',
    'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
    '12345678901234567890123456789012345678901234567890123456789012345678901234567890');
  RANDOM_LENGTHS: array[0..20] of Integer = (1, 2, 3, 54, 55, 56, 57, 63, 64, 65, 119, 120, 121, 127,
    128, 129, 200, 1000, 4096, 65536, 70000);

const
  GEmptyByte: Byte = 0;

class function TIdLibHashingCases.Ptr(const ABytes: TBytes): PByte;
begin
  if Length(ABytes) = 0 then
    Result := @GEmptyByte
  else
    Result := @ABytes[0];
end;

class procedure TIdLibHashingCases.ForEach(const AProc: TProc<string, TBytes>);
var
  LIndex: Integer;
  LBytes, LRandom: TBytes;
  LSampler: TIdLibSampler;
begin
  for LIndex := 0 to High(STANDARD_TEXTS) do
  begin
    SetLength(LBytes, Length(STANDARD_TEXTS[LIndex]));
    if Length(LBytes) > 0 then
      Move(STANDARD_TEXTS[LIndex][1], LBytes[0], Length(LBytes));
    AProc('std' + IntToStr(LIndex), LBytes);
  end;
  LSampler := TIdLibSampler.Create(12345);
  try
    SetLength(LRandom, 70000);
    for LIndex := 0 to 69999 do
      LRandom[LIndex] := LSampler.NextByte;
  finally
    LSampler.Free;
  end;
  for LIndex := 0 to High(RANDOM_LENGTHS) do
  begin
    SetLength(LBytes, RANDOM_LENGTHS[LIndex]);
    Move(LRandom[0], LBytes[0], RANDOM_LENGTHS[LIndex]);
    AProc('rnd' + IntToStr(RANDOM_LENGTHS[LIndex]), LBytes);
  end;
end;

end.
