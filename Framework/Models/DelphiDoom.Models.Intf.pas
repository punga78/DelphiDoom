{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the contracts                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types;

type
  /// <summary>
  ///   The data of an MD2 model, ready to draw: for every frame the vertexes of all the triangles
  ///   (three for each, already in the axis order of the renderer), and the texture points that are
  ///   the same for all the frames. The frames with the same name (without the number at the end)
  ///   make a group: the animation of the model (STAND, RUN...).
  /// </summary>
  IMd2Model = interface
    ['{E2C41B87-5D3A-4A19-8F60-1B7D9A0C3E55}']
    function GetFrameCount: Integer;
    /// <summary>Vertexes of every frame: three for each triangle</summary>
    function GetVertexCount: Integer;
    /// <summary>
    ///   The first vertex of a frame. The memory belongs to the model and stays valid as long as
    ///   the model lives and is not merged with another one
    /// </summary>
    function GetFrameVertices(const AFrame: Integer): PModelVertex;
    /// <summary>The first texture point (there is one for each vertex)</summary>
    function GetTexCoords: PModelTexCoord;
    function GetGroupCount: Integer;
    /// <summary>The name of a group of frames, in capital letters, without the number</summary>
    function GetGroupName(const AIndex: Integer): string;
    /// <summary>The first frame of a group, or -1 if the group does not exist</summary>
    function GetGroupStartFrame(const AIndex: Integer): Integer;
    /// <summary>The last frame of a group, or -1 if the group does not exist</summary>
    function GetGroupEndFrame(const AIndex: Integer): Integer;
    /// <summary>The index of a group by name (the case does not count), or -1</summary>
    function FindGroup(const AName: string): Integer;
    /// <summary>
    ///   Puts the frames of another model after the ones of this: the animations of a model made
    ///   of more files. False, and nothing changes, if the models do not have the same number of
    ///   vertexes
    /// </summary>
    function MergeFrames(const AOther: IMd2Model): Boolean;
    property FrameCount: Integer read GetFrameCount;
    property VertexCount: Integer read GetVertexCount;
    property GroupCount: Integer read GetGroupCount;
  end;

  /// <summary>Reads the bytes of an MD2 file</summary>
  IMd2Parser = interface
    ['{A93F5D12-7C0B-4E48-B2D6-4F8A1E6C9B07}']
    /// <summary>
    ///   Makes the model from the bytes of the file. The placement is applied to the vertexes, in
    ///   Quake axis order (x forward, y left, z up): the model gets the order of the renderer
    ///   (the old x, y, z become z, x, y). Raises EModelsException if the file is not a valid MD2
    ///   (too short, wrong magic, offsets or indexes outside the file).
    /// </summary>
    function Parse(const ABytes: TBytes; const APlacement: TModelPlacement): IMd2Model;
  end;

  /// <summary>
  ///   Where a procedural model is drawn: a call for each command of the model. The renderer
  ///   gives the real calls (OpenGL), a test gives a recorder.
  /// </summary>
  IModelRenderer = interface
    ['{5D8E2A41-B3F6-4C07-9A15-E0C7D4B28F93}']
    procedure BeginPrimitive(const AMode: Integer);
    procedure EndPrimitive;
    procedure TexCoord2f(const AU, AV: Single);
    procedure Vertex3f(const AX, AY, AZ: Single);
    procedure Color3f(const AR, AG, AB: Single);
    procedure Color4f(const AR, AG, AB, AA: Single);
    procedure Normal3f(const ANX, ANY, ANZ: Single);
    procedure MatrixMode(const AMode: Integer);
    procedure PushMatrix;
    procedure PopMatrix;
    procedure Translatef(const AX, AY, AZ: Single);
    procedure Rotatef(const AAngle, AX, AY, AZ: Single);
    procedure LoadIdentity;
    procedure Scalef(const AX, AY, AZ: Single);
  end;

  /// <summary>
  ///   The commands of a procedural model (the old TDDModelLoader without the script and the
  ///   drawing): a list of commands, each one for a frame. A script fills the list through
  ///   AddCommand (the engine runs the script), a binary model (DMX) gives it back in one piece.
  /// </summary>
  IModelCommandStream = interface
    ['{C61A9E03-4B72-4D58-A0F4-8E5B3D17C264}']
    function GetCommandCount: Integer;
    function GetCommand(const AIndex: Integer): TModelCommand;
    function GetCurrentFrame: Integer;
    procedure SetCurrentFrame(const AValue: Integer);
    function GetMaxRecursionDepth: Integer;
    procedure SetMaxRecursionDepth(const AValue: Integer);
    function GetFrameCount: Integer;
    /// <summary>The frame number at a position of the sorted list of frames</summary>
    function GetFrame(const AIndex: Integer): Integer;
    /// <summary>Empties the list of commands and goes back to the frame 0</summary>
    procedure Clear;
    /// <summary>
    ///   Adds a command to the current frame. The parameters not used are 0. Call
    ///   IdentifyFrames when the script is over
    /// </summary>
    procedure AddCommand(const ACommand: Integer; const AParam0: Single = 0.0;
      const AParam1: Single = 0.0; const AParam2: Single = 0.0; const AParam3: Single = 0.0);
    /// <summary>
    ///   Makes the sorted list of the frames that the commands use (the frame of each command
    ///   and the frames they call)
    /// </summary>
    procedure IdentifyFrames;
    /// <summary>The position of a frame number in the sorted list of frames, or -1</summary>
    function IndexOfFrame(const AFrame: Integer): Integer;
    /// <summary>
    ///   Takes the commands of a binary model (DMX) and finds the frames. False, and nothing
    ///   changes, if the bytes are not a DMX model (wrong number, negative size); raises
    ///   EModelsException if the bytes are shorter than the commands they say. As in the old
    ///   AppendFromStream (a defect that is kept), the commands that were in the list are
    ///   replaced, not followed.
    /// </summary>
    function LoadFromBytes(const ABytes: TBytes): Boolean;
    /// <summary>The binary model (DMX) of the commands</summary>
    function SaveToBytes: TBytes;
    /// <summary>
    ///   Sends the commands of a frame to the renderer, in the order they were added; a frame can
    ///   call another (up to MaxRecursionDepth deep, never a frame that is already being drawn)
    /// </summary>
    procedure Play(const AFrame: Integer; const ARenderer: IModelRenderer);
    property CommandCount: Integer read GetCommandCount;
    property Commands[const AIndex: Integer]: TModelCommand read GetCommand;
    property CurrentFrame: Integer read GetCurrentFrame write SetCurrentFrame;
    property MaxRecursionDepth: Integer read GetMaxRecursionDepth write SetMaxRecursionDepth;
    property FrameCount: Integer read GetFrameCount;
    property Frames[const AIndex: Integer]: Integer read GetFrame;
  end;

implementation

end.
