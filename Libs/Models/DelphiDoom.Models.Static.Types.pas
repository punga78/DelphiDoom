{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models (idTech 4): shared types      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\geometry\          }
{  DrawVert.h, renderer\Model_local.h, renderer\Model.cpp. Copyright (C)       }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>The name of the material of the surfaces of a model without materials (tr.defaultMaterial)</summary>
  STATIC_DEFAULT_MATERIAL = '_default';

type
  /// <summary>The colour of a vertex: four bytes (the byte color[4] of idDrawVert)</summary>
  TStaticColor = record
    R: Byte;
    G: Byte;
    B: Byte;
    A: Byte;
    /// <summary>The four bytes as the dword of idDrawVert::GetColor (R in the lowest byte)</summary>
    function ToCardinal: Cardinal;
    class function FromCardinal(const AValue: Cardinal): TStaticColor; static;
    class function Make(const AR, AG, AB, AA: Byte): TStaticColor; static;
  end;

  /// <summary>
  ///   A vertex of a surface (idDrawVert, 60 bytes): position, texture coordinates, normal, the
  ///   two tangents and the colour. The only vertex type of the static models of every format.
  /// </summary>
  TStaticDrawVert = record
    Xyz: TIdVec3;
    St: TIdVec2;
    Normal: TIdVec3;
    Tangents: array[0..1] of TIdVec3;
    Color: TStaticColor;
    /// <summary>idDrawVert::Clear: everything zero</summary>
    procedure Clear;
  end;

  /// <summary>
  ///   What the loaders take from the cvars of the renderer (r_mergeModelSurfaces, r_slopVertex,
  ///   r_slopTexCoord, r_slopNormal) and from the load flags (fastLoad of renderbump)
  /// </summary>
  TStaticLoadOptions = record
    /// <summary>Merge the surfaces with the same material (r_mergeModelSurfaces)</summary>
    MergeSurfaces: Boolean;
    /// <summary>Weld the positions that are this near (r_slopVertex)</summary>
    SlopVertex: Single;
    /// <summary>Weld the texture coordinates that are this near (r_slopTexCoord)</summary>
    SlopTexCoord: Single;
    /// <summary>Weld the vertexes whose normals dot more than 1 minus this (r_slopNormal)</summary>
    SlopNormal: Single;
    /// <summary>Do not weld anything that is not identical (idRenderModelStatic::fastLoad)</summary>
    FastLoad: Boolean;
    /// <summary>The defaults of the cvars: merge, 0.01, 0.001, 0.02, not fast</summary>
    class function Default: TStaticLoadOptions; static;
  end;

  /// <summary>
  ///   A model that cannot be read: the file is damaged or truncated, a number is out of range,
  ///   or a feature is not supported. <c>Line</c> is the line of a text format (ASE, 0 if not
  ///   known), <c>Offset</c> the byte of a binary one (LWO, -1 if not known).
  /// </summary>
  EStaticModelException = class(Exception)
  strict private
    FLine: Integer;
    FOffset: Integer;
  public
    constructor CreateAtLine(const AMessage: string; const ALine: Integer);
    constructor CreateAtOffset(const AMessage: string; const AOffset: Integer);
    property Line: Integer read FLine;
    property Offset: Integer read FOffset;
  end;

