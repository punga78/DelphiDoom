{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL level geometry - the OLD checks on the      }
{  sectors (gld_PrepareSectorSpecialEffects and the vcheck loops of            }
{  gld_PreprocessSectors, copied as they were, on arrays instead of pointers)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.OldSectorPreprocessor;

interface

type
  TOldLine = record
    V1, V2: Integer;
    Sidenum: array[0..1] of Integer;
    SideSector: array[0..1] of Integer;
    Textures: array[0..1, 0..1] of Integer; // [side, 0 = top, 1 = bottom]
    Isolated: Boolean;
  end;

  TOldSector = record
    Lines: TArray<TOldLine>;
    NoTopTextures: Boolean;
    NoBottomTextures: Boolean;
  end;

  TOldLevel = record
    VertexCount: Integer;
    Sectors: TArray<TOldSector>;
  end;

/// <summary>The old code on a level of arrays (valid vertex numbers only: the old second loop read garbage otherwise)</summary>
procedure OldPreprocessSectors(var ALevel: TOldLevel);

implementation

procedure OldPrepareSectorSpecialEffects(var ASector: TOldSector);
var
  i: Integer;
begin
  ASector.NoTopTextures := True;
  ASector.NoBottomTextures := True;

  for i := 0 to Length(ASector.Lines) - 1 do
  begin
    if (ASector.Lines[i].Sidenum[0] <> -1) and (ASector.Lines[i].Sidenum[1] <> -1) then
    begin
      if ASector.Lines[i].Textures[0, 0] <> 0 then
        ASector.NoTopTextures := False;
      if ASector.Lines[i].Textures[0, 1] <> 0 then
        ASector.NoBottomTextures := False;
      if ASector.Lines[i].Textures[1, 0] <> 0 then
        ASector.NoTopTextures := False;
      if ASector.Lines[i].Textures[1, 1] <> 0 then
        ASector.NoBottomTextures := False;
    end
    else
    begin
      ASector.NoTopTextures := False;
      ASector.NoBottomTextures := False;
      Exit;
    end;
  end;
end;

procedure OldPreprocessSectors(var ALevel: TOldLevel);
var
  vcheck1, vcheck2: array of Integer;
  i, j, ppl: Integer;
  v1num, v2num: Integer;
begin
  SetLength(vcheck1, ALevel.VertexCount);
  SetLength(vcheck2, ALevel.VertexCount);
  for i := 0 to Length(ALevel.Sectors) - 1 do
  begin
    OldPrepareSectorSpecialEffects(ALevel.Sectors[i]);

    for j := 0 to ALevel.VertexCount - 1 do
    begin
      vcheck1[j] := 0;
      vcheck2[j] := 0;
    end;

    ppl := 0;
    for j := 0 to Length(ALevel.Sectors[i].Lines) - 1 do
    begin
      v1num := ALevel.Sectors[i].Lines[ppl].V1;
      v2num := ALevel.Sectors[i].Lines[ppl].V2;
      if (v1num >= ALevel.VertexCount) or (v2num >= ALevel.VertexCount) then
        Continue;

      Inc(vcheck2[v1num]);
      Inc(vcheck2[v2num]);

      if ALevel.Sectors[i].Lines[ppl].Sidenum[0] <> -1 then
        if ALevel.Sectors[i].Lines[ppl].SideSector[0] = i then
        begin
          vcheck1[v1num] := vcheck1[v1num] or 1;
          vcheck1[v2num] := vcheck1[v2num] or 2;
        end;
      if ALevel.Sectors[i].Lines[ppl].Sidenum[1] <> -1 then
        if ALevel.Sectors[i].Lines[ppl].SideSector[1] = i then
        begin
          vcheck1[v1num] := vcheck1[v1num] or 2;
          vcheck1[v2num] := vcheck1[v2num] or 1;
        end;
      Inc(ppl);
    end;

    ppl := 0;
    for j := 0 to Length(ALevel.Sectors[i].Lines) - 1 do
    begin
      v1num := ALevel.Sectors[i].Lines[ppl].V1;
      v2num := ALevel.Sectors[i].Lines[ppl].V2;
      if (vcheck2[v1num] < 2) and (vcheck2[v2num] < 2) then
        ALevel.Sectors[i].Lines[ppl].Isolated := True;
      Inc(ppl);
    end;
  end;
end;

end.
