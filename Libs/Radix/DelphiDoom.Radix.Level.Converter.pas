{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelConverter                            }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of RX_CreateDoomLevel of radix_level.pas: a level of Radix becomes     }
{  the lumps of a map of Doom (the nodes are not built: SEGS, SSECTORS,        }
{  NODES, REJECT and BLOCKMAP are empty and the engine makes them)             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Converter;

interface

uses
  System.SysUtils,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Level.Intf, DelphiDoom.Radix.Level.DoomMap;

type
  TRadixLevelConverter = class
  strict private
    FReader: IRadixLevelReader;
    FFixSelector: IRadixLevelFixSelector;
  public
    constructor Create(const AReader: IRadixLevelReader; const AFixSelector: IRadixLevelFixSelector);
    /// <summary>
    ///   Writes the lumps of the map; false (and nothing written) when the bytes are not a level
    /// </summary>
    /// <param name="AExtraInfo">True: also the lumps with the data of Radix (RMAP, RTHINGS, RGRID, RMAPGRID, RACTION, RTRIGGER)</param>
    /// <param name="AMarkFlat">Called for each flat that a sector uses</param>
    function Convert(const AName: string; const ABytes: TBytes; const AWad: IGameWadComposer;
      AExtraInfo: Boolean; const AMarkFlat: TRadixFlatMarker): Boolean;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.Data,
  DelphiDoom.Radix.Level.Coordinates, DelphiDoom.Radix.Level.Versions;

{$Q-}
{$R-}

{ TRadixLevelConverter }

constructor TRadixLevelConverter.Create(const AReader: IRadixLevelReader;
  const AFixSelector: IRadixLevelFixSelector);
begin
  inherited Create;
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  if not Assigned(AFixSelector) then
    raise EArgumentNilException.Create('AFixSelector');
  FReader := AReader;
  FFixSelector := AFixSelector;
end;

function TRadixLevelConverter.Convert(const AName: string; const ABytes: TBytes;
  const AWad: IGameWadComposer; AExtraInfo: Boolean; const AMarkFlat: TRadixFlatMarker): Boolean;
var
  LLevel: TRadixLevelData;
  LFix: IRadixLevelFix;
  LCoordinates: TRadixLevelCoordinates;
  LMap: TRadixDoomMap;
  LPositions: TArray<TRadixSectorPosition>;
  LMapPoints: TRadixLevelMapPoints;
  LVersion: TRadixLevelVersion;
  LCrc: Cardinal;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LV1X: Integer;
  LV1Y: Integer;
  LV2X: Integer;
  LV2Y: Integer;
  LMinX: Integer;
  LMaxX: Integer;
  LMinY: Integer;
  LMaxY: Integer;
  LMapped: TArray<Boolean>;
  LWall: TRadixLevelWall;
  LStubX: Integer;
  LStubY: Integer;
  LCell: Integer;
  LPoint: TRadixLevelMapPoint;
  LGridBytes: TBytes;
  LMapPointBytes: TBytes;
  LActionBytes: TBytes;
  LTriggerBytes: TBytes;
begin
  LLevel := FReader.TryRead(AName, ABytes);
  if not Assigned(LLevel) then
    Exit(False);
  Result := True;
  try
    if Length(ABytes) > 0 then
      LCrc := TCrc32.Calculate(ABytes[0], Length(ABytes))
    else
      LCrc := 0;
    LLevel.Crc := LCrc;
    LVersion := TRadixLevelVersions.Identify(AName, LCrc);
    LFix := FFixSelector.Select(AName, LCrc);
    LCoordinates := TRadixLevelCoordinates.Create((LVersion = rlvV2) and (AName = 'E3M2'));
    try
      // the position of every sector, and of every wall, in the Doom map
      SetLength(LPositions, Length(LLevel.Sectors));
      for LIndex := 0 to High(LPositions) do
      begin
        LPositions[LIndex].XMul := RADIX_MAP_X_MULT;
        LPositions[LIndex].XAdd := RADIX_MAP_X_ADD;
        LPositions[LIndex].YMul := RADIX_MAP_Y_MULT;
        LPositions[LIndex].YAdd := RADIX_MAP_Y_ADD;
      end;
      for LIndex := 0 to High(LLevel.Walls) do
      begin
        LWall := LLevel.Walls[LIndex];
        LV1X := LWall.V1X;
        LV1Y := LWall.V1Y;
        LV2X := LWall.V2X;
        LV2Y := LWall.V2Y;
        if LCoordinates.SplitMap and (LWall.V1X > E3M2_SPLIT_X) and (LWall.V2X > E3M2_SPLIT_X) then
        begin
          LCoordinates.Convert(LV1X, LV1Y);
          LCoordinates.Convert(LV2X, LV2Y);
          if LWall.FrontSector >= 0 then
          begin
            LPositions[LWall.FrontSector].XAdd := RADIX_MAP_X_ADD2;
            LPositions[LWall.FrontSector].YAdd := RADIX_MAP_Y_ADD2;
          end;
          if LWall.BackSector >= 0 then
          begin
            LPositions[LWall.BackSector].XAdd := RADIX_MAP_X_ADD2;
            LPositions[LWall.BackSector].YAdd := RADIX_MAP_Y_ADD2;
          end;
        end
        else
        begin
          TRadixLevelCoordinates.ConvertDefault(LV1X, LV1Y);
          TRadixLevelCoordinates.ConvertDefault(LV2X, LV2Y);
        end;
        LLevel.Walls[LIndex].V1X := LV1X;
        LLevel.Walls[LIndex].V1Y := LV1Y;
        LLevel.Walls[LIndex].V2X := LV2X;
        LLevel.Walls[LIndex].V2Y := LV2Y;
      end;

      // where each cell of the grid is in the Doom map (after the grid was read)
      LCell := 0;
      for LY := 0 to LLevel.GridHeight - 1 do
        for LX := 0 to LLevel.GridWidth - 1 do
        begin
          LV1X := LX * RADIX_GRID_CELL_SIZE;
          LV1Y := LY * RADIX_GRID_CELL_SIZE;
          LCoordinates.Convert(LV1X, LV1Y);
          LPoint.X := SmallInt(LV1X);
          LPoint.Y := SmallInt(LV1Y);
          LMapPoints[LCell] := LPoint;
          Inc(LCell);
        end;

      LFix.FixRadix(LLevel);

      LMap := TRadixDoomMap.Create(LLevel, LCoordinates, LPositions, AMarkFlat);
      try
        LMap.AddPlayerStarts;
        for LIndex := 0 to High(LLevel.Sectors) do
          LMap.AddSector(LLevel.Sectors[LIndex]);
        for LIndex := 0 to High(LLevel.Walls) do
          LMap.AddWall(LLevel.Walls[LIndex]);
        LMap.AddRadixThings;

        // the bounding box of the map
        LMinX := 100000;
        LMaxX := -100000;
        LMinY := 100000;
        LMaxY := -100000;
        for LIndex := 0 to LMap.Vertexes.Count - 1 do
        begin
          if LMap.Vertexes[LIndex].X > LMaxX then
            LMaxX := LMap.Vertexes[LIndex].X;
          if LMap.Vertexes[LIndex].X < LMinX then
            LMinX := LMap.Vertexes[LIndex].X;
          if LMap.Vertexes[LIndex].Y > LMaxY then
            LMaxY := LMap.Vertexes[LIndex].Y;
          if LMap.Vertexes[LIndex].Y < LMinY then
            LMinY := LMap.Vertexes[LIndex].Y;
        end;

        LFix.FixDoom(LMap, LLevel);

        // a sector that no side uses gets a stub wall, to be a sector of the map
        SetLength(LMapped, LMap.Sectors.Count);
        for LIndex := 0 to LMap.SideDefs.Count - 1 do
          LMapped[LMap.SideDefs[LIndex].Sector] := True;
        FillChar(LWall, SizeOf(LWall), 0);
        LWall.BackSector := -1;
        LWall.Flags := RWF_SINGLESIDED or RWF_STUBWALL;
        LWall.FloorTexture := 1;
        for LIndex := 0 to LMap.Sectors.Count - 1 do
          if not LMapped[LIndex] then
          begin
            LWall.FrontSector := LIndex;
            LWall.V1X := LMinX + LIndex * 16 + 8;
            LWall.V1Y := LMaxY + 128;
            LWall.V2X := LMinX + LIndex * 16;
            LWall.V2Y := LMaxY + 136;
            LMap.AddWall(LWall);
            LWall.V1X := LMinX + LIndex * 16;
            LWall.V1Y := LMaxY + 136;
            LWall.V2X := LMinX + LIndex * 16 + 8;
            LWall.V2Y := LMaxY + 144;
            LMap.AddWall(LWall);
            LWall.V1X := LMinX + LIndex * 16 + 8;
            LWall.V1Y := LMaxY + 144;
            LWall.V2X := LMinX + LIndex * 16 + 8;
            LWall.V2Y := LMaxY + 128;
            LMap.AddWall(LWall);
          end;

        // the lines without sides are moved out of the map
        LStubX := LMinX + 64;
        LStubY := LMaxY + 256;
        for LIndex := 0 to LMap.LineDefs.Count - 1 do
          if (LMap.LineDefs[LIndex].SideNum[0] < 0) and (LMap.LineDefs[LIndex].SideNum[1] < 0) then
          begin
            LMap.LineDefs[LIndex].V1 := SmallInt(LMap.AddVertex(LStubX, LStubY));
            LMap.LineDefs[LIndex].V2 := SmallInt(LMap.AddVertex(LStubX + 32, LStubY));
            LMap.LineDefs[LIndex].Flags := LMap.LineDefs[LIndex].Flags or ML_AUTOMAPIGNOGE;
            LStubX := LStubX + 32;
          end;

        AWad.AddMarker(AName);
        AWad.AddLump('THINGS', LMap.Things.ToBytes);
        AWad.AddLump('LINEDEFS', LMap.LineDefs.ToBytes);
        AWad.AddLump('SIDEDEFS', LMap.SideDefs.ToBytes);
        AWad.AddLump('VERTEXES', LMap.Vertexes.ToBytes);
        AWad.AddMarker('SEGS');
        AWad.AddMarker('SSECTORS');
        AWad.AddMarker('NODES');
        AWad.AddLump('SECTORS', LMap.Sectors.ToBytes);
        AWad.AddMarker('REJECT');
        AWad.AddMarker('BLOCKMAP');
        if AExtraInfo then
        begin
          SetLength(LGridBytes, SizeOf(TRadixLevelGrid));
          Move(LLevel.TriggerGrid, LGridBytes[0], SizeOf(TRadixLevelGrid));
          SetLength(LMapPointBytes, SizeOf(TRadixLevelMapPoints));
          Move(LMapPoints, LMapPointBytes[0], SizeOf(TRadixLevelMapPoints));
          AWad.AddText('RMAP', LMap.ScriptText);
          AWad.AddLump('RTHINGS', LMap.ThingExtras.ToBytes);
          AWad.AddLump('RGRID', LGridBytes);
          AWad.AddLump('RMAPGRID', LMapPointBytes);
          SetLength(LActionBytes, Length(LLevel.Actions) * SizeOf(TRadixLevelAction));
          if Length(LActionBytes) > 0 then
            Move(LLevel.Actions[0], LActionBytes[0], Length(LActionBytes));
          SetLength(LTriggerBytes, Length(LLevel.Triggers) * SizeOf(TRadixLevelTrigger));
          if Length(LTriggerBytes) > 0 then
            Move(LLevel.Triggers[0], LTriggerBytes[0], Length(LTriggerBytes));
          AWad.AddLump('RACTION', LActionBytes);
          AWad.AddLump('RTRIGGER', LTriggerBytes);
        end;
      finally
        LMap.Free;
      end;
    finally
      LCoordinates.Free;
    end;
  finally
    LLevel.Free;
  end;
end;

end.
