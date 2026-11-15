{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the hash table of texts (SDBM)              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.StringHashTable;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf;

const
  /// <summary>Places of the table</summary>
  STRING_HASH_SIZE = $10000;

type
  /// <summary>
  ///   The SDBM hash of the old m_hash with its table, as an object (the old one was a global).
  ///   The hash reads the characters of the string as they are (16 bit), as the old one did.
  /// </summary>
  TStringHashTable = class(TInterfacedObject, IStringHashTable)
  private
    FTable: array[0..STRING_HASH_SIZE - 1] of Integer;
  public
    constructor Create;
    /// <summary>The place of a text: SDBM hash and (size - 1)</summary>
    class function Hash(const AText: string): Cardinal; static;
    function IndexOf(const AText: string): Integer;
    procedure Update(const AText: string; const AIndex: Integer);
  end;

implementation

{ TStringHashTable }

constructor TStringHashTable.Create;
begin
  inherited Create;
  FillChar(FTable, SizeOf(FTable), 0);
end;

class function TStringHashTable.Hash(const AText: string): Cardinal;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AText) do
    Result := Ord(AText[LIndex]) + (Result shl 6) + (Result shl 16) - Result;
  Result := Result and (STRING_HASH_SIZE - 1);
end;

function TStringHashTable.IndexOf(const AText: string): Integer;
begin
  Result := FTable[Hash(AText)];
end;

procedure TStringHashTable.Update(const AText: string; const AIndex: Integer);
begin
  FTable[Hash(AText)] := AIndex;
end;

end.
