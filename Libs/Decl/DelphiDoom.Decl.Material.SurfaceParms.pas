{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialSurfaceParms                     }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (infoParms, idMaterial::CheckSurfaceParm).            }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.SurfaceParms;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The words of a material that set a surface or content bit ("solid", "water", "metal", "ladder"...):
  ///   the table <c>infoParms</c>
  /// </summary>
  TMaterialSurfaceParms = class sealed
  public
    /// <summary>
    ///   If the word is one of them (case is ignored) it changes the flags and the result is true. A surface
    ///   type replaces the one set before (only one type at a time); <c>nonsolid</c>, <c>water</c>, <c>discrete</c>,
    ///   <c>areaportal</c> and <c>qer_nocarve</c> clear CONTENTS_SOLID.
    /// </summary>
    class function Apply(const AWord: AnsiString; var ASurfaceFlags, AContentFlags: Integer): Boolean; static;
    /// <summary>The number of words in the table</summary>
    class function Count: Integer; static;
    class function WordAt(const AIndex: Integer): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Material.Types;

type
  TInfoParm = record
    Name: AnsiString;
    ClearSolid: Boolean;
    SurfaceFlags: Integer;
    Contents: Integer;
  end;

function Parm(const AName: AnsiString; const AClearSolid: Boolean; const ASurface, AContents: Integer): TInfoParm;
begin
  Result.Name := AName;
  Result.ClearSolid := AClearSolid;
  Result.SurfaceFlags := ASurface;
  Result.Contents := AContents;
end;

var
  InfoParms: TArray<TInfoParm>;

procedure BuildTable;
begin
  InfoParms := [
    // game relevant attributes
    Parm('solid', False, 0, CONTENTS_SOLID),
    Parm('water', True, 0, CONTENTS_WATER),
    Parm('playerclip', False, 0, CONTENTS_PLAYERCLIP),
    Parm('monsterclip', False, 0, CONTENTS_MONSTERCLIP),
    Parm('moveableclip', False, 0, CONTENTS_MOVEABLECLIP),
    Parm('ikclip', False, 0, CONTENTS_IKCLIP),
    Parm('blood', False, 0, CONTENTS_BLOOD),
    Parm('trigger', False, 0, CONTENTS_TRIGGER),
    Parm('aassolid', False, 0, CONTENTS_AAS_SOLID),
    Parm('aasobstacle', False, 0, CONTENTS_AAS_OBSTACLE),
    Parm('flashlight_trigger', False, 0, CONTENTS_FLASHLIGHT_TRIGGER),
    Parm('nonsolid', True, 0, 0),
    Parm('nullNormal', False, SURF_NULLNORMAL, 0),
    // utility relevant attributes
    Parm('areaportal', True, 0, CONTENTS_AREAPORTAL),
    Parm('qer_nocarve', True, 0, CONTENTS_NOCSG),
    Parm('discrete', True, SURF_DISCRETE, 0),
    Parm('noFragment', False, SURF_NOFRAGMENT, 0),
    Parm('slick', False, SURF_SLICK, 0),
    Parm('collision', False, SURF_COLLISION, 0),
    Parm('noimpact', False, SURF_NOIMPACT, 0),
    Parm('nodamage', False, SURF_NODAMAGE, 0),
    Parm('ladder', False, SURF_LADDER, 0),
    Parm('nosteps', False, SURF_NOSTEPS, 0),
    // material types for particle, sound, footstep feedback
    Parm('metal', False, SURFTYPE_METAL, 0),
    Parm('stone', False, SURFTYPE_STONE, 0),
    Parm('flesh', False, SURFTYPE_FLESH, 0),
    Parm('wood', False, SURFTYPE_WOOD, 0),
    Parm('cardboard', False, SURFTYPE_CARDBOARD, 0),
    Parm('liquid', False, SURFTYPE_LIQUID, 0),
    Parm('glass', False, SURFTYPE_GLASS, 0),
    Parm('plastic', False, SURFTYPE_PLASTIC, 0),
    Parm('ricochet', False, SURFTYPE_RICOCHET, 0),
    // unassigned surface types
    Parm('surftype10', False, SURFTYPE_10, 0),
    Parm('surftype11', False, SURFTYPE_11, 0),
    Parm('surftype12', False, SURFTYPE_12, 0),
    Parm('surftype13', False, SURFTYPE_13, 0),
    Parm('surftype14', False, SURFTYPE_14, 0),
    Parm('surftype15', False, SURFTYPE_15, 0)
  ];
end;

{ TMaterialSurfaceParms }

class function TMaterialSurfaceParms.Apply(const AWord: AnsiString; var ASurfaceFlags,
  AContentFlags: Integer): Boolean;
var
  LParm: TInfoParm;
begin
  for LParm in InfoParms do
    if TIdStrings.Icmp(AWord, LParm.Name) = 0 then
    begin
      if (LParm.SurfaceFlags and SURF_TYPE_MASK) <> 0 then
        // ensure we only have one surface type set
        ASurfaceFlags := ASurfaceFlags and not SURF_TYPE_MASK;
      ASurfaceFlags := ASurfaceFlags or LParm.SurfaceFlags;
      AContentFlags := AContentFlags or LParm.Contents;
      if LParm.ClearSolid then
        AContentFlags := AContentFlags and not CONTENTS_SOLID;
      Exit(True);
    end;
  Result := False;
end;

class function TMaterialSurfaceParms.Count: Integer;
begin
  Result := Length(InfoParms);
end;

class function TMaterialSurfaceParms.WordAt(const AIndex: Integer): AnsiString;
begin
  Result := InfoParms[AIndex].Name;
end;

initialization
  BuildTable;

end.
