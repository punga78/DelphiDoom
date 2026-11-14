{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the scenarios of the path finding    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PathScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Map.PathGrid;

type
  /// <summary>
  ///   The scenarios `war_model_ref paths` and `war_model_ref rvo` (Tools\Verifica\194\war_path_ref.inc) written again:
  ///   the same synthetic maps (noise, rectangles, rooms with doors, an open field, a closed ring, a strip with a gap),
  ///   the same LCG of the seed and the same draws in the same order, the same text. The functions that the C runs are the
  ///   original ones; here they are TWarAStar, TWarFlowFields, TWarFlowField.Sample and TWarRvo
  /// </summary>
  TPathScenario = class
  strict private
    function RvoNumber(ARange: Integer): Single;
    procedure PathPoint(ARingX, ARingY: Integer; out AX, AY: Integer);
    function BuildGrid(ASeed: Cardinal; out ARingX, ARingY: Integer): TWarPathGrid;
  public
    /// <summary>The LCG of the script (the C's gScriptState): the movement scenarios go on drawing from it</summary>
    FState: Cardinal;
    /// <summary>scriptBelow: the next number of the LCG below ALimit (0 if the limit is 0)</summary>
    function Below(ALimit: Cardinal): Integer;
    /// <summary>pathPassable: the passable map of a kind (kind mod 6), from the numbers of the script</summary>
    procedure Passable(AKind: Cardinal; var APassable: TArray<Word>; out ARingX, ARingY: Integer);
    /// <summary>The lines of one scenario of `paths` (20 A star searches and 6 flow fields)</summary>
    class procedure RunPaths(ASeed: Cardinal; ALines: TStrings); static;
    /// <summary>The map of the scenario of the seed (the tests of the flow fields use the same maps)</summary>
    class function MapOf(ASeed: Cardinal; out ARingX, ARingY: Integer): TWarPathGrid; static;
    /// <summary>
    ///   The lines of one level of `levelpaths` (runLevelPaths of war_levels_ref.inc): the passable map of the level AIndex
    ///   of DATA.WAR (4096 words), 8 A star searches and 3 flow fields between points drawn from the index of the level
    /// </summary>
    class procedure RunLevel(AIndex: Integer; const APassable: TArray<Word>; ALines: TStrings); static;
    /// <summary>The lines of one scenario of `rvo` (120 choices of velocity)</summary>
    class procedure RunRvo(ASeed: Cardinal; ALines: TStrings); static;
    /// <summary>The first lines of `rvo`: the 32 candidates of the rings as bits and the constants</summary>
    class procedure RvoTables(ALines: TStrings); static;
  end;

const
  PATH_ASTARS = 20;
  PATH_FIELDS = 6;
  PATH_SAMPLES = 4;
  RVO_CASES = 120;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Path.Types, DelphiDoom.War.Path.AStar,
  DelphiDoom.War.Path.FlowField, DelphiDoom.War.Path.FlowFields, DelphiDoom.War.Model.Rvo;

{$Q-}
{$R-}

function FBits(AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

function H8(AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

{ TPathScenario }

function TPathScenario.Below(ALimit: Cardinal): Integer;
begin
  Result := 0;
  if ALimit <> 0 then
  begin
    FState := FState * 1664525 + 1013904223;
    Result := Integer((FState shr 8) mod ALimit);
  end;
end;

function TPathScenario.RvoNumber(ARange: Integer): Single;
var
  LDraw: Integer;
begin
  LDraw := Below(Cardinal(2 * ARange * 16 + 1));
  Result := (LDraw - ARange * 16) / 16.0;
end;

procedure TPathScenario.Passable(AKind: Cardinal; var APassable: TArray<Word>; out ARingX, ARingY: Integer);
var
  LIndex: Integer;
  LDensity: Cardinal;
  LCount: Integer;
  LRect: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LX: Integer;
  LY: Integer;
  LXX: Integer;
  LYY: Integer;
  LK: Integer;
  LDoorV: Integer;
  LDoorH: Integer;
  LRadius: Integer;
  LGap: Integer;
begin
  SetLength(APassable, WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT);
  FillChar(APassable[0], Length(APassable) * SizeOf(Word), 0);
  ARingX := -1;
  ARingY := -1;
  case AKind mod 6 of
    0:
      begin
        LDensity := 4 + Cardinal(Below(36));
        for LIndex := 0 to Length(APassable) - 1 do
          if Cardinal(Below(100)) < LDensity then
            if Below(2) <> 0 then
              APassable[LIndex] := 128
            else
              APassable[LIndex] := 64;
      end;
    1:
      begin
        LCount := 4 + Below(8);
        for LRect := 0 to LCount - 1 do
        begin
          LWidth := 1 + Below(14);
          LHeight := 1 + Below(14);
          LX := Below(WAR_MAP_TILES_WIDTH);
          LY := Below(WAR_MAP_TILES_HEIGHT);
          LYY := LY;
          while (LYY < LY + LHeight) and (LYY < WAR_MAP_TILES_HEIGHT) do
          begin
            LXX := LX;
            while (LXX < LX + LWidth) and (LXX < WAR_MAP_TILES_WIDTH) do
            begin
              APassable[LYY * WAR_MAP_TILES_WIDTH + LXX] := 128;
              Inc(LXX);
            end;
            Inc(LYY);
          end;
        end;
      end;
    2:
      begin
        LK := 16;
        while LK < WAR_MAP_TILES_WIDTH do
        begin
          LDoorV := Below(WAR_MAP_TILES_HEIGHT - 3);
          LDoorH := Below(WAR_MAP_TILES_WIDTH - 3);
          for LIndex := 0 to WAR_MAP_TILES_WIDTH - 1 do
          begin
            if (LIndex < LDoorV) or (LIndex >= LDoorV + 3) then
              APassable[LIndex * WAR_MAP_TILES_WIDTH + LK] := 128;
            if (LIndex < LDoorH) or (LIndex >= LDoorH + 3) then
              APassable[LK * WAR_MAP_TILES_WIDTH + LIndex] := 64;
          end;
          Inc(LK, 16);
        end;
      end;
    3:
      ;
    4:
      begin
        for LIndex := 0 to Length(APassable) - 1 do
          if Below(100) < 6 then
            APassable[LIndex] := 128;
        ARingX := 8 + Below(WAR_MAP_TILES_WIDTH - 16);
        ARingY := 8 + Below(WAR_MAP_TILES_HEIGHT - 16);
        LRadius := 2 + Below(4);
        for LY := ARingY - LRadius to ARingY + LRadius do
          for LX := ARingX - LRadius to ARingX + LRadius do
            if (LX = ARingX - LRadius) or (LX = ARingX + LRadius) or (LY = ARingY - LRadius) or
              (LY = ARingY + LRadius) then
              APassable[LY * WAR_MAP_TILES_WIDTH + LX] := 128;
      end;
  else
    begin
      LY := 20 + Below(24);
      LGap := Below(WAR_MAP_TILES_WIDTH);
      for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
        if LX <> LGap then
          APassable[LY * WAR_MAP_TILES_WIDTH + LX] := 128;
    end;
  end;
end;

procedure TPathScenario.PathPoint(ARingX, ARingY: Integer; out AX, AY: Integer);
begin
  if (ARingX >= 0) and (Below(3) = 0) then
  begin
    AX := ARingX + Below(3) - 1;
    AY := ARingY + Below(3) - 1;
    Exit;
  end;
  AX := Below(WAR_MAP_TILES_WIDTH);
  AY := Below(WAR_MAP_TILES_HEIGHT);
end;

function TPathScenario.BuildGrid(ASeed: Cardinal; out ARingX, ARingY: Integer): TWarPathGrid;
var
  LPassable: TArray<Word>;
  LBlocks: Integer;
  LBlock: Integer;
  LX: Integer;
  LY: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LId: Integer;
begin
  FState := ASeed * 2654435761 + 5150;
  Passable(ASeed, LPassable, ARingX, ARingY);
  Result := TWarPathGrid.Create(LPassable);
  // some rectangles taken by a static entity (a building, a unit that stands)
  LBlocks := Below(4);
  for LBlock := 0 to LBlocks - 1 do
  begin
    LX := Below(WAR_MAP_TILES_WIDTH);
    LY := Below(WAR_MAP_TILES_HEIGHT);
    LWidth := 1 + Below(5);
    LHeight := 1 + Below(5);
    LId := 1 + Below(1000);
    Result.SetStaticEntity(LX, LY, LWidth, LHeight, Word(LId));
  end;
end;

class function TPathScenario.MapOf(ASeed: Cardinal; out ARingX, ARingY: Integer): TWarPathGrid;
var
  LScenario: TPathScenario;
begin
  LScenario := TPathScenario.Create;
  try
    Result := LScenario.BuildGrid(ASeed, ARingX, ARingY);
  finally
    LScenario.Free;
  end;
end;

class procedure TPathScenario.RunPaths(ASeed: Cardinal; ALines: TStrings);
var
  LScenario: TPathScenario;
  LGrid: TWarPathGrid;
  LAStar: TWarAStar;
  LFields: TWarFlowFields;
  LPath: TWarMapPath;
  LRingX: Integer;
  LRingY: Integer;
  LIndex: Integer;
  LSx: Integer;
  LSy: Integer;
  LEx: Integer;
  LEy: Integer;
  LHash: Cardinal;
  LNode: Integer;
  LField: TWarFlowField;
  LGx: Integer;
  LGy: Integer;
  LHashCost: Cardinal;
  LHashDir: Cardinal;
  LReach: Integer;
  LMaxCost: Integer;
  LCell: Integer;
  LSample: Integer;
  LVector: TWarVec2;
  LLine: string;
begin
  LScenario := TPathScenario.Create;
  try
    LGrid := LScenario.BuildGrid(ASeed, LRingX, LRingY);
    try
      LAStar := TWarAStar.Create(LGrid);
      LFields := TWarFlowFields.Create(LGrid);
      try
        for LIndex := 0 to PATH_ASTARS - 1 do
        begin
          LScenario.PathPoint(LRingX, LRingY, LSx, LSy);
          LScenario.PathPoint(LRingX, LRingY, LEx, LEy);
          // one pair in eight has the end where the start is (the path of one tile)
          if LScenario.Below(8) = 0 then
          begin
            LEx := LSx;
            LEy := LSy;
          end;
          // the caller of the original clears the path first; a search that closes one tile leaves it as it was
          LPath.Count := 0;
          LAStar.FindPath(LSx, LSy, LEx, LEy, LPath);
          LHash := 2166136261;
          for LNode := 0 to LPath.Count - 1 do
          begin
            LHash := (LHash xor Cardinal(LPath.Nodes[LNode].X)) * 16777619;
            LHash := (LHash xor Cardinal(LPath.Nodes[LNode].Y)) * 16777619;
          end;
          ALines.Add(Format('A %u %d %d,%d,%d,%d n=%d h=%s', [ASeed, LIndex, LSx, LSy, LEx, LEy, LPath.Count,
            H8(LHash)]));
        end;
        for LIndex := 0 to PATH_FIELDS - 1 do
        begin
          LScenario.PathPoint(LRingX, LRingY, LGx, LGy);
          LField := LFields.Compute(LGx, LGy);
          LHashCost := 2166136261;
          LHashDir := 2166136261;
          LReach := 0;
          LMaxCost := 0;
          for LCell := 0 to WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1 do
          begin
            LHashCost := (LHashCost xor Cardinal(LField.Cost[LCell])) * 16777619;
            LHashDir := (LHashDir xor Cardinal(LField.Direction[LCell])) * 16777619;
            if LField.Direction[LCell] < WAR_FLOW_NO_DIRECTION then
            begin
              Inc(LReach);
              if LField.Cost[LCell] > LMaxCost then
                LMaxCost := LField.Cost[LCell];
            end;
          end;
          LLine := Format('F %u %d %d,%d reach=%d max=%d c=%s d=%s s=', [ASeed, LIndex, LGx, LGy, LReach, LMaxCost,
            H8(LHashCost), H8(LHashDir)]);
          for LSample := 0 to PATH_SAMPLES - 1 do
          begin
            LSx := LScenario.Below(WAR_MAP_TILES_WIDTH);
            LSy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
            LVector := LField.Sample(LSx, LSy);
            LLine := LLine + Format('%s,%s;', [H8(FBits(LVector.X)), H8(FBits(LVector.Y))]);
          end;
          ALines.Add(LLine);
        end;
      finally
        LFields.Free;
        LAStar.Free;
      end;
    finally
      LGrid.Free;
    end;
  finally
    LScenario.Free;
  end;
end;

class procedure TPathScenario.RunLevel(AIndex: Integer; const APassable: TArray<Word>; ALines: TStrings);
var
  LScenario: TPathScenario;
  LGrid: TWarPathGrid;
  LAStar: TWarAStar;
  LFields: TWarFlowFields;
  LField: TWarFlowField;
  LPath: TWarMapPath;
  LStatics: Integer;
  LCell: Integer;
  LIndex: Integer;
  LSx: Integer;
  LSy: Integer;
  LEx: Integer;
  LEy: Integer;
  LGx: Integer;
  LGy: Integer;
  LNode: Integer;
  LHash: Cardinal;
  LHashCost: Cardinal;
  LHashDir: Cardinal;
  LReach: Integer;
  LMaxCost: Integer;
  LTiles: TArray<Word>;
begin
  LScenario := TPathScenario.Create;
  LGrid := TWarPathGrid.Create(APassable);
  try
    LScenario.FState := Cardinal(AIndex) * 2654435761 + 9090;
    LTiles := LGrid.ToArray;
    LStatics := 0;
    for LCell := 0 to High(LTiles) do
      if LTiles[LCell] <> 0 then
        Inc(LStatics);
    ALines.Add(Format('L %d statics=%d', [AIndex, LStatics]));
    LAStar := TWarAStar.Create(LGrid);
    LFields := TWarFlowFields.Create(LGrid);
    try
      for LIndex := 0 to 7 do
      begin
        LSx := LScenario.Below(WAR_MAP_TILES_WIDTH);
        LSy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
        LEx := LScenario.Below(WAR_MAP_TILES_WIDTH);
        LEy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
        LPath.Count := 0;
        LAStar.FindPath(LSx, LSy, LEx, LEy, LPath);
        LHash := 2166136261;
        for LNode := 0 to LPath.Count - 1 do
        begin
          LHash := (LHash xor Cardinal(LPath.Nodes[LNode].X)) * 16777619;
          LHash := (LHash xor Cardinal(LPath.Nodes[LNode].Y)) * 16777619;
        end;
        ALines.Add(Format('A %d %d %d,%d,%d,%d n=%d h=%s', [AIndex, LIndex, LSx, LSy, LEx, LEy, LPath.Count, H8(LHash)]));
      end;
      for LIndex := 0 to 2 do
      begin
        LGx := LScenario.Below(WAR_MAP_TILES_WIDTH);
        LGy := LScenario.Below(WAR_MAP_TILES_HEIGHT);
        LField := LFields.Compute(LGx, LGy);
        LHashCost := 2166136261;
        LHashDir := 2166136261;
        LReach := 0;
        LMaxCost := 0;
        for LCell := 0 to WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1 do
        begin
          LHashCost := (LHashCost xor Cardinal(LField.Cost[LCell])) * 16777619;
          LHashDir := (LHashDir xor Cardinal(LField.Direction[LCell])) * 16777619;
          if LField.Direction[LCell] < WAR_FLOW_NO_DIRECTION then
          begin
            Inc(LReach);
            if LField.Cost[LCell] > LMaxCost then
              LMaxCost := LField.Cost[LCell];
          end;
        end;
        ALines.Add(Format('F %d %d %d,%d reach=%d max=%d c=%s d=%s', [AIndex, LIndex, LGx, LGy, LReach, LMaxCost,
          H8(LHashCost), H8(LHashDir)]));
      end;
    finally
      LFields.Free;
      LAStar.Free;
    end;
  finally
    LGrid.Free;
    LScenario.Free;
  end;
end;

class procedure TPathScenario.RunRvo(ASeed: Cardinal; ALines: TStrings);
var
  LScenario: TPathScenario;
  LCase: Integer;
  LMaxSpeed: Single;
  LRadius: Single;
  LPosition: TWarVec2;
  LVelocity: TWarVec2;
  LPreferred: TWarVec2;
  LAx: Single;
  LAy: Single;
  LVx: Single;
  LVy: Single;
  LPx: Single;
  LPy: Single;
  LDx: Single;
  LDy: Single;
  LUx: Single;
  LUy: Single;
  LMode: Integer;
  LNeighbours: TWarRvoNeighbours;
  LNeighbour: Integer;
  LDebug: TWarRvoDebug;
  LResult: TWarVec2;
  LMask: UInt64;
  LHash: Cardinal;
  LIndex: Integer;
  LMaskText: string;
begin
  LScenario := TPathScenario.Create;
  try
    LScenario.FState := ASeed * 2654435761 + 777;
    for LCase := 0 to RVO_CASES - 1 do
    begin
      LMaxSpeed := 6 + LScenario.Below(40);
      if LScenario.Below(2) <> 0 then
        LRadius := 7.2
      else
        LRadius := 9.6;
      LAx := LScenario.RvoNumber(60);
      LAy := LScenario.RvoNumber(60);
      LPosition.X := LAx + 400.0;
      LPosition.Y := LAy + 400.0;
      LVx := LScenario.RvoNumber(20);
      LVy := LScenario.RvoNumber(20);
      LVelocity.X := LVx * 0.5;
      LVelocity.Y := LVy * 0.5;
      LMode := LScenario.Below(6);
      if LMode = 0 then
      begin
        LPreferred.X := 0;
        LPreferred.Y := 0;
      end
      else if LMode = 1 then
      begin
        LPx := LScenario.RvoNumber(2);
        LPy := LScenario.RvoNumber(2);
        LPreferred.X := LPx * 0.0625;
        LPreferred.Y := LPy * 0.0625;
      end
      else
      begin
        LPx := LScenario.RvoNumber(40);
        LPy := LScenario.RvoNumber(40);
        LPreferred.X := LPx;
        LPreferred.Y := LPy;
      end;
      LNeighbours.Count := LScenario.Below(WAR_RVO_MAX_NEIGHBOURS + 1);
      for LNeighbour := 0 to LNeighbours.Count - 1 do
      begin
        LDx := LScenario.RvoNumber(40);
        LDy := LScenario.RvoNumber(40);
        LUx := LScenario.RvoNumber(20);
        LUy := LScenario.RvoNumber(20);
        LNeighbours.Items[LNeighbour].Position.X := LPosition.X + LDx;
        LNeighbours.Items[LNeighbour].Position.Y := LPosition.Y + LDy;
        LNeighbours.Items[LNeighbour].Velocity.X := LUx;
        LNeighbours.Items[LNeighbour].Velocity.Y := LUy;
        LNeighbours.Items[LNeighbour].Radius := 7.2;
      end;
      LResult := TWarRvo.ComputeNewVelocity(LPreferred, LPosition, LVelocity, LRadius, LMaxSpeed, 1.0 / 60.0,
        LNeighbours, @LDebug);
      LMask := 0;
      LHash := 2166136261;
      for LIndex := 0 to LDebug.Count - 1 do
      begin
        if LDebug.HadCollision[LIndex] then
          LMask := LMask or (UInt64(1) shl LIndex);
        LHash := (LHash xor FBits(LDebug.Candidates[LIndex].X)) * 16777619;
        LHash := (LHash xor FBits(LDebug.Candidates[LIndex].Y)) * 16777619;
      end;
      LMaskText := LowerCase(IntToHex(LMask, 1));
      ALines.Add(Format('R %u %d n=%d best=%d r=%s,%s mask=%s h=%s', [ASeed, LCase, LNeighbours.Count,
        LDebug.BestIndex, H8(FBits(LResult.X)), H8(FBits(LResult.Y)), LMaskText, H8(LHash)]));
    end;
  finally
    LScenario.Free;
  end;
end;

class procedure TPathScenario.RvoTables(ALines: TStrings);
var
  LNone: TWarRvoNeighbours;
  LZero: TWarVec2;
  LDebug: TWarRvoDebug;
  LIndex: Integer;
begin
  LNone.Count := 0;
  LZero.X := 0;
  LZero.Y := 0;
  TWarRvo.ComputeNewVelocity(LZero, LZero, LZero, 7.2, 1.0, 1.0 / 60.0, LNone, @LDebug);
  ALines.Add('# anelli: T indice cosf sinf (bit); velocita'' massima 1');
  for LIndex := 0 to WAR_RVO_RING - 1 do
    ALines.Add(Format('T %d %s %s', [LIndex, H8(FBits(LDebug.Candidates[1 + LIndex].X)),
      H8(FBits(LDebug.Candidates[1 + LIndex].Y))]));
  ALines.Add('# costanti: K maxNeighbours ringN candidates horizon collisionW deviationW (bit)');
  ALines.Add(Format('K %d %d %d %s %s %s', [WAR_RVO_MAX_NEIGHBOURS, WAR_RVO_RING, WAR_RVO_MAX_CANDIDATES,
    H8(FBits(2.0)), H8(FBits(1.5)), H8(FBits(1.0))]));
end;

end.
