{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixMapInfoReader                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the parser of RX_LoadRadixMapInfo (radix_map_extra.pas): the text   }
{  of the lump RMAP, that the translation of a level writes                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.MapInfo.Reader;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.MapInfo.Types;

type
  /// <summary>
  ///   Reads the statements of RMAP ("sectorid 3 xmul 1 ... wallid 7 wallflags 2"): words and
  ///   numbers divided by blanks, without case. A statement belongs to the last sector or wall
  ///   named (the sector 0 and the wall 0 before any is named, as in the old code); a word that is
  ///   not a statement is skipped. A statement given twice keeps the last values
  /// </summary>
  TRadixMapInfoReader = class(TInterfacedObject, IRadixMapInfoReader)
  strict private
    FTokens: TArray<string>;
    FPosition: Integer;
    FSectors: TList<TRadixSectorInfo>;
    FSectorIndex: TDictionary<Integer, Integer>;
    FWalls: TList<TRadixWallInfo>;
    FWallIndex: TDictionary<Integer, Integer>;
    function NextInteger(const AStatement: string): Integer;
    function NextCardinal(const AStatement: string): Cardinal;
    function NextTriple(const AStatement: string): TRadixTriple;
    function NextPlane(const AStatement: string): TRadixPlaneEquation;
    function SectorSlot(ASectorId: Integer): Integer;
    function WallSlot(AWallId: Integer): Integer;
    procedure ReadSectorStatement(const AWord: string; ASectorId: Integer);
    procedure ReadWallStatement(const AWord: string; AWallId: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Read(const AText: string): TRadixMapInfo;
    /// <summary>A sector as it is when RMAP does not name it</summary>
    class function DefaultSector(ASectorId: Integer): TRadixSectorInfo; static;
  end;

implementation

uses
  DelphiDoom.Radix.Types;

const
  SMissingNumber = 'RMAP: the statement "%s" ends before its numbers';
  SBadNumber = 'RMAP: "%s" is not a number of the statement "%s"';

  BLANKS: array[0..3] of Char = (' ', #9, #13, #10);

{ TRadixMapInfoReader }

constructor TRadixMapInfoReader.Create;
begin
  inherited Create;
  FSectors := TList<TRadixSectorInfo>.Create;
  FSectorIndex := TDictionary<Integer, Integer>.Create;
  FWalls := TList<TRadixWallInfo>.Create;
  FWallIndex := TDictionary<Integer, Integer>.Create;
end;

destructor TRadixMapInfoReader.Destroy;
begin
  FWallIndex.Free;
  FWalls.Free;
  FSectorIndex.Free;
  FSectors.Free;
  inherited Destroy;
end;

class function TRadixMapInfoReader.DefaultSector(ASectorId: Integer): TRadixSectorInfo;
begin
  Result := Default(TRadixSectorInfo);
  Result.SectorId := ASectorId;
  Result.XMul := 1;
  Result.YMul := 1;
end;

function TRadixMapInfoReader.NextInteger(const AStatement: string): Integer;
var
  LValue: Int64;
begin
  if FPosition >= Length(FTokens) then
    raise ERadixException.CreateFmt(SMissingNumber, [AStatement]);
  if not TryStrToInt64(FTokens[FPosition], LValue) then
    raise ERadixException.CreateFmt(SBadNumber, [FTokens[FPosition], AStatement]);
  Inc(FPosition);
  // an angle past 2^31 is written as a negative number and read back as it was
  Result := Integer(LValue and $FFFFFFFF);
end;

function TRadixMapInfoReader.NextCardinal(const AStatement: string): Cardinal;
begin
  Result := Cardinal(NextInteger(AStatement));
end;

function TRadixMapInfoReader.NextTriple(const AStatement: string): TRadixTriple;
begin
  Result[0] := NextInteger(AStatement);
  Result[1] := NextInteger(AStatement);
  Result[2] := NextInteger(AStatement);
end;

function TRadixMapInfoReader.NextPlane(const AStatement: string): TRadixPlaneEquation;
begin
  Result.A := NextInteger(AStatement);
  Result.B := NextInteger(AStatement);
  Result.C := NextInteger(AStatement);
  Result.D := NextInteger(AStatement);
end;

function TRadixMapInfoReader.SectorSlot(ASectorId: Integer): Integer;
begin
  if not FSectorIndex.TryGetValue(ASectorId, Result) then
  begin
    Result := FSectors.Add(DefaultSector(ASectorId));
    FSectorIndex.Add(ASectorId, Result);
  end;
end;

function TRadixMapInfoReader.WallSlot(AWallId: Integer): Integer;
var
  LWall: TRadixWallInfo;
begin
  if not FWallIndex.TryGetValue(AWallId, Result) then
  begin
    LWall := Default(TRadixWallInfo);
    LWall.WallId := AWallId;
    Result := FWalls.Add(LWall);
    FWallIndex.Add(AWallId, Result);
  end;
end;

procedure TRadixMapInfoReader.ReadSectorStatement(const AWord: string; ASectorId: Integer);
var
  LSlot: Integer;
  LSector: TRadixSectorInfo;
  LStatement: TRadixSectorStatement;
begin
  LSlot := SectorSlot(ASectorId);
  LSector := FSectors[LSlot];
  if AWord = 'FLOORSLOPE' then
  begin
    LStatement := rssFloorSlope;
    LSector.FloorSlope := NextPlane(AWord);
  end
  else if AWord = 'CEILINGSLOPE' then
  begin
    LStatement := rssCeilingSlope;
    LSector.CeilingSlope := NextPlane(AWord);
  end
  else if AWord = 'XMUL' then
  begin
    LStatement := rssXMul;
    LSector.XMul := NextInteger(AWord);
  end
  else if AWord = 'XADD' then
  begin
    LStatement := rssXAdd;
    LSector.XAdd := NextInteger(AWord);
  end
  else if AWord = 'YMUL' then
  begin
    LStatement := rssYMul;
    LSector.YMul := NextInteger(AWord);
  end
  else if AWord = 'YADD' then
  begin
    LStatement := rssYAdd;
    LSector.YAdd := NextInteger(AWord);
  end
  else if AWord = 'FLOORANGLE' then
  begin
    LStatement := rssFloorAngle;
    LSector.FloorAngle := NextCardinal(AWord);
  end
  else if AWord = 'FLOORANGLE_X' then
  begin
    LStatement := rssFloorAngleX;
    LSector.FloorAngleX := NextCardinal(AWord);
  end
  else if AWord = 'FLOORANGLE_Y' then
  begin
    LStatement := rssFloorAngleY;
    LSector.FloorAngleY := NextCardinal(AWord);
  end
  else if AWord = 'CEILINGANGLE' then
  begin
    LStatement := rssCeilingAngle;
    LSector.CeilingAngle := NextCardinal(AWord);
  end
  else if AWord = 'CEILINGANGLE_X' then
  begin
    LStatement := rssCeilingAngleX;
    LSector.CeilingAngleX := NextCardinal(AWord);
  end
  else if AWord = 'CEILINGANGLE_Y' then
  begin
    LStatement := rssCeilingAngleY;
    LSector.CeilingAngleY := NextCardinal(AWord);
  end
  else if AWord = 'HEIGHTNODESX' then
  begin
    LStatement := rssHeightNodesX;
    LSector.HeightNodesX := NextTriple(AWord);
  end
  else if AWord = 'HEIGHTNODESY' then
  begin
    LStatement := rssHeightNodesY;
    LSector.HeightNodesY := NextTriple(AWord);
  end
  else if AWord = 'FLOORHEIGHTS' then
  begin
    LStatement := rssFloorHeights;
    LSector.FloorHeights := NextTriple(AWord);
  end
  else if AWord = 'CEILINGHEIGHTS' then
  begin
    LStatement := rssCeilingHeights;
    LSector.CeilingHeights := NextTriple(AWord);
  end
  else
  begin
    LStatement := rssFlags;
    LSector.Flags := NextInteger(AWord);
  end;
  Include(LSector.Statements, LStatement);
  FSectors[LSlot] := LSector;
end;

procedure TRadixMapInfoReader.ReadWallStatement(const AWord: string; AWallId: Integer);
var
  LSlot: Integer;
  LWall: TRadixWallInfo;
begin
  LSlot := WallSlot(AWallId);
  LWall := FWalls[LSlot];
  if AWord = 'WALLFLAGS' then
  begin
    LWall.Flags := NextInteger(AWord);
    Include(LWall.Statements, rwsFlags);
  end
  else if AWord = 'WALLHITPOINTS' then
  begin
    LWall.HitPoints := NextInteger(AWord);
    Include(LWall.Statements, rwsHitPoints);
  end
  else if AWord = 'WALLTRIGGER' then
  begin
    LWall.Trigger := NextInteger(AWord);
    Include(LWall.Statements, rwsTrigger);
  end
  else
    Include(LWall.Statements, rwsBriefingIgnore);
  FWalls[LSlot] := LWall;
end;

function TRadixMapInfoReader.Read(const AText: string): TRadixMapInfo;
const
  SECTOR_WORDS: array[0..16] of string = ('FLOORSLOPE', 'CEILINGSLOPE', 'XMUL', 'XADD', 'YMUL', 'YADD',
    'FLOORANGLE', 'FLOORANGLE_X', 'FLOORANGLE_Y', 'CEILINGANGLE', 'CEILINGANGLE_X', 'CEILINGANGLE_Y',
    'HEIGHTNODESX', 'HEIGHTNODESY', 'FLOORHEIGHTS', 'CEILINGHEIGHTS', 'SECTORFLAGS');
  WALL_WORDS: array[0..3] of string = ('WALLFLAGS', 'WALLHITPOINTS', 'WALLTRIGGER', 'LINEBRIEFINGIGNORE');
var
  LWord: string;
  LCandidate: string;
  LSectorId: Integer;
  LWallId: Integer;
  LHandled: Boolean;
begin
  FSectors.Clear;
  FSectorIndex.Clear;
  FWalls.Clear;
  FWallIndex.Clear;
  // a lump read as text can have zeros turned into blanks: empty words are dropped
  FTokens := AText.Split(BLANKS, TStringSplitOptions.ExcludeEmpty);
  FPosition := 0;
  LSectorId := 0;
  LWallId := 0;
  while FPosition < Length(FTokens) do
  begin
    LWord := UpperCase(FTokens[FPosition]);
    Inc(FPosition);
    if LWord = 'SECTORID' then
    begin
      LSectorId := NextInteger(LWord);
      SectorSlot(LSectorId);
      Continue;
    end;
    if LWord = 'WALLID' then
    begin
      LWallId := NextInteger(LWord);
      WallSlot(LWallId);
      Continue;
    end;
    LHandled := False;
    for LCandidate in SECTOR_WORDS do
      if LCandidate = LWord then
      begin
        ReadSectorStatement(LWord, LSectorId);
        LHandled := True;
        Break;
      end;
    if LHandled then
      Continue;
    for LCandidate in WALL_WORDS do
      if LCandidate = LWord then
      begin
        ReadWallStatement(LWord, LWallId);
        Break;
      end;
  end;
  Result.Sectors := FSectors.ToArray;
  Result.Walls := FWalls.ToArray;
  FTokens := nil;
end;

end.
