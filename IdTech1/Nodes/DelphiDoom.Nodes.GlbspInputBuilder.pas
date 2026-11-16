{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the WAD that the node builder reads             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.GlbspInputBuilder;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   Writes the lumps of one map in a WAD of its own, for glBSP. The game decides how the map is
  ///   read: in Hexen the lumps are copied as they are; in the other games a map with a BEHAVIOR
  ///   lump gets its THINGS and LINEDEFS in the Hexen format (the builder is told the map is a
  ///   Hexen one)
  /// </summary>
  TNodesGlbspInputBuilder = class(TInterfacedObject, INodesGlbspInputBuilder)
  strict private
    FSource: INodesLumpSource;
    FHexen: Boolean;
    function LumpOrEmpty(AMapLabel, AOffset: Integer): TBytes;
  public
    /// <param name="AHexen">True for the Hexen engine: its maps are already in the Hexen format</param>
    constructor Create(const ASource: INodesLumpSource; AHexen: Boolean);
    function BuildForMap(AMapLabel: Integer): TBytes;
    function BuildForMapWithoutNodes(AMapLabel: Integer; const ALayout: TNodesMapLayout): TBytes;
  end;

implementation

uses
  DelphiDoom.Nodes.PwadAssembler, DelphiDoom.Nodes.HexenConverter;

const
  LUMPS_OF_A_MAP = 11;
  LUMPS_OF_A_HEXEN_MAP = 12;

{ TNodesGlbspInputBuilder }

constructor TNodesGlbspInputBuilder.Create(const ASource: INodesLumpSource; AHexen: Boolean);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FHexen := AHexen;
end;

function TNodesGlbspInputBuilder.LumpOrEmpty(AMapLabel, AOffset: Integer): TBytes;
begin
  // an offset <= 0 is a lump that the map does not have
  if AOffset > 0 then
    Result := FSource.ReadLump(AMapLabel + AOffset)
  else
    Result := nil;
end;

function TNodesGlbspInputBuilder.BuildForMap(AMapLabel: Integer): TBytes;
var
  LAssembler: TNodesPwadAssembler;
  LHasBehavior: Boolean;
  LLumpsToCopy: Integer;
  LEntries: Integer;
  LIndex: Integer;
  LLump: Integer;
  LData: TBytes;
begin
  LHasBehavior := (AMapLabel + NODES_MAP_BEHAVIOR >= 0) and
    (AMapLabel + NODES_MAP_BEHAVIOR < FSource.LumpCount) and
    SameText(FSource.LumpName(AMapLabel + NODES_MAP_BEHAVIOR), 'BEHAVIOR');
  if LHasBehavior then
    LLumpsToCopy := LUMPS_OF_A_HEXEN_MAP
  else
    LLumpsToCopy := LUMPS_OF_A_MAP;
  if FHexen then
    LEntries := LUMPS_OF_A_HEXEN_MAP
  else
    LEntries := LLumpsToCopy;

  LAssembler := TNodesPwadAssembler.Create;
  try
    for LIndex := 0 to LLumpsToCopy - 1 do
    begin
      LLump := AMapLabel + LIndex;
      if LLump >= FSource.LumpCount then
        Break;
      LData := FSource.ReadLump(LLump);
      if (not FHexen) and LHasBehavior then
      begin
        if LIndex = NODES_MAP_THINGS then
          LData := TNodesHexenConverter.ConvertThings(LData)
        else if LIndex = NODES_MAP_LINEDEFS then
          LData := TNodesHexenConverter.ConvertLinedefs(LData);
      end;
      LAssembler.AddLump(FSource.LumpName(LLump), LData);
    end;

    if FHexen and (not LHasBehavior) then
    begin
      // Hexen wants twelve lumps: the last is BEHAVIOR, absent
      while LAssembler.EntryCount < LEntries - 1 do
        LAssembler.AddBlankEntry;
      LAssembler.AddAbsentLump('BEHAVIOR');
    end
    else
      while LAssembler.EntryCount < LEntries do
        LAssembler.AddBlankEntry;
    Result := LAssembler.Build;
  finally
    LAssembler.Free;
  end;
end;

function TNodesGlbspInputBuilder.BuildForMapWithoutNodes(AMapLabel: Integer;
  const ALayout: TNodesMapLayout): TBytes;
var
  LAssembler: TNodesPwadAssembler;
begin
  LAssembler := TNodesPwadAssembler.Create;
  try
    LAssembler.AddEmptyLump(UpperCase(FSource.LumpName(AMapLabel)));
    LAssembler.AddLump('THINGS', LumpOrEmpty(AMapLabel, ALayout.Things));
    LAssembler.AddLump('LINEDEFS', LumpOrEmpty(AMapLabel, ALayout.Linedefs));
    LAssembler.AddLump('SIDEDEFS', LumpOrEmpty(AMapLabel, ALayout.Sidedefs));
    LAssembler.AddLump('VERTEXES', LumpOrEmpty(AMapLabel, ALayout.Vertexes));
    // what the node builder writes
    LAssembler.AddEmptyLump('SEGS');
    LAssembler.AddEmptyLump('SSECTORS');
    LAssembler.AddEmptyLump('NODES');
    LAssembler.AddLump('SECTORS', LumpOrEmpty(AMapLabel, ALayout.Sectors));
    LAssembler.AddEmptyLump('REJECT');
    LAssembler.AddEmptyLump('BLOCKMAP');
    if FHexen then
      LAssembler.AddLump('BEHAVIOR', LumpOrEmpty(AMapLabel, ALayout.Behavior));
    Result := LAssembler.Build;
  finally
    LAssembler.Free;
  end;
end;

end.
