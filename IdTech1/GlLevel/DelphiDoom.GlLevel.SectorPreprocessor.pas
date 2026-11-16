{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL level geometry - the checks on the sectors               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  The check of the vertexes is from prboom-plus (e6y).                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlLevel.SectorPreprocessor;

interface

uses
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>
  ///   The part of the old gld_PreprocessSectors that reads and writes the records of sectors and lines:
  ///   gld_PrepareSectorSpecialEffects and the check of the vertexes that finds the isolated lines. It
  ///   works through an IGlSectorWorld, once per level (cold path).
  /// </summary>
  /// <remarks>
  ///   The old code also filled a second array (vcheck1, which side a vertex is on) that nobody read:
  ///   it is not computed. The count of the uses of a vertex is zeroed only where it was touched, not
  ///   for the whole vertex array at every sector.
  /// </remarks>
  TGlSectorPreprocessor = class(TInterfacedObject, IGlSectorPreprocessor)
  strict private
    FWorld: IGlSectorWorld;
    procedure PrepareSpecialEffects(const ASector: Integer);
    procedure MarkIsolatedLines(const ASector: Integer; var AUses: TArray<Integer>);
    class function VertexUses(const AUses: TArray<Integer>; const AVertex: Integer): Integer; static;
  public
    constructor Create(const AWorld: IGlSectorWorld);
    procedure Preprocess;
  end;

implementation

uses
  System.SysUtils;

{ TGlSectorPreprocessor }

constructor TGlSectorPreprocessor.Create(const AWorld: IGlSectorWorld);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  FWorld := AWorld;
end;

procedure TGlSectorPreprocessor.PrepareSpecialEffects(const ASector: Integer);
var
  LLine: Integer;
  LRecord: TGlSectorLine;
  LNoTop: Boolean;
  LNoBottom: Boolean;
begin
  LNoTop := True;
  LNoBottom := True;
  for LLine := 0 to FWorld.GetLineCount(ASector) - 1 do
  begin
    LRecord := FWorld.GetLine(ASector, LLine);
    if LRecord.HasBothSides then
    begin
      if LRecord.FrontTopTexture <> 0 then
        LNoTop := False;
      if LRecord.FrontBottomTexture <> 0 then
        LNoBottom := False;
      if LRecord.BackTopTexture <> 0 then
        LNoTop := False;
      if LRecord.BackBottomTexture <> 0 then
        LNoBottom := False;
    end
    else
    begin
      // a line with one side (or none) ends the check: the sector has both kinds of textures
      LNoTop := False;
      LNoBottom := False;
      Break;
    end;
  end;
  FWorld.SetNoTextures(ASector, LNoTop, LNoBottom);
end;

class function TGlSectorPreprocessor.VertexUses(const AUses: TArray<Integer>; const AVertex: Integer): Integer;
begin
  if (AVertex >= 0) and (AVertex < Length(AUses)) then
    Result := AUses[AVertex]
  else
    Result := 0;
end;

procedure TGlSectorPreprocessor.MarkIsolatedLines(const ASector: Integer; var AUses: TArray<Integer>);
var
  LLine: Integer;
  LCounted: Integer;
  LRecord: TGlSectorLine;
begin
  // e6y: for correct handling of missing textures we do not need to apply some algorithms to isolated
  // lines. A line whose vertexes are not in the array ends the count (the old loop did not advance
  // its pointer there and skipped every following line).
  LCounted := 0;
  for LLine := 0 to FWorld.GetLineCount(ASector) - 1 do
  begin
    LRecord := FWorld.GetLine(ASector, LLine);
    if (LRecord.Vertex1 < 0) or (LRecord.Vertex1 >= Length(AUses)) or
       (LRecord.Vertex2 < 0) or (LRecord.Vertex2 >= Length(AUses)) then
      Break;
    Inc(AUses[LRecord.Vertex1]);
    Inc(AUses[LRecord.Vertex2]);
    Inc(LCounted);
  end;

  for LLine := 0 to FWorld.GetLineCount(ASector) - 1 do
  begin
    LRecord := FWorld.GetLine(ASector, LLine);
    if (VertexUses(AUses, LRecord.Vertex1) < 2) and (VertexUses(AUses, LRecord.Vertex2) < 2) then
      FWorld.MarkIsolated(ASector, LLine);
  end;

  // clear what the first pass counted, for the next sector
  for LLine := 0 to LCounted - 1 do
  begin
    LRecord := FWorld.GetLine(ASector, LLine);
    AUses[LRecord.Vertex1] := 0;
    AUses[LRecord.Vertex2] := 0;
  end;
end;

procedure TGlSectorPreprocessor.Preprocess;
var
  LSector: Integer;
  LUses: TArray<Integer>;
begin
  SetLength(LUses, FWorld.GetVertexCount);
  if Length(LUses) > 0 then
    FillChar(LUses[0], Length(LUses) * SizeOf(Integer), 0);
  for LSector := 0 to FWorld.GetSectorCount - 1 do
  begin
    PrepareSpecialEffects(LSector);
    MarkIsolatedLines(LSector, LUses);
  end;
end;

end.
