{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - fixed answers of libsndfile (C)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.Golden;

interface

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections;

type
  /// <summary>
  ///   The fingerprints of what libsndfile (C) gave for each test sound, kept
  ///   in Tests\Data\sound_golden.txt as "key TAB hex" lines. The file was
  ///   written while the C engine was still in the repository (see
  ///   Tests\Data\README.md)
  /// </summary>
  TSoundGolden = class
  private
    FValues: TDictionary<string, UInt64>;
    class function FilePath: string; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The fingerprint of AKey; raises when there is none</summary>
    function Get(const AKey: string): UInt64;
  end;

implementation

{ TSoundGolden }

constructor TSoundGolden.Create;
var
  LLine: string;
  LTab: Integer;
begin
  inherited Create;
  FValues := TDictionary<string, UInt64>.Create;
  for LLine in TFile.ReadAllLines(FilePath, TEncoding.UTF8) do
  begin
    LTab := Pos(#9, LLine);
    if LTab > 0 then
      FValues.Add(Copy(LLine, 1, LTab - 1), StrToUInt64('$' + Copy(LLine, LTab + 1, MaxInt)));
  end;
end;

destructor TSoundGolden.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

class function TSoundGolden.FilePath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\sound_golden.txt'));
end;

function TSoundGolden.Get(const AKey: string): UInt64;
begin
  if not FValues.TryGetValue(AKey, Result) then
    raise Exception.CreateFmt('no fixed answer for "%s" in %s', [AKey, FilePath]);
end;

end.
