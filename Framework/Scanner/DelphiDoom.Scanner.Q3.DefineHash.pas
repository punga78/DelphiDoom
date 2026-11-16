{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3DefineHash, the hash table of the defines  }
{  of a source of Quake III Arena                                              }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_precomp.c (PC_NameHash, PC_AddDefineToHash, PC_FindHashedDefine).         }
{  Copyright (C) 1999-2005 Id Software, Inc. Licensed under the GNU General    }
{  Public License, version 2 or later.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.DefineHash;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Scanner.Q3.Define;

type
  /// <summary>1024 chains of defines; a new define goes at the head of its chain. It owns the defines</summary>
  TQ3DefineHash = class sealed
  public
    const
      HashSize = 1024;
  strict private
    FBuckets: array[0..HashSize - 1] of TQ3Define;
  public
    destructor Destroy; override;
    /// <summary>PC_NameHash</summary>
    class function NameHash(const AName: AnsiString): Integer; static;
    /// <summary>PC_AddDefineToHash</summary>
    procedure Add(const ADefine: TQ3Define);
    /// <summary>PC_FindHashedDefine: nil if there is no define with the name</summary>
    function Find(const AName: AnsiString): TQ3Define;
    /// <summary>Takes the define out of its chain (the caller frees it)</summary>
    procedure Unlink(const ADefine: TQ3Define);
    /// <summary>
    ///   The head of the first chain that is not empty (what PC_DefineFromString takes as "the" define it
    ///   has just made)
    /// </summary>
    function FirstDefine: TQ3Define;
  end;

implementation

{ TQ3DefineHash }

function ShiftRight(const AValue, ACount: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := not ((not AValue) shr ACount);
end;

destructor TQ3DefineHash.Destroy;
var
  LIndex: Integer;
  LDefine: TQ3Define;
begin
  for LIndex := 0 to HashSize - 1 do
    while FBuckets[LIndex] <> nil do
    begin
      LDefine := FBuckets[LIndex];
      FBuckets[LIndex] := LDefine.HashNext;
      LDefine.Free;
    end;
  inherited;
end;

class function TQ3DefineHash.NameHash(const AName: AnsiString): Integer;
var
  LIndex: Integer;
  LHash: Integer;
begin
  LHash := 0;
  for LIndex := 1 to Length(AName) do
    LHash := LHash + ShortInt(Ord(AName[LIndex])) * (119 + LIndex - 1);
  // hash >> 10 and hash >> 20 of a signed int are arithmetic shifts
  Result := (LHash xor ShiftRight(LHash, 10) xor ShiftRight(LHash, 20)) and (HashSize - 1);
end;

procedure TQ3DefineHash.Add(const ADefine: TQ3Define);
var
  LHash: Integer;
begin
  LHash := NameHash(ADefine.Name);
  ADefine.HashNext := FBuckets[LHash];
  FBuckets[LHash] := ADefine;
end;

function TQ3DefineHash.Find(const AName: AnsiString): TQ3Define;
begin
  Result := FBuckets[NameHash(AName)];
  while Result <> nil do
  begin
    if Result.Name = AName then
      Exit;
    Result := Result.HashNext;
  end;
end;

procedure TQ3DefineHash.Unlink(const ADefine: TQ3Define);
var
  LHash: Integer;
  LDefine: TQ3Define;
  LLast: TQ3Define;
begin
  LHash := NameHash(ADefine.Name);
  LLast := nil;
  LDefine := FBuckets[LHash];
  while LDefine <> nil do
  begin
    if LDefine = ADefine then
    begin
      if LLast <> nil then
        LLast.HashNext := LDefine.HashNext
      else
        FBuckets[LHash] := LDefine.HashNext;
      LDefine.HashNext := nil;
      Exit;
    end;
    LLast := LDefine;
    LDefine := LDefine.HashNext;
  end;
end;

function TQ3DefineHash.FirstDefine: TQ3Define;
var
  LIndex: Integer;
begin
  for LIndex := 0 to HashSize - 1 do
    if FBuckets[LIndex] <> nil then
      Exit(FBuckets[LIndex]);
  Result := nil;
end;

end.
