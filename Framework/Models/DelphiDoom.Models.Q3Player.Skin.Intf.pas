{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, skin files and     }
{  the files of a player model: contracts                                      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): renderer\       }
{  tr_image.c (RE_RegisterSkin), renderer\tr_model.c, renderer\tr_mesh.c and   }
{  cgame\cg_players.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types;

type
  /// <summary>skin_t: the shader of each surface of a model, by the (lowercase) name of the surface</summary>
  IQ3Skin = interface
    ['{3A7D5C19-E804-4B62-9F31-C60B1D8A7E25}']
    function GetName: AnsiString;
    function GetSurfaceCount: Integer;
    function GetSurface(const AIndex: Integer): TQ3SkinSurface;
    /// <summary>The game path of the skin, with the extension</summary>
    property Name: AnsiString read GetName;
    property SurfaceCount: Integer read GetSurfaceCount;
    property Surfaces[const AIndex: Integer]: TQ3SkinSurface read GetSurface;
    /// <summary>The first surface with exactly that name (strcmp); False if there is none</summary>
    function FindShader(const ASurfaceName: AnsiString; out AShader: AnsiString): Boolean;
  end;

  /// <summary>The text of a .skin file (the loop of RE_RegisterSkin) as a skin</summary>
  IQ3SkinParser = interface
    ['{91E2B64F-0D3A-4C78-A5B9-2F7E8C1D4A60}']
    /// <summary>nil when the file names no surface (the original then uses the default skin)</summary>
    function Parse(const AName, AText: AnsiString): IQ3Skin;
  end;

  /// <summary>RE_RegisterSkin and R_GetSkinByHandle: the skins of the renderer, by handle</summary>
  IQ3SkinRegistry = interface
    ['{C5F09A3E-6B21-47D8-8E14-D93A7B0F2C56}']
    function GetSkinCount: Integer;
    /// <summary>tr.numSkins: the default skin and the ones registered, the failed ones too</summary>
    property SkinCount: Integer read GetSkinCount;
    /// <summary>The handle of the skin, 0 (the default skin) if the name is wrong or the file gives no surface</summary>
    function RegisterSkin(const AName: AnsiString): Integer;
    /// <summary>The skin of a handle; the default skin for 0 or a handle that does not exist</summary>
    function GetSkin(const AHandle: Integer): IQ3Skin;
  end;

  /// <summary>trap_FS_FOpenFile of CG_FileExists: the length of a file</summary>
  IQ3FileProbe = interface
    ['{0B8E3D72-A94C-4F15-B6D0-5E1C7A29F483}']
    /// <summary>The bytes of the file, a negative number if it does not exist</summary>
    function FileLength(const AFileName: string): Integer;
  end;

  /// <summary>CG_FindClientModelFile and CG_FindClientHeadFile: the file of a skin or an icon of a player</summary>
  IQ3PlayerFileFinder = interface
    ['{6D4A1F98-3C07-4E52-A8B6-F20E9D5C7B31}']
    /// <summary>
    ///   The body parts (base "lower", "upper"): AFileName is the file found; if there is none it is
    ///   the last name tried, as the buffer of the original
    /// </summary>
    function FindModelFile(const AContext: TQ3TeamContext; const ATeamName, AModelName, ASkinName,
      ABase, AExtension: AnsiString; out AFileName: AnsiString): Boolean;
    /// <summary>The head (base "head", "icon"); a head model starting with "*" is in the folder of the heads</summary>
    function FindHeadFile(const AContext: TQ3TeamContext; const ATeamName, AHeadModelName,
      AHeadSkinName, ABase, AExtension: AnsiString; out AFileName: AnsiString): Boolean;
  end;

  /// <summary>RE_RegisterModel of an MD3: the model of a file, nil if there is none</summary>
  IQ3ModelSource = interface
    ['{F2C61B85-9E40-4D37-A1B8-0C5D3E7A9246}']
    function RegisterModel(const AFileName: AnsiString): IMd3Model;
  end;

  /// <summary>R_AddMD3Surfaces: the shader of every surface of a model</summary>
  IQ3SkinShaderResolver = interface
    ['{47B9E0D3-1A5F-4C86-93E7-8D2B6F0C1A54}']
    /// <summary>
    ///   One name for each surface of the model, empty for the default shader. With a skin the
    ///   shader is the one of the surface of the same name; without it (the handle was 0) the shader
    ///   of the model at ASkinNumber mod the shaders of the surface. A negative skin number raises
    ///   EArgumentOutOfRangeException.
    /// </summary>
    function Resolve(const AModel: IMd3Model; const ASkin: IQ3Skin; const ASkinNumber: Integer): TArray<AnsiString>;
  end;

  /// <summary>The parts of a player as CG_RegisterClientModelname leaves them in the clientInfo_t</summary>
  IQ3PlayerModel = interface
    ['{B1D75E02-8F36-4A49-9C61-E7A04F3D2B85}']
    function GetLegsModel: IMd3Model;
    function GetTorsoModel: IMd3Model;
    function GetHeadModel: IMd3Model;
    function GetLegsSkin: IQ3Skin;
    function GetTorsoSkin: IQ3Skin;
    function GetHeadSkin: IQ3Skin;
    function GetAnimation: IQ3AnimationConfig;
    function GetIconFile: AnsiString;
    property LegsModel: IMd3Model read GetLegsModel;
    property TorsoModel: IMd3Model read GetTorsoModel;
    property HeadModel: IMd3Model read GetHeadModel;
    property LegsSkin: IQ3Skin read GetLegsSkin;
    property TorsoSkin: IQ3Skin read GetTorsoSkin;
    property HeadSkin: IQ3Skin read GetHeadSkin;
    property Animation: IQ3AnimationConfig read GetAnimation;
    /// <summary>The file of the icon of the model</summary>
    property IconFile: AnsiString read GetIconFile;
  end;

  /// <summary>CG_RegisterClientModelname</summary>
  IQ3PlayerModelLoader = interface
    ['{5E83C7A1-D92B-4F60-B418-A06D1C9E3F72}']
    /// <summary>
    ///   False (with the warnings of the original in the log) when a file is missing; a malformed
    ///   animation.cfg raises EQ3PlayerException, which is a fatal error in the game
    /// </summary>
    function Load(const ARequest: TQ3PlayerModelRequest; out AModel: IQ3PlayerModel): Boolean;
  end;

implementation

end.
