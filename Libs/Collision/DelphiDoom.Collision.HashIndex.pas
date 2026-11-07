{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - hash index (idHashIndex)                    }
{                                                                              }
{  Port of the used part of idHashIndex (HashIndex.h) of Doom 3 GPL Source     }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.HashIndex;

interface

type
  /// <summary>
  ///   Index of integers by hash key: each key has a chain of the indexes added with it, the
  ///   last added first (this is the order in which idHashIndex returns them and the order
  ///   of the vertex and edge lookups of the model builder depends on it)
  /// </summary>
  TCmHashIndex = class
  private
    FHash: TArray<Integer>;
    FChain: TArray<Integer>;
    FHashMask: Integer;
  public
    /// <summary>AHashSize must be a power of two</summary>
    constructor Create(AHashSize, AIndexSize: Integer);
    procedure Clear;
    procedure Add(AKey, AIndex: Integer);
    /// <summary>First index with the key, or -1</summary>
    function First(AKey: Integer): Integer;
    /// <summary>Next index in the chain of the key, or -1</summary>
    function Next(AIndex: Integer): Integer;
    function GenerateKey(AValue: Integer): Integer; overload;
    function GenerateKey(AValue1, AValue2: Integer): Integer; overload;
  end;

implementation

{ TCmHashIndex }

constructor TCmHashIndex.Create(AHashSize, AIndexSize: Integer);
begin
  inherited Create;
  SetLength(FHash, AHashSize);
  SetLength(FChain, AIndexSize);
  FHashMask := AHashSize - 1;
  Clear;
end;

procedure TCmHashIndex.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FHash) do
    FHash[LIndex] := -1;
  for LIndex := 0 to High(FChain) do
    FChain[LIndex] := -1;
end;

procedure TCmHashIndex.Add(AKey, AIndex: Integer);
var
  LOldLength: Integer;
  LIndex: Integer;
begin
  if AIndex >= Length(FChain) then
  begin
    LOldLength := Length(FChain);
    SetLength(FChain, AIndex * 2 + 16);
    for LIndex := LOldLength to High(FChain) do
      FChain[LIndex] := -1;
  end;
  AKey := AKey and FHashMask;
  FChain[AIndex] := FHash[AKey];
  FHash[AKey] := AIndex;
end;

function TCmHashIndex.First(AKey: Integer): Integer;
begin
  Result := FHash[AKey and FHashMask];
end;

function TCmHashIndex.Next(AIndex: Integer): Integer;
begin
  Result := FChain[AIndex];
end;

function TCmHashIndex.GenerateKey(AValue: Integer): Integer;
begin
  Result := AValue and FHashMask;
end;

function TCmHashIndex.GenerateKey(AValue1, AValue2: Integer): Integer;
begin
  Result := (AValue1 + AValue2) and FHashMask;
end;

end.
