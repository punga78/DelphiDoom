{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the hash table of the names of the variables      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is THashTable of psi_globals.pas as a class of its own. The hash wraps   }
{  around on purpose (overflow checks are off).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Variables.HashTable;

{$Q-}
{$R-}

interface

uses
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Variables.Types;

type
  /// <summary>
  ///   Finds the position of a name in a list of strings without reading the list: the names
  ///   are in chains by hash, and the last positions found are tried first (the same few
  ///   variables are read over and over)
  /// </summary>
  TScriptHashTable = class(TObject)
  strict private
    FPositions: array[0..SCRIPT_VARIABLES_HASH_SIZE - 1] of TList<Integer>;
    FList: TStringList;
    FLastSearches: array[0..SCRIPT_VARIABLES_LAST_SEARCHES - 1] of Integer;
    FLastSearchCount: Integer;
    procedure RememberSearch(const APosition: Integer);
  public
    /// <summary>The hash of a name: from 0 to SCRIPT_VARIABLES_HASH_SIZE - 1</summary>
    class function HashOf(const AName: string): Integer; static;
    constructor Create;
    destructor Destroy; override;
    /// <summary>Forgets the chains and indexes the list: from then on the table is about that list</summary>
    procedure AssignStringList(const AList: TStringList);
    /// <summary>The string of the position has just been added to the list</summary>
    procedure Insert(const AName: string; const APosition: Integer);
    /// <summary>Forgets the chains (the last positions found stay: they are checked against the list)</summary>
    procedure Clear;
    /// <summary>The position of the name in the list (case sensitive), -1 if it is not there</summary>
    function CheckPos(const AName: string): Integer;
    property List: TStringList read FList;
  end;

implementation

{ TScriptHashTable }

class function TScriptHashTable.HashOf(const AName: string): Integer;
var
  LIndex: Integer;
  LLength: Integer;
begin
  LLength := Length(AName);
  if LLength = 0 then
    Exit(0);

  // the low byte of each character, as the first version of the engine
  Result := 5381 * 33 + (Ord(AName[1]) and $FF);
  for LIndex := 2 to LLength do
    Result := Result * 33 + (Ord(AName[LIndex]) and $FF);
  Result := Result and (SCRIPT_VARIABLES_HASH_SIZE - 1);
end;

constructor TScriptHashTable.Create;
begin
  inherited Create;
  FList := nil;
  FLastSearchCount := 0;
  FillChar(FPositions, SizeOf(FPositions), 0);
end;

destructor TScriptHashTable.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to SCRIPT_VARIABLES_HASH_SIZE - 1 do
    FPositions[LIndex].Free;
  inherited Destroy;
end;

procedure TScriptHashTable.RememberSearch(const APosition: Integer);
var
  LIndex: Integer;
begin
  if FLastSearchCount >= SCRIPT_VARIABLES_LAST_SEARCHES then
  begin
    for LIndex := 1 to FLastSearchCount - 1 do
      FLastSearches[LIndex - 1] := FLastSearches[LIndex];
    FLastSearches[FLastSearchCount - 1] := APosition;
  end
  else
  begin
    FLastSearches[FLastSearchCount] := APosition;
    Inc(FLastSearchCount);
  end;
end;

procedure TScriptHashTable.Insert(const AName: string; const APosition: Integer);
var
  LHash: Integer;
begin
  if not Assigned(FList) then
    Exit;

  LHash := HashOf(AName);
  if not Assigned(FPositions[LHash]) then
    FPositions[LHash] := TList<Integer>.Create;
  FPositions[LHash].Add(APosition);
end;

procedure TScriptHashTable.AssignStringList(const AList: TStringList);
var
  LIndex: Integer;
begin
  Clear;
  FList := AList;
  for LIndex := 0 to FList.Count - 1 do
    Insert(FList[LIndex], LIndex);
end;

procedure TScriptHashTable.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to SCRIPT_VARIABLES_HASH_SIZE - 1 do
    if Assigned(FPositions[LIndex]) then
      FPositions[LIndex].Clear;
end;

function TScriptHashTable.CheckPos(const AName: string): Integer;
var
  LIndex: Integer;
  LPosition: Integer;
  LChain: TList<Integer>;
begin
  for LIndex := FLastSearchCount - 1 downto 0 do
  begin
    LPosition := FLastSearches[LIndex];
    if (LPosition > -1) and (LPosition < FList.Count) then
      if FList[LPosition] = AName then
        Exit(LPosition);
  end;

  LChain := FPositions[HashOf(AName)];
  if not Assigned(LChain) then
    Exit(-1);

  for LIndex := 0 to LChain.Count - 1 do
  begin
    LPosition := LChain[LIndex];
    if (LPosition > -1) and (LPosition < FList.Count) then
      if FList[LPosition] = AName then
      begin
        RememberSearch(LPosition);
        Exit(LPosition);
      end;
  end;

  Result := -1;
end;

end.
