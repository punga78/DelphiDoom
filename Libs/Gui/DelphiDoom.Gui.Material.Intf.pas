{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - the material as the windows of a .gui see it      }
{                                                                              }
{  The part of idMaterial and idDeclManager::FindMaterial that ui\*.cpp of     }
{  Doom 3 calls (id Software, GPL v3). The materials themselves are Libs\Decl  }
{  or the renderer: an adapter implements these two interfaces.                }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Material.Intf;

interface

type
  /// <summary>
  ///   What a window asks of a material: the size of its first image (a natural scale and the thumb of
  ///   a slider), its cinematic, and the marks the gui puts on it. Not reference counted by the gui: the
  ///   lookup keeps the materials alive.
  /// </summary>
  IGuiMaterial = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F21}']
    /// <summary>The name the material was found with (what the recorder of a test prints)</summary>
    function GetName: AnsiString;
    /// <summary>idMaterial::GetImageWidth</summary>
    function GetImageWidth: Integer;
    /// <summary>idMaterial::GetImageHeight</summary>
    function GetImageHeight: Integer;
    /// <summary>idMaterial::CinematicLength: 0 if the material has no cinematic</summary>
    function GetCinematicLength: Integer;
    /// <summary>idMaterial::UpdateCinematic: the cinematic moves to the time</summary>
    procedure UpdateCinematic(const ATime: Integer);
    /// <summary>idMaterial::ResetCinematicTime</summary>
    procedure ResetCinematicTime(const ATime: Integer);
    /// <summary>idMaterial::TestMaterialFlag(MF_DEFAULTED): the image was not found and the default one is used</summary>
    function IsDefaulted: Boolean;
    /// <summary>SetSort(SS_GUI): the material is drawn in the gui pass</summary>
    procedure SetGuiSort;
  end;

  /// <summary>declManager->FindMaterial(name): never nil (a missing material is the default one)</summary>
  IGuiMaterialLookup = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F22}']
    function FindMaterial(const AName: AnsiString): IGuiMaterial;
  end;

implementation

end.
