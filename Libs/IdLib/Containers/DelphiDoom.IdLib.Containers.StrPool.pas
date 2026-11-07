{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdStrPool, the pool of shared strings       }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\StrPool.h.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.StrPool;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Containers.HashIndex;

type
  TIdStrPool = class;

  /// <summary>A string of a pool with the number of its users (idPoolStr)</summary>
  TIdPoolStr = class
  private
    FText: AnsiString;
    FPool: TIdStrPool;
    FNumUsers: Integer;
  public
    property Text: AnsiString read FText;
    /// <summary>The pool this string was allocated from</summary>
    property Pool: TIdStrPool read FPool;
    property NumUsers: Integer read FNumUsers;
  end;

  /// <summary>
  ///   A pool of strings in which equal strings are stored once (idStrPool): <c>AllocString</c>
  ///   returns the string of the pool and counts a user, <c>FreeString</c> drops a user and
  ///   removes the string at zero. The pool owns its strings: a string must not be used after its
  ///   last user freed it.
  /// </summary>
  TIdStrPool = class
  private
    FCaseSensitive: Boolean;
    FPool: TObjectList<TIdPoolStr>;
    FPoolHash: TIdHashIndex;
    function GetString(const AIndex: Integer): TIdPoolStr;
    function Matches(const AIndex: Integer; const AText: AnsiString): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetCaseSensitive(const ACaseSensitive: Boolean);
    function Num: Integer;
    function Allocated: NativeInt;
    /// <summary>The string at an index of the pool</summary>
    property Strings[const AIndex: Integer]: TIdPoolStr read GetString; default;
    function AllocString(const AText: AnsiString): TIdPoolStr;
    procedure FreeString(const APoolStr: TIdPoolStr);
    /// <summary>A string of the same pool just gets another user; one of another pool is allocated here</summary>
    function CopyString(const APoolStr: TIdPoolStr): TIdPoolStr;
    procedure Clear;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Strings;

{ TIdStrPool }

constructor TIdStrPool.Create;
begin
  inherited Create;
  FCaseSensitive := True;
  FPool := TObjectList<TIdPoolStr>.Create(True);
  FPoolHash := TIdHashIndex.Create;
end;

destructor TIdStrPool.Destroy;
begin
  FPoolHash.Free;
  FPool.Free;
  inherited Destroy;
end;

procedure TIdStrPool.SetCaseSensitive(const ACaseSensitive: Boolean);
begin
  FCaseSensitive := ACaseSensitive;
end;

function TIdStrPool.Num: Integer;
begin
  Result := FPool.Count;
end;

function TIdStrPool.Allocated: NativeInt;
var
  LIndex: Integer;
begin
  Result := FPool.Count * SizeOf(Pointer) + FPoolHash.Allocated;
  for LIndex := 0 to FPool.Count - 1 do
    Inc(Result, Length(FPool[LIndex].FText));
end;

function TIdStrPool.GetString(const AIndex: Integer): TIdPoolStr;
begin
  Result := FPool[AIndex];
end;

function TIdStrPool.Matches(const AIndex: Integer; const AText: AnsiString): Boolean;
begin
  if FCaseSensitive then
    Result := TIdStrings.Cmp(FPool[AIndex].FText, AText) = 0
  else
    Result := TIdStrings.Icmp(FPool[AIndex].FText, AText) = 0;
end;

function TIdStrPool.AllocString(const AText: AnsiString): TIdPoolStr;
var
  LIndex, LHash: Integer;
begin
  LHash := FPoolHash.GenerateKey(AText, FCaseSensitive);
  LIndex := FPoolHash.First(LHash);
  while LIndex <> -1 do
  begin
    if Matches(LIndex, AText) then
    begin
      Inc(FPool[LIndex].FNumUsers);
      Exit(FPool[LIndex]);
    end;
    LIndex := FPoolHash.Next(LIndex);
  end;
  Result := TIdPoolStr.Create;
  Result.FText := AText;
  Result.FPool := Self;
  Result.FNumUsers := 1;
  FPoolHash.Add(LHash, FPool.Add(Result));
end;

procedure TIdStrPool.FreeString(const APoolStr: TIdPoolStr);
var
  LIndex, LHash: Integer;
begin
  if APoolStr.FNumUsers < 1 then
    raise EIdLibException.Create('idStrPool::FreeString: the string has no users');
  if APoolStr.FPool <> Self then
    raise EIdLibException.Create('idStrPool::FreeString: the string is from another pool');
  Dec(APoolStr.FNumUsers);
  if APoolStr.FNumUsers <= 0 then
  begin
    LHash := FPoolHash.GenerateKey(APoolStr.FText, FCaseSensitive);
    LIndex := FPoolHash.First(LHash);
    while LIndex <> -1 do
    begin
      if Matches(LIndex, APoolStr.FText) then
        Break;
      LIndex := FPoolHash.Next(LIndex);
    end;
    if LIndex = -1 then
      raise EIdLibException.Create('idStrPool::FreeString: the string is not in the pool');
    FPool.Delete(LIndex);
    FPoolHash.RemoveIndex(LHash, LIndex);
  end;
end;

function TIdStrPool.CopyString(const APoolStr: TIdPoolStr): TIdPoolStr;
begin
  if APoolStr.FNumUsers < 1 then
    raise EIdLibException.Create('idStrPool::CopyString: the string has no users');
  if APoolStr.FPool = Self then
  begin
    // the string is from this pool so just increase the user count
    Inc(APoolStr.FNumUsers);
    Result := APoolStr;
  end
  else
    // the string is from another pool so it needs to be re-allocated from this pool
    Result := AllocString(APoolStr.FText);
end;

procedure TIdStrPool.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FPool.Count - 1 do
    FPool[LIndex].FNumUsers := 0;
  FPool.Clear;
  FPoolHash.FreeMemory;
end;

end.
