{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: MD3 (Quake 3), contracts     }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md3.cpp,  }
{  renderer\Model_local.h. Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. This unit is derived from the Doom 3 GPL source code and is  }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Md3.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Md3.Types;

type
  /// <summary>
  ///   An MD3 model as the file has it (idRenderModelMD3): frames, tags and surfaces with the
  ///   vertexes of every frame, and the instance for a frame or between two frames
  /// </summary>
  IMd3Model = interface
    ['{5D2B8F10-7A43-4E96-B1C7-3F8A0E6D9C52}']
    function GetName: string;
    function GetNumFrames: Integer;
    function GetNumTags: Integer;
    function GetNumSurfaces: Integer;
    function GetFrame(const AIndex: Integer): TMd3Frame;
    function GetTag(const AFrame, ATag: Integer): TMd3Tag;
    function GetSurface(const AIndex: Integer): TMd3Surface;
    property Name: string read GetName;
    property NumFrames: Integer read GetNumFrames;
    /// <summary>The tags of every frame</summary>
    property NumTags: Integer read GetNumTags;
    property NumSurfaces: Integer read GetNumSurfaces;
    property Frames[const AIndex: Integer]: TMd3Frame read GetFrame;
    /// <summary>The tag ATag of the frame AFrame</summary>
    property Tags[const AFrame, ATag: Integer]: TMd3Tag read GetTag;
    property Surfaces[const AIndex: Integer]: TMd3Surface read GetSurface;
    /// <summary>idRenderModelMD3::Bounds with an entity: the box of the first frame</summary>
    function Bounds: TGeoBounds;
    /// <summary>
    ///   idRenderModelMD3::InstantiateDynamicModel: a static model with the vertexes of AFrame, or
    ///   the interpolation between AOldFrame and AFrame by ABackLerp (the weight of the old
    ///   frame, 0 for none): the position is xyz * (1/64); texture coordinates and indexes as in
    ///   the file; the normals and tangents are not computed (as in the original).
    /// </summary>
    function Instantiate(const AFrame, AOldFrame: Integer; const ABackLerp: Single): IStaticModel;
  end;

  /// <summary>Reads the bytes of an .md3 file into a model with all its frames</summary>
  IMd3Reader = interface
    ['{C47E91A8-2B3D-4F56-8E10-6A9D5B2C7F83}']
    /// <summary>Raises EStaticModelException when the file cannot be read</summary>
    function Read(const AData: TBytes; const AName: string): IMd3Model;
  end;

implementation

end.
