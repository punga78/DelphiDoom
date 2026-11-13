{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the names of functions, blends and parms    }
{                                                                              }
{  Port of NameToAFunc, NameToSrcBlendMode, NameToDstBlendMode,                }
{  NameToGenFunc, the table infoParms and ParseSurfaceParm of                  }
{  renderer\tr_shader.c of Quake III Arena (id Software, GPL v2 or later).     }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Names;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context;

type
  /// <summary>The words of a shader that stand for a number or a mode; every comparison ignores case</summary>
  TQ3ShaderNames = class sealed
  public
    /// <summary>NameToAFunc: the GLS_ATEST_* bits, 0 with a warning for a name that is not known</summary>
    class function AlphaFunc(const AContext: TQ3ShaderContext; const AName: AnsiString): Cardinal; static;
    /// <summary>NameToSrcBlendMode: GL_ONE with a warning for a name that is not known</summary>
    class function SourceBlendMode(const AContext: TQ3ShaderContext; const AName: AnsiString): Cardinal; static;
    /// <summary>NameToDstBlendMode: GL_ONE with a warning for a name that is not known</summary>
    class function DestinationBlendMode(const AContext: TQ3ShaderContext; const AName: AnsiString): Cardinal; static;
    /// <summary>NameToGenFunc: sin with a warning for a name that is not known</summary>
    class function GenFunc(const AContext: TQ3ShaderContext; const AName: AnsiString): TQ3GenFunc; static;
    /// <summary>
    ///   The body of ParseSurfaceParm after the word is read: adds the flags of a name of <c>infoParms</c>
    ///   to the shader; a name that is not in the table is ignored without a warning
    /// </summary>
    class procedure ApplySurfaceParm(const AContext: TQ3ShaderContext; const AName: AnsiString); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

type
  TInfoParm = record
    Name: AnsiString;
    SurfaceFlags: Integer;
    Contents: Integer;
  end;

const
  // infoParms[]; clearSolid is unused in the renderer (#if 0) and is not kept
  INFO_PARMS: array[0..31] of TInfoParm = (
    (Name: 'water'; SurfaceFlags: 0; Contents: CONTENTS_WATER),
    (Name: 'slime'; SurfaceFlags: 0; Contents: CONTENTS_SLIME),
    (Name: 'lava'; SurfaceFlags: 0; Contents: CONTENTS_LAVA),
    (Name: 'playerclip'; SurfaceFlags: 0; Contents: CONTENTS_PLAYERCLIP),
    (Name: 'monsterclip'; SurfaceFlags: 0; Contents: CONTENTS_MONSTERCLIP),
    (Name: 'nodrop'; SurfaceFlags: 0; Contents: CONTENTS_NODROP),
    (Name: 'nonsolid'; SurfaceFlags: SURF_NONSOLID; Contents: 0),
    (Name: 'origin'; SurfaceFlags: 0; Contents: CONTENTS_ORIGIN),
    (Name: 'trans'; SurfaceFlags: 0; Contents: CONTENTS_TRANSLUCENT),
    (Name: 'detail'; SurfaceFlags: 0; Contents: CONTENTS_DETAIL),
    (Name: 'structural'; SurfaceFlags: 0; Contents: CONTENTS_STRUCTURAL),
    (Name: 'areaportal'; SurfaceFlags: 0; Contents: CONTENTS_AREAPORTAL),
    (Name: 'clusterportal'; SurfaceFlags: 0; Contents: CONTENTS_CLUSTERPORTAL),
    (Name: 'donotenter'; SurfaceFlags: 0; Contents: CONTENTS_DONOTENTER),
    (Name: 'fog'; SurfaceFlags: 0; Contents: CONTENTS_FOG),
    (Name: 'sky'; SurfaceFlags: SURF_SKY; Contents: 0),
    (Name: 'lightfilter'; SurfaceFlags: SURF_LIGHTFILTER; Contents: 0),
    (Name: 'alphashadow'; SurfaceFlags: SURF_ALPHASHADOW; Contents: 0),
    (Name: 'hint'; SurfaceFlags: SURF_HINT; Contents: 0),
    (Name: 'slick'; SurfaceFlags: SURF_SLICK; Contents: 0),
    (Name: 'noimpact'; SurfaceFlags: SURF_NOIMPACT; Contents: 0),
    (Name: 'nomarks'; SurfaceFlags: SURF_NOMARKS; Contents: 0),
    (Name: 'ladder'; SurfaceFlags: SURF_LADDER; Contents: 0),
    (Name: 'nodamage'; SurfaceFlags: SURF_NODAMAGE; Contents: 0),
    (Name: 'metalsteps'; SurfaceFlags: SURF_METALSTEPS; Contents: 0),
    (Name: 'flesh'; SurfaceFlags: SURF_FLESH; Contents: 0),
    (Name: 'nosteps'; SurfaceFlags: SURF_NOSTEPS; Contents: 0),
    (Name: 'nodraw'; SurfaceFlags: SURF_NODRAW; Contents: 0),
    (Name: 'pointlight'; SurfaceFlags: SURF_POINTLIGHT; Contents: 0),
    (Name: 'nolightmap'; SurfaceFlags: SURF_NOLIGHTMAP; Contents: 0),
    (Name: 'nodlight'; SurfaceFlags: SURF_NODLIGHT; Contents: 0),
    (Name: 'dust'; SurfaceFlags: SURF_DUST; Contents: 0));

