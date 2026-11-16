{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLumpAliases                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_alias.pas (RX_ParseAlias, RX_FindAliasLump): the names of     }
{  RADIX.DAT ("MainMenuButton1") brought to the lumps of the translated WAD    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.LumpAliases;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Radix.Intf;

type
  /// <summary>
  ///   The table of RADIXINF: every line is "LUMP=name in RADIX.DAT". The game asks for a
  ///   picture with the name it has in RADIX.DAT and gets the name of the lump of the WAD.
  ///   Names are compared without case. When a name is given twice the old code kept the last
  ///   line of the first text that was read: the same is done here
  /// </summary>
  TRadixLumpAliases = class(TInterfacedObject, IRadixLumpAliases)
  strict private
    FLumps: TDictionary<string, string>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddText(const AText: string; const AExists: TRadixLumpExists);
    function TryResolve(const ARadixName: string; out ALumpName: string): Boolean;
    property Count: Integer read GetCount;
  end;

implementation

uses
  System.Classes;

const
  SEPARATOR = '=';

{ TRadixLumpAliases }

constructor TRadixLumpAliases.Create;
begin
  inherited Create;
  FLumps := TDictionary<string, string>.Create;
end;

destructor TRadixLumpAliases.Destroy;
begin
  FLumps.Free;
  inherited Destroy;
end;

function TRadixLumpAliases.GetCount: Integer;
begin
  Result := FLumps.Count;
end;

procedure TRadixLumpAliases.AddText(const AText: string; const AExists: TRadixLumpExists);
var
  LLines: TStringList;
  LIndex: Integer;
  LSeparator: Integer;
  LLump: string;
  LName: string;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    // from the last line to the first, and the first name found is kept: the last line wins
    for LIndex := LLines.Count - 1 downto 0 do
    begin
      LSeparator := Pos(SEPARATOR, LLines[LIndex]);
      if LSeparator = 0 then
        Continue;
      LLump := Trim(Copy(LLines[LIndex], 1, LSeparator - 1));
      LName := UpperCase(Trim(Copy(LLines[LIndex], LSeparator + 1, MaxInt)));
      if (LLump = '') or (LName = '') or FLumps.ContainsKey(LName) then
        Continue;
      if Assigned(AExists) and not AExists(LLump) then
        Continue;
      FLumps.Add(LName, LLump);
    end;
  finally
    LLines.Free;
  end;
end;

function TRadixLumpAliases.TryResolve(const ARadixName: string; out ALumpName: string): Boolean;
begin
  Result := FLumps.TryGetValue(UpperCase(Trim(ARadixName)), ALumpName);
end;

end.
