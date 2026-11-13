{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialData                             }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.h (the data members of idMaterial, CommonInit).           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.Data;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types;

type
  /// <summary>
  ///   What the parse of a material produces: the fields of <c>idMaterial</c>. A plain data holder owned by
  ///   <c>TDeclMaterial</c>; <c>Reset</c> is <c>CommonInit</c> (the surface area, which is only for the
  ///   <c>listSurfaceAreas</c> command, is kept as the original keeps it when a material is purged).
  /// </summary>
  TMaterialData = class
  public
    Description: AnsiString;
    RenderBump: AnsiString;
    LightFalloffImageName: AnsiString;
    EntityGui: Integer;
    /// <summary>"guisurf name": a global gui; <c>GuiName</c> is its name</summary>
    HasGlobalGui: Boolean;
    GuiName: AnsiString;
    NoFog: Boolean;
    Spectrum: Integer;
    PolygonOffset: Single;
    ContentFlags: Integer;
    SurfaceFlags: Integer;
    MaterialFlags: Integer;
    DecalInfo: TMaterialDecalInfo;
    Sort: Single;
    Deform: TMaterialDeform;
    DeformRegisters: array[0..3] of Integer;
    DeformDecl: IDecl;
    TexGenRegisters: array[0..MAX_TEXGEN_REGISTERS - 1] of Integer;
    Coverage: TMaterialCoverage;
    CullType: TMaterialCullType;
    ShouldCreateBackSides: Boolean;
    FogLight: Boolean;
    BlendLight: Boolean;
    AmbientLight: Boolean;
    UnsmoothedTangents: Boolean;
    HasSubview: Boolean;
    AllowOverlays: Boolean;
    Ops: TArray<TMaterialOp>;
    /// <summary>The registers as the parse left them (constants; the predefined ones and the temporaries are 0)</summary>
    ExpressionRegisters: TArray<Single>;
    /// <summary>nil if an operation reads time, a parameter, a global or the sound</summary>
    ConstantRegisters: TArray<Single>;
    Stages: TArray<TMaterialStage>;
    NumAmbientStages: Integer;
    SurfaceArea: Single;
    EditorImageName: AnsiString;
    EditorAlpha: Single;
    SuppressInSubview: Boolean;
    PortalSky: Boolean;
    constructor Create;
    procedure Reset;
  end;

implementation

{ TMaterialData }

constructor TMaterialData.Create;
begin
  inherited Create;
  Reset;
  // we put this here instead of in Reset, because we don't want it cleared when a material is purged
  SurfaceArea := 0;
end;

procedure TMaterialData.Reset;
var
  LIndex: Integer;
begin
  Description := '<none>';
  RenderBump := '';
  LightFalloffImageName := '';
  EditorImageName := '';
  ContentFlags := CONTENTS_SOLID;
  SurfaceFlags := SURFTYPE_NONE;
  MaterialFlags := 0;
  Sort := SS_BAD;
  Coverage := TMaterialCoverage.Bad;
  CullType := TMaterialCullType.FrontSided;
  Deform := TMaterialDeform.None;
  DeformDecl := nil;
  Ops := nil;
  ExpressionRegisters := nil;
  ConstantRegisters := nil;
  Stages := nil;
  NumAmbientStages := 0;
  ShouldCreateBackSides := False;
  EntityGui := 0;
  HasGlobalGui := False;
  GuiName := '';
  FogLight := False;
  BlendLight := False;
  AmbientLight := False;
  NoFog := False;
  HasSubview := False;
  AllowOverlays := True;
  UnsmoothedTangents := False;
  for LIndex := 0 to 3 do
    DeformRegisters[LIndex] := 0;
  for LIndex := 0 to MAX_TEXGEN_REGISTERS - 1 do
    TexGenRegisters[LIndex] := 0;
  EditorAlpha := 1.0;
  Spectrum := 0;
  PolygonOffset := 0;
  SuppressInSubview := False;
  PortalSky := False;
  DecalInfo.StayTime := 10000;
  DecalInfo.FadeTime := 4000;
  for LIndex := 0 to 3 do
  begin
    DecalInfo.Start[LIndex] := 1;
    DecalInfo.Finish[LIndex] := 0;
  end;
end;

end.
