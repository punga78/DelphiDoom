{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, skin files and     }
{  the files of a player model: shared types                                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): renderer\       }
{  tr_local.h (skin_t, skinSurface_t), cgame\cg_local.h and game\bg_public.h   }
{  (team_t). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived    }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.Types;

interface

const
  /// <summary>MAX_QPATH: the paths of the original live in buffers of 64 bytes (63 characters and the NUL)</summary>
  Q3_MAX_QPATH = 64;
  /// <summary>MAX_SKINS: the skins that the renderer keeps, the default one included</summary>
  Q3_MAX_SKINS = 1024;
  /// <summary>MD3_MAX_SURFACES: the surfaces of a skin</summary>
  Q3_MD3_MAX_SURFACES = 32;
  /// <summary>DEFAULT_REDTEAM_NAME and DEFAULT_BLUETEAM_NAME of cg_local.h: the folders of the team skins</summary>
  Q3_DEFAULT_RED_TEAM_NAME = 'Stroggs';
  Q3_DEFAULT_BLUE_TEAM_NAME = 'Pagans';

type
  /// <summary>skinSurface_t: the shader of a surface of the model; the surface name is lowercase</summary>
  TQ3SkinSurface = record
    Name: AnsiString;
    /// <summary>The name of the shader, empty for the default shader</summary>
    Shader: AnsiString;
  end;

  /// <summary>team_t</summary>
  TQ3Team = (qtFree, qtRed, qtBlue, qtSpectator);

  /// <summary>
  ///   What the search of the files of a player reads from the game: if the game type is a team one
  ///   (cgs.gametype &gt;= GT_TEAM) and the team of the client (ci->team)
  /// </summary>
  TQ3TeamContext = record
    TeamGame: Boolean;
    Team: TQ3Team;
  end;

  /// <summary>
  ///   What CG_RegisterClientModelname is given: the names of the model and of the skin, the head
  ///   model (empty for the model's own, "*name" for the folder of the heads) and its skin, and the
  ///   folder of the team ("Stroggs/", or empty)
  /// </summary>
  TQ3PlayerModelRequest = record
    Context: TQ3TeamContext;
    ModelName: AnsiString;
    SkinName: AnsiString;
    HeadModelName: AnsiString;
    HeadSkinName: AnsiString;
    TeamName: AnsiString;
  end;

resourcestring
  SQ3SkinEmptyName = 'Empty name passed to RE_RegisterSkin';
  SQ3SkinNameTooLong = 'Skin name exceeds MAX_QPATH';
  SQ3SkinMaxSkins = 'WARNING: RE_RegisterSkin( ''%s'' ) MAX_SKINS hit';
  SQ3SkinTooManySurfaces = 'The skin %s has more than %d surfaces, the others are ignored';
  SQ3ModelEmptyName = 'RE_RegisterModel: NULL name';
  SQ3ModelNameTooLong = 'Model name exceeds MAX_QPATH';
  SQ3ModelNotLoaded = 'RE_RegisterModel: couldn''t load %s';
  SQ3PathOverflow = 'Com_sprintf: overflow of %d in %d';
  SQ3LegsSkinFailure = 'Leg skin load failure: %s';
  SQ3TorsoSkinFailure = 'Torso skin load failure: %s';
  SQ3HeadSkinFailure = 'Head skin load failure: %s';
  SQ3ModelFileFailure = 'Failed to load model file %s';
  SQ3SkinFileFailureTeam = 'Failed to load skin file: %s : %s : %s, %s : %s';
  SQ3SkinFileFailure = 'Failed to load skin file: %s : %s, %s : %s';
  SQ3AnimationFileFailure = 'Failed to load animation file %s';

implementation

end.