resourcestring
  SStaticTruncated = 'The model is truncated: %d bytes needed at the offset %d, the file has %d';
  SStaticNegativeSize = 'The model has a negative size (%d) at the offset %d';
  SStaticLwoNotLwo = 'The file is not a LightWave object (FORM/LWO2 expected)';
  SStaticLwoLwob = 'The LWOB format (LightWave 5) is not supported';
  SStaticLwoBadChunk = 'LWO: the chunk %s is damaged (%s)';
  SStaticLwoBadPolygonTag = 'LWO: the polygon tag %d does not exist (%d polygons)';
  SStaticLwoBadPoint = 'LWO: the point %d does not exist (%d points)';
  SStaticLwoBadTag = 'LWO: the surface tag %d does not exist (%d tags)';
  SStaticLwoNoTags = 'LWO: the polygons have no surface (no TAGS chunk)';
  SStaticLwoNoSurfaces = 'LWO: the object has no surfaces';
  SStaticLwoNoPoints = 'LWO: the model has bad or missing vertex data';
  SStaticLwoBadVMap = 'LWO: the vertex map %s has a record that does not exist (%s %d)';
  SStaticLwoTexDimension = 'LWO: the texture map %s has %d dimensions, 2 needed';
  SStaticAseUnexpectedBrace = 'ASE: unexpected "}"';
  SStaticAseUnknownToken = 'ASE: unknown token "%s" while parsing %s';
  SStaticAseOutOfRange = 'ASE: %s out of range: %d (%d)';
  SStaticAseBeforeFaces = 'ASE: %s before *MESH_FACE_LIST';
  SStaticAseCountMismatch = 'ASE: MESH_NUMTVFACES != MESH_NUMFACES';
  SStaticAseNormalFace = 'ASE: MESH_NORMALS face index != currentFace';
  SStaticAseNormalVertex = 'ASE: MESH_NORMALS vertex index does not match the face';
  SStaticAseBadVertex = 'ASE: bad vertex index in the model';
  SStaticAseBadTexCoord = 'ASE: bad tex coord index in the model';
  SStaticAseBadMaterial = 'ASE: the object %d uses the material %d, that does not exist (%d materials)';
  SStaticAseNoObjects = 'ASE: the model has no objects';
  SStaticWarnLwoNoUv = 'LWO: the model has bad or missing uv data';
  SStaticWarnLwoPolygon = 'LWO: the model has a polygon with %d vertexes, skipped (a model must be triangulated)';

implementation

{ TStaticColor }

function TStaticColor.ToCardinal: Cardinal;
begin
  Result := Cardinal(R) or (Cardinal(G) shl 8) or (Cardinal(B) shl 16) or (Cardinal(A) shl 24);
end;

class function TStaticColor.FromCardinal(const AValue: Cardinal): TStaticColor;
begin
  Result.R := Byte(AValue);
  Result.G := Byte(AValue shr 8);
  Result.B := Byte(AValue shr 16);
  Result.A := Byte(AValue shr 24);
end;

class function TStaticColor.Make(const AR, AG, AB, AA: Byte): TStaticColor;
begin
  Result.R := AR;
  Result.G := AG;
  Result.B := AB;
  Result.A := AA;
end;

{ TStaticDrawVert }

procedure TStaticDrawVert.Clear;
begin
  Xyz.Zero;
  St.Zero;
  Normal.Zero;
  Tangents[0].Zero;
  Tangents[1].Zero;
  Color := TStaticColor.Make(0, 0, 0, 0);
end;

{ TStaticLoadOptions }

class function TStaticLoadOptions.Default: TStaticLoadOptions;
begin
  Result.MergeSurfaces := True;
  Result.SlopVertex := 0.01;
  Result.SlopTexCoord := 0.001;
  Result.SlopNormal := 0.02;
  Result.FastLoad := False;
end;

{ EStaticModelException }

constructor EStaticModelException.CreateAtLine(const AMessage: string; const ALine: Integer);
begin
  if ALine > 0 then
    inherited CreateFmt('%s (line %d)', [AMessage, ALine])
  else
    inherited Create(AMessage);
  FLine := ALine;
  FOffset := -1;
end;

constructor EStaticModelException.CreateAtOffset(const AMessage: string; const AOffset: Integer);
begin
  if AOffset >= 0 then
    inherited CreateFmt('%s (offset %d)', [AMessage, AOffset])
  else
    inherited Create(AMessage);
  FLine := 0;
  FOffset := AOffset;
end;

end.
