{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the list of the switches of Doom                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Definitions.SwitchListLoader;

interface

uses
  DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf,
  DelphiDoom.Engine.Definitions.Intf;

type
  /// <summary>
  ///   The switches of Doom: the lump SWITCHES of BOOM, or the table of the game, reduced to the
  ///   pairs of textures that exist in the episode, in switchlist of p_switch.pas. It was
  ///   P_InitSwitchList
  /// </summary>
  TEngineSwitchListLoader = class(TInterfacedObject, IEngineSwitchListLoader)
  strict private
    FReader: IDefSwitchLumpReader;
    FSelector: IDefSwitchSelector;
    FDefaultTable: TArray<TDefSwitchPair>;
    function Episode: Integer;
    function ReadTable: TArray<TDefSwitchPair>;
  public
    constructor Create(const AReader: IDefSwitchLumpReader; const ASelector: IDefSwitchSelector;
      const ADefaultTable: TArray<TDefSwitchPair>);
    procedure Load;
  end;

implementation

uses
  System.SysUtils,
  doomdef,
  doomstat,
  p_switch,
  w_wad,
  z_zone;

const
  SWITCHES_LUMP_NAME = 'SWITCHES';

{ TEngineSwitchListLoader }

constructor TEngineSwitchListLoader.Create(const AReader: IDefSwitchLumpReader;
  const ASelector: IDefSwitchSelector; const ADefaultTable: TArray<TDefSwitchPair>);
begin
  inherited Create;
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  if not Assigned(ASelector) then
    raise EArgumentNilException.Create('ASelector');
  FReader := AReader;
  FSelector := ASelector;
  FDefaultTable := ADefaultTable;
end;

function TEngineSwitchListLoader.Episode: Integer;
begin
  if (gamemode = registered) or (gamemode = retail) then
    Result := 2
  else if gamemode = commercial then
    Result := 3
  else
    Result := 1;
end;

function TEngineSwitchListLoader.ReadTable: TArray<TDefSwitchPair>;
var
  LLump: Integer;
  LBytes: TArray<Byte>;
begin
  // JVAL: Check for 'SWITCHES' lump (BOOM compatibility)
  LLump := W_CheckNumForName(SWITCHES_LUMP_NAME);
  if LLump < 0 then
    Exit(FDefaultTable);

  SetLength(LBytes, W_LumpLength(LLump));
  if Length(LBytes) > 0 then
    W_ReadLump(LLump, @LBytes[0]);
  Result := FReader.Read(LBytes);
end;

procedure TEngineSwitchListLoader.Load;
var
  LIndex: Integer;
  LResolved: TArray<TDefResolvedSwitch>;
begin
  // The pairs of the textures that exist, for the episode
  LResolved := FSelector.Select(ReadTable, Episode);

  // JVAL: Removed size of switchlist limit
  switchlist := Z_Malloc((Length(LResolved) * 2 + 1) * SizeOf(Integer), PU_STATIC, nil);
  for LIndex := 0 to Length(LResolved) - 1 do
  begin
    switchlist[LIndex * 2] := LResolved[LIndex].Texture1;
    switchlist[LIndex * 2 + 1] := LResolved[LIndex].Texture2;
  end;
  numswitches := Length(LResolved);
  switchlist[numswitches * 2] := -1;
end;

end.
