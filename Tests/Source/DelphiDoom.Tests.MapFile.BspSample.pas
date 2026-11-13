{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the BSP samples                 }
{                                                                              }
{  Builds the small BSPs that Tools\Verifica\116\bspgen.c writes (same         }
{  formulas, same bytes): a room, a quad, a flare and patches. No data of any  }
{  game.                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspSample;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   Variant 0 is a room with a patch group of three patches (one with SURF_NODRAW) and one
  ///   patch in another group; variants 1 and 2 are a 3 x 3 field of patches in one group
  ///   with random bulges (fixed seeds) and two patches in another group
  /// </summary>
  TBspSampleBuilder = class
  strict private
    type
      TPatch = record
        OriginX, OriginY: Single;
        Width, Height: Integer;
        Bulge: Single;
        Shader, Fog, Group: Integer;
      end;
    var
      FSeed: Cardinal;
      FPatches: TArray<TPatch>;
    function NextRandom: Cardinal;
    procedure AddPatch(const AX, AY: Single; const AWidth, AHeight: Integer; const ABulge: Single;
      const AShader, AFog, AGroup: Integer);
    procedure MakePatches(const AVariant: Integer);
  public
    /// <summary>The bytes of the file</summary>
    function Build(const AVariant: Integer): TBytes;
    /// <summary>The number of surfaces: the quad, the soup, the flare and the patches</summary>
    function SurfaceCount(const AVariant: Integer): Integer;
  end;

/// <summary>Writes an integer inside lump ALump of a file in memory (to break a sample on purpose)</summary>
procedure BspPatchInt(var ABytes: TBytes; const ALump, AOffset, AValue: Integer);

/// <summary>Writes the length of lump ALump in the header</summary>
procedure BspPatchLumpLength(var ABytes: TBytes; const ALump, ALength: Integer);

/// <summary>The offset of lump ALump in the file</summary>
function BspLumpOffset(const ABytes: TBytes; const ALump: Integer): Integer;

implementation

uses
  System.Classes;

function BspLumpOffset(const ABytes: TBytes; const ALump: Integer): Integer;
begin
  Move(ABytes[8 + ALump * 8], Result, 4);
end;

procedure BspPatchInt(var ABytes: TBytes; const ALump, AOffset, AValue: Integer);
begin
  Move(AValue, ABytes[BspLumpOffset(ABytes, ALump) + AOffset], 4);
end;

procedure BspPatchLumpLength(var ABytes: TBytes; const ALump, ALength: Integer);
begin
  Move(ALength, ABytes[8 + ALump * 8 + 4], 4);
end;

const
  GROUP_MIN: array[0..1, 0..2] of Single = ((0, 0, -128), (1000, 1000, -128));
  GROUP_MAX: array[0..1, 0..2] of Single = ((256, 256, 256), (1256, 1256, 256));

type
  TLump = TBytesStream;

procedure PutInt(const ALump: TLump; const AValue: Integer);
begin
  ALump.WriteBuffer(AValue, 4);
end;

procedure PutFloat(const ALump: TLump; const AValue: Single);
begin
  ALump.WriteBuffer(AValue, 4);
end;

procedure PutName(const ALump: TLump; const AName: AnsiString);
var
  LName: array[0..BSP_MAX_QPATH - 1] of AnsiChar;
begin
  FillChar(LName, SizeOf(LName), 0);
  Move(AName[1], LName[0], Length(AName));
  ALump.WriteBuffer(LName, SizeOf(LName));
end;

procedure PutPlane(const ALump: TLump; const AX, AY, AZ, ADist: Single);
begin
  PutFloat(ALump, AX);
  PutFloat(ALump, AY);
  PutFloat(ALump, AZ);
  PutFloat(ALump, ADist);
end;

function EdgeZ(const AX, AY: Single): Single;
begin
  Result := (((Trunc(AX) div 32) * 7 + (Trunc(AY) div 32) * 13) mod 5) * 8;
end;

procedure PutSurface(const ALump: TLump; const AShader, AFog, AType, AFirstVert, ANumVerts,
  AFirstIndex, ANumIndexes, ALightmapNum, ALightmapWidth, ALightmapHeight: Integer;
  const AOrigin: array of Single; const AVecs: array of Single; const AWidth, AHeight: Integer);
var
  LIndex: Integer;
begin
  PutInt(ALump, AShader);
  PutInt(ALump, AFog);
  PutInt(ALump, AType);
  PutInt(ALump, AFirstVert);
  PutInt(ALump, ANumVerts);
  PutInt(ALump, AFirstIndex);
  PutInt(ALump, ANumIndexes);
  PutInt(ALump, ALightmapNum);
  PutInt(ALump, 0);
  PutInt(ALump, 0);
  PutInt(ALump, ALightmapWidth);
  PutInt(ALump, ALightmapHeight);
  for LIndex := 0 to 2 do
    PutFloat(ALump, AOrigin[LIndex]);
  for LIndex := 0 to 8 do
    PutFloat(ALump, AVecs[LIndex]);
  PutInt(ALump, AWidth);
  PutInt(ALump, AHeight);
end;

{ TBspSampleBuilder }

function TBspSampleBuilder.NextRandom: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

procedure TBspSampleBuilder.AddPatch(const AX, AY: Single; const AWidth, AHeight: Integer;
  const ABulge: Single; const AShader, AFog, AGroup: Integer);
var
  LPatch: TPatch;
begin
  LPatch.OriginX := AX;
  LPatch.OriginY := AY;
  LPatch.Width := AWidth;
  LPatch.Height := AHeight;
  LPatch.Bulge := ABulge;
  LPatch.Shader := AShader;
  LPatch.Fog := AFog;
  LPatch.Group := AGroup;
  SetLength(FPatches, Length(FPatches) + 1);
  FPatches[High(FPatches)] := LPatch;
end;

procedure TBspSampleBuilder.MakePatches(const AVariant: Integer);
var
  LA, LB: Integer;
  LBulge: Single;
begin
  FPatches := nil;
  if AVariant = 0 then
  begin
    AddPatch(0, 0, 3, 3, 128, 2, 0, 0);
    AddPatch(128, 0, 3, 3, 0, 2, -1, 0);
    AddPatch(0, 128, 3, 3, -96, 2, -1, 0);
    AddPatch(512, 0, 3, 3, 32, 1, -1, 0);
    AddPatch(1000, 1000, 5, 5, 64, 2, -1, 1);
  end
  else
  begin
    if AVariant = 1 then
      FSeed := $1234ABCD
    else
      FSeed := $0BADF00D;
    for LB := 0 to 2 do
      for LA := 0 to 2 do
      begin
        LBulge := Integer(NextRandom mod 321) - 160;
        AddPatch(LA * 128, LB * 128, 3, 3, LBulge, 2, -1, 0);
      end;
    AddPatch(1000, 1000, 5, 3, 48, 2, -1, 1);
    AddPatch(1128, 1000, 3, 5, -48, 2, -1, 1);
  end;
end;

function TBspSampleBuilder.SurfaceCount(const AVariant: Integer): Integer;
begin
  MakePatches(AVariant);
  Result := 3 + Length(FPatches);
end;

function TBspSampleBuilder.Build(const AVariant: Integer): TBytes;
const
  ZERO3: array[0..2] of Single = (0, 0, 0);
  QUAD_VECS: array[0..8] of Single = (128, 0, 0, 0, 128, 0, 0, 0, 1);
  QUAD_ORIGIN: array[0..2] of Single = (-64, -64, 0);
  FLARE_ORIGIN: array[0..2] of Single = (0, 0, 32);
  QUAD_X: array[0..3] of Single = (-64, 64, 64, -64);
  QUAD_Y: array[0..3] of Single = (-64, -64, 64, 64);
  QUAD_S: array[0..3] of Single = (0, 1, 1, 0);
  QUAD_T: array[0..3] of Single = (0, 0, 1, 1);
  QUAD_INDEXES: array[0..5] of Integer = (0, 1, 2, 0, 2, 3);
var
  LLumps: array[0..HEADER_LUMPS - 1] of TLump;
  LHeader: TBspHeader;
  LVecs: array[0..8] of Single;
  LIndex, LJ, LSurfaceCount, LVertex, LOffset, LPadding: Integer;
  LNormal: array[0..2] of Single;
  LText: AnsiString;
  LColor: array[0..3] of Byte;
  LByte: Byte;
  LS, LT, LX, LY, LZ: Single;
  LPatch: TPatch;
  LOutput: TBytesStream;
  LZeroes: Cardinal;
begin
  for LIndex := 0 to HEADER_LUMPS - 1 do
    LLumps[LIndex] := TBytesStream.Create;
  try
    MakePatches(AVariant);
    LSurfaceCount := 3 + Length(FPatches);

    LText := AnsiString(Format('{'#10'"classname" "worldspawn"'#10'"message" "q3 test variant %d"'#10'}'#10 +
      '{'#10'"classname" "info_player_deathmatch"'#10'"origin" "0 0 24"'#10'"angle" "90"'#10'}'#10,
      [AVariant]));
    LLumps[LUMP_ENTITIES].WriteBuffer(LText[1], Length(LText));
    LByte := 0;
    LLumps[LUMP_ENTITIES].WriteBuffer(LByte, 1);

    PutName(LLumps[LUMP_SHADERS], 'textures/test/wall');
    PutInt(LLumps[LUMP_SHADERS], 0);
    PutInt(LLumps[LUMP_SHADERS], 1);
    PutName(LLumps[LUMP_SHADERS], 'textures/test/nodraw');
    PutInt(LLumps[LUMP_SHADERS], SURF_NODRAW);
    PutInt(LLumps[LUMP_SHADERS], 0);
    PutName(LLumps[LUMP_SHADERS], 'textures/test/curve');
    PutInt(LLumps[LUMP_SHADERS], 0);
    PutInt(LLumps[LUMP_SHADERS], 0);

    for LIndex := 0 to 2 do
    begin
      LNormal[0] := 0;
      LNormal[1] := 0;
      LNormal[2] := 0;
      LNormal[LIndex] := 1;
      PutPlane(LLumps[LUMP_PLANES], LNormal[0], LNormal[1], LNormal[2], 64);
      LNormal[LIndex] := -1;
      PutPlane(LLumps[LUMP_PLANES], LNormal[0], LNormal[1], LNormal[2], 64);
    end;
    PutPlane(LLumps[LUMP_PLANES], 0.25, 0.5, 0.75, 12.5);
    PutPlane(LLumps[LUMP_PLANES], 0.0, 0.5, 0.75, -32.0);

    PutInt(LLumps[LUMP_NODES], 6);
    PutInt(LLumps[LUMP_NODES], -1);
    PutInt(LLumps[LUMP_NODES], -2);
    for LIndex := 0 to 2 do
      PutInt(LLumps[LUMP_NODES], -64);
    for LIndex := 0 to 2 do
      PutInt(LLumps[LUMP_NODES], 64);

    for LJ := 0 to 1 do
    begin
      PutInt(LLumps[LUMP_LEAFS], LJ);
      PutInt(LLumps[LUMP_LEAFS], 0);
      for LIndex := 0 to 2 do
        PutInt(LLumps[LUMP_LEAFS], -64);
      for LIndex := 0 to 2 do
        PutInt(LLumps[LUMP_LEAFS], 64);
      PutInt(LLumps[LUMP_LEAFS], 0);
      if LJ = 0 then
        PutInt(LLumps[LUMP_LEAFS], LSurfaceCount)
      else
        PutInt(LLumps[LUMP_LEAFS], 0);
      PutInt(LLumps[LUMP_LEAFS], 0);
      if LJ = 0 then
        PutInt(LLumps[LUMP_LEAFS], 1)
      else
        PutInt(LLumps[LUMP_LEAFS], 0);
    end;
    for LIndex := 0 to LSurfaceCount - 1 do
      PutInt(LLumps[LUMP_LEAFSURFACES], LIndex);
    PutInt(LLumps[LUMP_LEAFBRUSHES], 0);

    for LIndex := 0 to 2 do
      PutFloat(LLumps[LUMP_MODELS], -64);
    for LIndex := 0 to 2 do
      PutFloat(LLumps[LUMP_MODELS], 64);
    PutInt(LLumps[LUMP_MODELS], 0);
    PutInt(LLumps[LUMP_MODELS], LSurfaceCount);
    PutInt(LLumps[LUMP_MODELS], 0);
    PutInt(LLumps[LUMP_MODELS], 1);

    PutInt(LLumps[LUMP_BRUSHES], 0);
    PutInt(LLumps[LUMP_BRUSHES], 6);
    PutInt(LLumps[LUMP_BRUSHES], 0);
    for LIndex := 0 to 5 do
    begin
      PutInt(LLumps[LUMP_BRUSHSIDES], LIndex);
      PutInt(LLumps[LUMP_BRUSHSIDES], 0);
    end;

    // the quad
    for LIndex := 0 to 3 do
    begin
      LColor[0] := 255;
      LColor[1] := 128;
      LColor[2] := 64;
      LColor[3] := 255;
      PutFloat(LLumps[LUMP_DRAWVERTS], QUAD_X[LIndex]);
      PutFloat(LLumps[LUMP_DRAWVERTS], QUAD_Y[LIndex]);
      PutFloat(LLumps[LUMP_DRAWVERTS], 0);
      PutFloat(LLumps[LUMP_DRAWVERTS], QUAD_S[LIndex]);
      PutFloat(LLumps[LUMP_DRAWVERTS], QUAD_T[LIndex]);
      LS := QUAD_S[LIndex] * 0.5;
      LT := QUAD_T[LIndex] * 0.5;
      PutFloat(LLumps[LUMP_DRAWVERTS], LS);
      PutFloat(LLumps[LUMP_DRAWVERTS], LT);
      PutFloat(LLumps[LUMP_DRAWVERTS], 0);
      PutFloat(LLumps[LUMP_DRAWVERTS], 0);
      PutFloat(LLumps[LUMP_DRAWVERTS], 1);
      LLumps[LUMP_DRAWVERTS].WriteBuffer(LColor, 4);
    end;
    for LIndex := 0 to 5 do
      PutInt(LLumps[LUMP_DRAWINDEXES], QUAD_INDEXES[LIndex]);

    PutName(LLumps[LUMP_FOGS], 'textures/test/fog');
    PutInt(LLumps[LUMP_FOGS], 0);
    PutInt(LLumps[LUMP_FOGS], -1);

    PutSurface(LLumps[LUMP_SURFACES], 0, -1, MST_PLANAR, 0, 4, 0, 6, 0, 128, 128, QUAD_ORIGIN, QUAD_VECS, 0, 0);
    PutSurface(LLumps[LUMP_SURFACES], 0, -1, MST_TRIANGLE_SOUP, 0, 4, 0, 6, -1, 0, 0, ZERO3, QUAD_VECS, 0, 0);
    PutSurface(LLumps[LUMP_SURFACES], 0, -1, MST_FLARE, 0, 1, 0, 0, -1, 0, 0, FLARE_ORIGIN, QUAD_VECS, 0, 0);
    LVertex := 4;
    for LIndex := 0 to High(FPatches) do
    begin
      LPatch := FPatches[LIndex];
      FillChar(LVecs, SizeOf(LVecs), 0);
      for LJ := 0 to 2 do
      begin
        LVecs[LJ] := GROUP_MIN[LPatch.Group, LJ];
        LVecs[3 + LJ] := GROUP_MAX[LPatch.Group, LJ];
      end;
      PutSurface(LLumps[LUMP_SURFACES], LPatch.Shader, LPatch.Fog, MST_PATCH, LVertex, LPatch.Width * LPatch.Height,
        0, 0, -1, 0, 0, ZERO3, LVecs, LPatch.Width, LPatch.Height);
      for LJ := 0 to LPatch.Height - 1 do
        for LOffset := 0 to LPatch.Width - 1 do
        begin
          LX := LPatch.OriginX + (LOffset * (128 div (LPatch.Width - 1)));
          LY := LPatch.OriginY + (LJ * (128 div (LPatch.Height - 1)));
          if (LOffset > 0) and (LOffset < LPatch.Width - 1) and (LJ > 0) and (LJ < LPatch.Height - 1) then
            LZ := LPatch.Bulge
          else
            LZ := EdgeZ(LX, LY);
          LS := LOffset / (LPatch.Width - 1);
          LT := LJ / (LPatch.Height - 1);
          PutFloat(LLumps[LUMP_DRAWVERTS], LX);
          PutFloat(LLumps[LUMP_DRAWVERTS], LY);
          PutFloat(LLumps[LUMP_DRAWVERTS], LZ);
          PutFloat(LLumps[LUMP_DRAWVERTS], LS);
          PutFloat(LLumps[LUMP_DRAWVERTS], LT);
          LS := LS * 0.5;
          LT := LT * 0.5;
          PutFloat(LLumps[LUMP_DRAWVERTS], LS);
          PutFloat(LLumps[LUMP_DRAWVERTS], LT);
          PutFloat(LLumps[LUMP_DRAWVERTS], 0);
          PutFloat(LLumps[LUMP_DRAWVERTS], 0);
          PutFloat(LLumps[LUMP_DRAWVERTS], 0);
          LColor[0] := (LOffset * 37 + LJ * 91) and 255;
          LColor[1] := (LOffset * 11 + LJ * 53 + 7) and 255;
          LColor[2] := 255 - ((LOffset * 29 + LJ * 13) and 255);
          LColor[3] := ((LOffset + LJ) * 17) and 255;
          LLumps[LUMP_DRAWVERTS].WriteBuffer(LColor, 4);
        end;
      Inc(LVertex, LPatch.Width * LPatch.Height);
    end;

    FSeed := $A5A5A5A5 xor Cardinal(AVariant);
    for LIndex := 0 to 2 * 128 * 128 * 3 - 1 do
    begin
      LByte := Byte(NextRandom shr 7);
      LLumps[LUMP_LIGHTMAPS].WriteBuffer(LByte, 1);
    end;
    for LIndex := 0 to 6 * 8 - 1 do
    begin
      LByte := Byte(NextRandom shr 11);
      LLumps[LUMP_LIGHTGRID].WriteBuffer(LByte, 1);
    end;
    PutInt(LLumps[LUMP_VISIBILITY], 2);
    PutInt(LLumps[LUMP_VISIBILITY], 8);
    for LIndex := 0 to 15 do
    begin
      LByte := Byte(NextRandom shr 3);
      LLumps[LUMP_VISIBILITY].WriteBuffer(LByte, 1);
    end;

    FillChar(LHeader, SizeOf(LHeader), 0);
    LHeader.Ident := BSP_IDENT;
    LHeader.Version := BSP_VERSION;
    LOffset := SizeOf(TBspHeader);
    for LIndex := 0 to HEADER_LUMPS - 1 do
    begin
      LHeader.Lumps[LIndex].FileOfs := LOffset;
      LHeader.Lumps[LIndex].FileLen := Integer(LLumps[LIndex].Size);
      Inc(LOffset, (Integer(LLumps[LIndex].Size) + 3) and not 3);
    end;
    LOutput := TBytesStream.Create;
    try
      LOutput.WriteBuffer(LHeader, SizeOf(LHeader));
      LZeroes := 0;
      for LIndex := 0 to HEADER_LUMPS - 1 do
      begin
        if LLumps[LIndex].Size > 0 then
          LOutput.WriteBuffer(LLumps[LIndex].Bytes[0], LLumps[LIndex].Size);
        LPadding := ((Integer(LLumps[LIndex].Size) + 3) and not 3) - Integer(LLumps[LIndex].Size);
        if LPadding > 0 then
          LOutput.WriteBuffer(LZeroes, LPadding);
      end;
      Result := Copy(LOutput.Bytes, 0, LOutput.Size);
    finally
      LOutput.Free;
    end;
  finally
    for LIndex := 0 to HEADER_LUMPS - 1 do
      LLumps[LIndex].Free;
  end;
end;

end.
