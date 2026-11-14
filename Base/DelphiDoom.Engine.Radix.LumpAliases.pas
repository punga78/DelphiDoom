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
  // The lumps that the engine of Doom asks for by name and RADIX.DAT does not have, in the format
  // of RADIXINF: the flat of the border of the view is the background of the menus of Rad-X
  // (menubackgroundflat). The sounds of Doom that the engine plays by number (doors and platforms,
  // switches, the teleport, the craft that hits something, the menus) are the sounds of
  // RADIX.DAT that Rad-X gave them (radixalias of its sound_data.pas; DS_nnnnn is the sound nnnnn
  // of the table of TRadixSoundPart); the three of the menus and of the switches, which Rad-X
  // played from its own menu, are the click of the buttons
  ENGINE_NAMES = 'RDXF0000=FLOOR7_2'#13#10 +
    'DS_00001=DSPLASMA'#13#10 +
    'DS_00004=DSRLAUNC'#13#10 +
    'DS_00005=DSRXPLOD'#13#10 +
    'DS_00002=DSPSTART'#13#10 +
    'DS_00003=DSPSTOP'#13#10 +
    'DS_00002=DSSTNMOV'#13#10 +
    'DS_00015=DSWPNUP'#13#10 +
    'DS_00025=DSOOF'#13#10 +
    'DS_00014=DSTELEPT'#13#10 +
    'DS_00000=DSPLDETH'#13#10 +
    'DS_00000=DSNOWAY'#13#10 +
    'DS_00017=DSPISTOL'#13#10 +
    'DS_00017=DSSWTCHN'#13#10 +
    'DS_00017=DSSWTCHX'#13#10 +
    // the menu of Doom leaves the game with the voice of one of its monsters (Radix has none);
    // Rad-X left with the sound of the teleport
    'DS_00014=DSDMPAIN'#13#10 +
    'DS_00014=DSPOPAIN'#13#10 +
    'DS_00014=DSPOSIT1'#13#10 +
    'DS_00014=DSPOSIT3'#13#10 +
    'DS_00014=DSSGTATK'#13#10;

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
    LTable.AddText(ENGINE_NAMES,
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
