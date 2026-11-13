{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: factory          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Intf;

type
  /// <summary>The only place that knows the classes of the BSP reader</summary>
  TBspFactory = class
  public
    /// <summary>A reader; the file system is only needed to read files by name</summary>
    class function CreateReader(const AFileSystem: IIdLibFileSystem = nil): IBspReader; static;
    class function CreateValidator: IBspValidator; static;
    /// <summary>
    ///   The loader of the patches as the engine uses it: r_subdivisions 4, stitching on
    ///   (PATCH_STITCHING is defined in tr_local.h) and an overbright shift of 1
    ///   (r_mapOverBrightBits 2, overbrightBits 1)
    /// </summary>
    class function CreatePatchLoader(const AColorShift: Integer = 1;
      const ASubdivisions: Single = 4.0; const AStitch: Boolean = True): IBspPatchLoader; static;
    class function CreatePatchStitcher: IBspPatchStitcher; static;
    class function CreateLodFixer: IBspLodFixer; static;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.LodFixer, DelphiDoom.MapFile.Bsp.PatchLoader, DelphiDoom.MapFile.Bsp.PatchStitcher,
  DelphiDoom.MapFile.Bsp.Reader, DelphiDoom.MapFile.Bsp.Validator, DelphiDoom.MathCore.Patch.Factory;

class function TBspFactory.CreateReader(const AFileSystem: IIdLibFileSystem): IBspReader;
begin
  Result := TBspReader.Create(AFileSystem);
end;

class function TBspFactory.CreateValidator: IBspValidator;
begin
  Result := TBspValidator.Create;
end;

class function TBspFactory.CreatePatchStitcher: IBspPatchStitcher;
begin
  Result := TBspPatchStitcher.Create(TPatchFactory.CreateGridEditor);
end;

class function TBspFactory.CreateLodFixer: IBspLodFixer;
begin
  Result := TBspLodFixer.Create;
end;

class function TBspFactory.CreatePatchLoader(const AColorShift: Integer; const ASubdivisions: Single;
  const AStitch: Boolean): IBspPatchLoader;
var
  LStitcher: IBspPatchStitcher;
begin
  if AStitch then
    LStitcher := CreatePatchStitcher
  else
    LStitcher := nil;
  Result := TBspPatchLoader.Create(TPatchFactory.CreateSubdivider(ASubdivisions), LStitcher,
    CreateLodFixer, AColorShift);
end;

end.
