{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the contract of the .aas reader              }
{                                                                              }
{  Written for this library (the original loads the file in idAASFileLocal).   }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Intf;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.AasFile,
  DelphiDoom.MapFile.Aas.Trace;

type
  /// <summary>Turns the text of an .aas file into the model. The caller owns the file that is returned</summary>
  IAasFileReader = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B621}']
    /// <summary>
    ///   Reads the file with the name given (the extension is part of the name: "aas48", "aas32"
    ///   or whatever the settings say). nil if there is no file. With a <c>ACrc</c> other than 0
    ///   the CRC of the map in the file must be the same, or EAasFileOutOfDateException is raised
    ///   (idAASFileLocal::Load returns false and warns). A text that is not valid raises
    ///   EAasFileException
    /// </summary>
    function Parse(const AFileName: AnsiString; const ACrc: Cardinal = 0): TAasFile;
    /// <summary>Reads a text that is already in memory; the name is only used in the messages</summary>
    function ParseText(const AText, AName: AnsiString; const ACrc: Cardinal = 0): TAasFile;
  end;

  /// <summary>
  ///   The queries of idAASFileLocal on a file that is loaded (AASFile_sample.cpp): which area a
  ///   point is in, the closest reachable area, a trace through the tree. It does not change the
  ///   file
  /// </summary>
  IAasSampler = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B623}']
    /// <summary>The area of a point; 0 if it is in solid</summary>
    function PointAreaNum(const AOrigin: TGeoVec3): Integer;
    /// <summary>
    ///   The area of the point, or if it is not suitable the closest one with the flags wanted
    ///   (<c>AAreaFlags</c>) and none of the travel flags excluded; 0 if there is none
    /// </summary>
    function PointReachableAreaNum(const AOrigin: TGeoVec3; const ASearchBounds: TGeoBounds;
      const AAreaFlags, AExcludeTravelFlags: Integer): Integer;
    function BoundsReachableAreaNum(const ABounds: TGeoBounds; const AAreaFlags,
      AExcludeTravelFlags: Integer): Integer;
    /// <summary>Moves the point to the front side of every face plane of the area</summary>
    procedure PushPointIntoAreaNum(const AAreaNum: Integer; var APoint: TGeoVec3);
    /// <summary>
    ///   The point where a bot goes to reach the area: the centre of the floor faces dropped on
    ///   the floor, or the centre of the area if it is not reachable by walking or flying
    /// </summary>
    function AreaReachableGoal(const AAreaNum: Integer): TGeoVec3;
    /// <summary>
    ///   Traces a line through the tree (idAASFileLocal::Trace). True if the trace was stopped
    ///   by an area it cannot enter or by solid; the answer is in <c>ATrace</c>
    /// </summary>
    function Trace(var ATrace: TAasTrace; const AStart, AEnd: TGeoVec3): Boolean;
  end;

  /// <summary>Turns the model into the text of an .aas file, in the format of the AAS compiler</summary>
  IAasFileWriter = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B622}']
    /// <summary>
    ///   Writes the file under the name given (idAASFileLocal::Write; the name is not changed to
    ///   have the extension of the settings) and gives it that name and that CRC. The file
    ///   system that cannot open the file is an EAasFileException, as <c>common->Error</c> is
    ///   in the original
    /// </summary>
    function Write(const AFile: TAasFile; const AFileName: AnsiString; const ACrc: Cardinal): Boolean;
    /// <summary>The text that Write would write</summary>
    function ToText(const AFile: TAasFile; const ACrc: Cardinal): AnsiString;
  end;

implementation

end.
