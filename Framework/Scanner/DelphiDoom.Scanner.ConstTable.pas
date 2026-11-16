{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the table of the named integer constants      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.ConstTable;

interface

uses
  System.Generics.Collections;

type
  /// <summary>What happened to a name given to TScannerConstTable.Add</summary>
  TScannerConstAddResult = (
    /// <summary>The constant is in the table</summary>
    carAdded,
    /// <summary>The name is empty (or only blanks): nothing was added</summary>
    carEmptyName,
    /// <summary>The name is already in the table: the old value stays</summary>
    carDuplicate
  );

  /// <summary>
  ///   The constants of the scripts (ACTORDEF, DECORATE): upper-case names with an integer
  ///   value (the old sc_consts, with the same sixteen buckets and the same search inside
  ///   a bucket: ignoring the case with AnsiCompareText)
  /// </summary>
  TScannerConstTable = class sealed
  strict private
    const
      BucketCount = 16;
    var
      FNames: array[0..BucketCount - 1] of TList<string>;
      FValues: array[0..BucketCount - 1] of TList<Integer>;
    class function Bucket(const AName: string): Integer; static;
    function IndexInBucket(const ABucket: Integer; const AName: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The name as the table stores it: upper-case ASCII letters, blanks cut</summary>
    class function NormalizeName(const AName: string): string; static;
    /// <summary>Adds a constant; the name is normalized (NormalizeName)</summary>
    function Add(const AName: string; const AValue: Integer): TScannerConstAddResult;
    /// <summary>The value of a constant (the name is normalized); False if it is not there</summary>
    function TryGet(const AName: string; out AValue: Integer): Boolean;
    /// <summary>How many constants are in the table</summary>
    function Count: Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TScannerConstTable }

constructor TScannerConstTable.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to BucketCount - 1 do
  begin
    FNames[LIndex] := TList<string>.Create;
    FValues[LIndex] := TList<Integer>.Create;
  end;
end;

destructor TScannerConstTable.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to BucketCount - 1 do
  begin
    FNames[LIndex].Free;
    FValues[LIndex].Free;
  end;
  inherited Destroy;
end;

class function TScannerConstTable.NormalizeName(const AName: string): string;
begin
  Result := TScannerStrings.UpperAscii(TScannerStrings.Trim(AName));
end;

class function TScannerConstTable.Bucket(const AName: string): Integer;
var
  LLength: Integer;
begin
  LLength := Length(AName);
  Result := (LLength + Ord(AName[1]) + Ord(AName[LLength])) and (BucketCount - 1);
end;

function TScannerConstTable.IndexInBucket(const ABucket: Integer; const AName: string): Integer;
begin
  for Result := 0 to FNames[ABucket].Count - 1 do
    if AnsiCompareText(FNames[ABucket][Result], AName) = 0 then
      Exit;
  Result := -1;
end;

function TScannerConstTable.Add(const AName: string; const AValue: Integer): TScannerConstAddResult;
var
  LName: string;
  LBucket: Integer;
begin
  LName := NormalizeName(AName);
  if LName = '' then
    Exit(carEmptyName);
  LBucket := Bucket(LName);
  if IndexInBucket(LBucket, LName) >= 0 then
    Exit(carDuplicate);
  FNames[LBucket].Add(LName);
  FValues[LBucket].Add(AValue);
  Result := carAdded;
end;

function TScannerConstTable.TryGet(const AName: string; out AValue: Integer): Boolean;
var
  LName: string;
  LBucket: Integer;
  LIndex: Integer;
begin
  AValue := 0;
  LName := NormalizeName(AName);
  if LName = '' then
    Exit(False);
  LBucket := Bucket(LName);
  LIndex := IndexInBucket(LBucket, LName);
  Result := LIndex >= 0;
  if Result then
    AValue := FValues[LBucket][LIndex];
end;

function TScannerConstTable.Count: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to BucketCount - 1 do
    Inc(Result, FNames[LIndex].Count);
end;

end.
