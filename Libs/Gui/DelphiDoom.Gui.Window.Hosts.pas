{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - the hosts of the marker and render windows        }
{                                                                              }
{  What idMarkerWindow and idRenderWindow (ui\MarkerWindow.cpp, RenderWindow.  }
{  cpp of Doom 3, id Software, GPL v3) ask of the engine: a list of files, a   }
{  scratch image, a render world and the game edit functions.                  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Hosts;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Gui.Material.Intf;

type
  /// <summary>fileSystem->ListFiles( path, ".tga", false, true ): the full names of the files of a folder</summary>
  IGuiFileLister = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F51}']
    function ListFiles(const APath, AExtension: AnsiString): TArray<AnsiString>;
  end;

  /// <summary>image->UploadScratch: the pixels (4 bytes each) of the first stage of a material</summary>
  IGuiScratchImages = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F52}']
    procedure UploadScratch(const AMaterial: IGuiMaterial; const APixels: TArray<Cardinal>; const AWidth, AHeight: Integer);
  end;

  /// <summary>renderLight_t, the part that the window sets</summary>
  TGuiRenderLight = record
    Origin: TIdVec3;
    Red: Single;
    Green: Single;
    Blue: Single;
  end;

  /// <summary>renderEntity_t, the part that the window sets: the rotation is the angles in degrees (the host makes the axis)</summary>
  TGuiRenderEntity = record
    HasModel: Boolean;
    NumJoints: Integer;
    Origin: AnsiString;
    Pitch: Single;
    Yaw: Single;
    Roll: Single;
    ModelName: AnsiString;
  end;

  /// <summary>renderView_t, the part that the window sets</summary>
  TGuiRenderView = record
    ViewOrigin: TIdVec3;
    X: Single;
    Y: Single;
    Width: Single;
    Height: Single;
    FovX: Single;
    FovY: Single;
    Time: Integer;
  end;

  /// <summary>idRenderWorld, the calls of idRenderWindow</summary>
  IGuiRenderWorld = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F53}']
    procedure InitFromMap;
    function AddLightDef(const ALight: TGuiRenderLight): Integer;
    procedure UpdateLightDef(const AHandle: Integer; const ALight: TGuiRenderLight);
    function AddEntityDef(const AEntity: TGuiRenderEntity): Integer;
    procedure UpdateEntityDef(const AHandle: Integer; const AEntity: TGuiRenderEntity);
    procedure RenderScene(const AView: TGuiRenderView);
  end;

  /// <summary>renderSystem->AllocRenderWorld and gameEdit: the world of a render window and the model and the animation of the game</summary>
  IGuiRenderHost = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F54}']
    function AllocRenderWorld: IGuiRenderWorld;
    /// <summary>ParseSpawnArgsToRenderEntity of a func_static with a model and an origin</summary>
    function ParseModelEntity(const AModelName, AOrigin: AnsiString): TGuiRenderEntity;
    /// <summary>ANIM_GetAnimFromEntityDef and ANIM_GetLength: the length of the animation, 0 if there is none</summary>
    function AnimationLength(const AAnimClass, AAnimName: AnsiString): Integer;
    /// <summary>ANIM_CreateAnimFrame at a time inside the animation</summary>
    procedure CreateAnimationFrame(const AAnimClass, AAnimName: AnsiString; const ATime: Integer);
  end;

implementation

end.