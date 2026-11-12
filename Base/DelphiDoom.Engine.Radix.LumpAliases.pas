{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the names of RADIX.DAT as names of lumps               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Radix.LumpAliases;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Intf, DelphiDoom.Engine.Wad.Lumps.Intf, DelphiDoom.Engine.Wad.Aliases.Intf;

type
  /// <summary>
  ///   The aliases of Radix over the loaded files: the text of every lump RADIXINF goes to the
  ///   table of the library (RX_InitRadixAlias of the old fork). The lumps are read at the first
  ///   question, when the directory exists, and again after a Reset
  /// </summary>
  TEngineRadixLumpAliases = class(TInterfacedObject, IEngineLumpAliases)
  strict private
    FLumps: IEngineLumps;
    FCreateTable: TFunc<IRadixLumpAliases>;
    FTable: IRadixLumpAliases;
    FLoading: Boolean;
    procedure Load;
  public
    /// <param name="ALumps">The loaded files; EArgumentNilException when nil</param>
    /// <param name="ACreateTable">Gives an empty table; EArgumentNilException when nil</param>
    constructor Create(const ALumps: IEngineLumps; const ACreateTable: TFunc<IRadixLumpAliases>);
    function TryResolve(const AName: string; out ALumpName: string): Boolean;
    procedure Reset;
  end;

implementation

const
  ALIASES_LUMP = 'RADIXINF';

{ TEngineRadixLumpAliases }

constructor TEngineRadixLumpAliases.Create(const ALumps: IEngineLumps;
  const ACreateTable: TFunc<IRadixLumpAliases>);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(ACreateTable) then
    raise EArgumentNilException.Create('ACreateTable');
  FLumps := ALumps;
  FCreateTable := ACreateTable;
end;

procedure TEngineRadixLumpAliases.Load;
var
  LTable: IRadixLumpAliases;
  LLump: Integer;
begin
  LTable := FCreateTable();
  FLoading := True;
  try
    for LLump := 0 to FLumps.Count - 1 do
      if SameText(FLumps.NameOf(LLump), ALIASES_LUMP) then
        LTable.AddText(FLumps.TextOf(LLump),
          function(const ALumpName: string): Boolean
          begin
            Result := FLumps.CheckNumForName(ALumpName) >= 0;
          end);
  finally
    FLoading := False;
  end;
  FTable := LTable;
end;

function TEngineRadixLumpAliases.TryResolve(const AName: string; out ALumpName: string): Boolean;
begin
  ALumpName := '';
  // while the table is read the directory asks about the lumps that are missing: they have no alias
  if FLoading then
    Exit(False);
  if not Assigned(FTable) then
    Load;
  Result := FTable.TryResolve(AName, ALumpName);
end;

procedure TEngineRadixLumpAliases.Reset;
begin
  if not FLoading then
    FTable := nil;
end;

end.