function SameName(const AText1, AText2: AnsiString): Boolean;
begin
  Result := TIdStrings.Icmp(AText1, AText2) = 0;
end;

{ TQ3ShaderNames }

class function TQ3ShaderNames.AlphaFunc(const AContext: TQ3ShaderContext; const AName: AnsiString): Cardinal;
begin
  if SameName(AName, 'GT0') then
    Exit(GLS_ATEST_GT_0);
  if SameName(AName, 'LT128') then
    Exit(GLS_ATEST_LT_80);
  if SameName(AName, 'GE128') then
    Exit(GLS_ATEST_GE_80);
  AContext.Warn('invalid alphaFunc name ''%s'' in shader ''%s''', [AName, AContext.Data.Name]);
  Result := 0;
end;

class function TQ3ShaderNames.SourceBlendMode(const AContext: TQ3ShaderContext; const AName: AnsiString): Cardinal;
begin
  if SameName(AName, 'GL_ONE') then
    Exit(GLS_SRCBLEND_ONE);
  if SameName(AName, 'GL_ZERO') then
    Exit(GLS_SRCBLEND_ZERO);
  if SameName(AName, 'GL_DST_COLOR') then
    Exit(GLS_SRCBLEND_DST_COLOR);
  if SameName(AName, 'GL_ONE_MINUS_DST_COLOR') then
    Exit(GLS_SRCBLEND_ONE_MINUS_DST_COLOR);
  if SameName(AName, 'GL_SRC_ALPHA') then
    Exit(GLS_SRCBLEND_SRC_ALPHA);
  if SameName(AName, 'GL_ONE_MINUS_SRC_ALPHA') then
    Exit(GLS_SRCBLEND_ONE_MINUS_SRC_ALPHA);
  if SameName(AName, 'GL_DST_ALPHA') then
    Exit(GLS_SRCBLEND_DST_ALPHA);
  if SameName(AName, 'GL_ONE_MINUS_DST_ALPHA') then
    Exit(GLS_SRCBLEND_ONE_MINUS_DST_ALPHA);
  if SameName(AName, 'GL_SRC_ALPHA_SATURATE') then
    Exit(GLS_SRCBLEND_ALPHA_SATURATE);
  AContext.Warn('unknown blend mode ''%s'' in shader ''%s'', substituting GL_ONE', [AName, AContext.Data.Name]);
  Result := GLS_SRCBLEND_ONE;
end;

class function TQ3ShaderNames.DestinationBlendMode(const AContext: TQ3ShaderContext;
  const AName: AnsiString): Cardinal;
begin
  if SameName(AName, 'GL_ONE') then
    Exit(GLS_DSTBLEND_ONE);
  if SameName(AName, 'GL_ZERO') then
    Exit(GLS_DSTBLEND_ZERO);
  if SameName(AName, 'GL_SRC_ALPHA') then
    Exit(GLS_DSTBLEND_SRC_ALPHA);
  if SameName(AName, 'GL_ONE_MINUS_SRC_ALPHA') then
    Exit(GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA);
  if SameName(AName, 'GL_DST_ALPHA') then
    Exit(GLS_DSTBLEND_DST_ALPHA);
  if SameName(AName, 'GL_ONE_MINUS_DST_ALPHA') then
    Exit(GLS_DSTBLEND_ONE_MINUS_DST_ALPHA);
  if SameName(AName, 'GL_SRC_COLOR') then
    Exit(GLS_DSTBLEND_SRC_COLOR);
  if SameName(AName, 'GL_ONE_MINUS_SRC_COLOR') then
    Exit(GLS_DSTBLEND_ONE_MINUS_SRC_COLOR);
  AContext.Warn('unknown blend mode ''%s'' in shader ''%s'', substituting GL_ONE', [AName, AContext.Data.Name]);
  Result := GLS_DSTBLEND_ONE;
end;

class function TQ3ShaderNames.GenFunc(const AContext: TQ3ShaderContext; const AName: AnsiString): TQ3GenFunc;
begin
  if SameName(AName, 'sin') then
    Exit(gfSin);
  if SameName(AName, 'square') then
    Exit(gfSquare);
  if SameName(AName, 'triangle') then
    Exit(gfTriangle);
  if SameName(AName, 'sawtooth') then
    Exit(gfSawtooth);
  if SameName(AName, 'inversesawtooth') then
    Exit(gfInverseSawtooth);
  if SameName(AName, 'noise') then
    Exit(gfNoise);
  AContext.Warn('invalid genfunc name ''%s'' in shader ''%s''', [AName, AContext.Data.Name]);
  Result := gfSin;
end;

class procedure TQ3ShaderNames.ApplySurfaceParm(const AContext: TQ3ShaderContext; const AName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(INFO_PARMS) do
    if SameName(AName, INFO_PARMS[LIndex].Name) then
    begin
      AContext.Data.SurfaceFlags := AContext.Data.SurfaceFlags or INFO_PARMS[LIndex].SurfaceFlags;
      AContext.Data.ContentFlags := AContext.Data.ContentFlags or INFO_PARMS[LIndex].Contents;
      Exit;
    end;
end;

end.
