{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the contracts                                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Automap.Types;

type
  /// <summary>
  ///   What the drawing of the automap needs to know about the window: where it is on the screen,
  ///   what part of the map it shows, and how to move points and lines between the two
  /// </summary>
  IAutomapView = interface
    ['{5B0E1C42-7A3D-4C2B-9F61-3D8E5A7B2C10}']
    function GetWindow: TAutomapWindow;
    /// <summary>A copy of the window (frame, part of the map and scales)</summary>
    property Window: TAutomapWindow read GetWindow;

    /// <summary>Where the automap is on the screen (the old f_x, f_y, f_w, f_h)</summary>
    procedure SetFrame(const AX, AY, AWidth, AHeight: Integer);
    /// <summary>A distance in the frame buffer as a distance on the map (the old FTOM)</summary>
    function FrameToMap(const AValue: Integer): Integer;
    /// <summary>A distance on the map as a distance in the frame buffer (the old MTOF)</summary>
    function MapToFrame(const AValue: Integer): Integer;
    /// <summary>The x of a point of the map in the frame buffer (the old CXMTOF)</summary>
    function MapToFrameX(const AValue: Integer): Integer;
    /// <summary>The y of a point of the map in the frame buffer (the old CYMTOF)</summary>
    function MapToFrameY(const AValue: Integer): Integer;
    /// <summary>
    ///   Cuts a line of the map to the frame and moves it to the frame buffer (the old
    ///   AM_clipMline); false when it is all outside
    /// </summary>
    function ClipLine(const AMapLine: TAutomapLine; var AFrameLine: TAutomapFrameLine): Boolean;
  end;

  /// <summary>
  ///   Moves the window of the automap: zoom, pan, follow the player, the limits of the level
  ///   and the saved place. The engine calls it from the keys and the tics.
  /// </summary>
  /// <remarks>
  ///   The coordinates of the player are the ones of the level (16.16), as the engine has them:
  ///   the navigator brings them to the units of the automap.
  /// </remarks>
  IAutomapNavigator = interface
    ['{8C41E7D9-2B5A-4F3E-A0C8-6E19D4B35F72}']
    function GetFollowPlayer: Boolean;
    procedure SetFollowPlayer(const AValue: Boolean);
    function GetPanX: TFixed;
    procedure SetPanX(const AValue: TFixed);
    function GetPanY: TFixed;
    procedure SetPanY(const AValue: TFixed);
    function GetZoomMapToFrame: TFixed;
    function GetZoomFrameToMap: TFixed;
    function GetMinScale: TFixed;
    function GetMaxScale: TFixed;

    /// <summary>Whether the window stays on the player (the old followplayer)</summary>
    property FollowPlayer: Boolean read GetFollowPlayer write SetFollowPlayer;
    /// <summary>How far the window pans each tic, in map coordinates (the old m_paninc)</summary>
    property PanX: TFixed read GetPanX write SetPanX;
    property PanY: TFixed read GetPanY write SetPanY;
    /// <summary>How much the scale map to frame changes each tic; FIXED_ONE means no zoom</summary>
    property ZoomMapToFrame: TFixed read GetZoomMapToFrame;
    /// <summary>How much the scale frame to map changes each tic</summary>
    property ZoomFrameToMap: TFixed read GetZoomFrameToMap;
    /// <summary>The scale where zooming out stops (the old min_scale_mtof)</summary>
    property MinScale: TFixed read GetMinScale;
    /// <summary>The scale where zooming in stops (the old max_scale_mtof)</summary>
    property MaxScale: TFixed read GetMaxScale;

    /// <summary>
    ///   Finds the box of all the vertices of the level and sets the limits of the zoom (the old
    ///   AM_findMinMaxBoundaries). The vertices are in the coordinates of the level and start with
    ///   x and y, AStride bytes apart (the vertices of the engine have more fields); the frame has to be
    ///   set before
    /// </summary>
    procedure FitToVertices(const AVertices: PAutomapPoint; const ACount, AStride: Integer);
    /// <summary>The scale a level starts with, from the limits (part of the old AM_LevelInit)</summary>
    procedure InitializeScale;
    /// <summary>
    ///   Puts the window back at the start of the automap: no pan, no zoom, the window centered
    ///   on the player when there is one (the old AM_initVariables)
    /// </summary>
    procedure StartWindow(const AHasPlayer: Boolean; const APlayerX, APlayerY: TFixed);
    /// <summary>Zoom in or out each tic; (FIXED_ONE, FIXED_ONE) stops it</summary>
    procedure SetZoom(const AMapToFrame, AFrameToMap: TFixed);
    /// <summary>
    ///   The tic of the automap, after the clock: follows the player, zooms and pans
    ///   (the old AM_Ticker without the clock)
    /// </summary>
    procedure Tick(const APlayerX, APlayerY: TFixed);
    /// <summary>The window follows the player each frame (done by the old AM_Drawer)</summary>
    procedure CenterOnPlayer(const APlayerX, APlayerY: TFixed);
    /// <summary>Forgets where the player was, so the next tic moves the window again</summary>
    procedure ForgetPlayerLocation;
    /// <summary>Keeps the place and the scale of the window (the old AM_saveScaleAndLoc)</summary>
    procedure SaveScaleAndLocation;
    /// <summary>Brings back the saved place and scale (the old AM_restoreScaleAndLoc)</summary>
    procedure RestoreScaleAndLocation(const APlayerX, APlayerY: TFixed);
    /// <summary>The whole level in the window (the old AM_minOutWindowScale)</summary>
    procedure MinOutWindowScale;
    /// <summary>The closest the window can get (the old AM_maxOutWindowScale)</summary>
    procedure MaxOutWindowScale;
  end;

  /// <summary>The marks the player puts on the map</summary>
  IAutomapMarks = interface
    ['{2F7A9D14-6C83-4B05-8E27-91A5C3D0B6E8}']
    function GetCount: Integer;
    function GetNextIndex: Integer;
    /// <summary>How many marks there can be (the old AM_NUMMARKPOINTS)</summary>
    property Count: Integer read GetCount;
    /// <summary>The number the next mark gets (the old markpointnum)</summary>
    property NextIndex: Integer read GetNextIndex;

    /// <summary>Puts a mark: the oldest one is replaced when all are used (the old AM_addMark)</summary>
    procedure Add(const AX, AY: TFixed);
    /// <summary>Removes all the marks (the old AM_clearMarks)</summary>
    procedure Clear;
    /// <summary>Whether the mark is on the map</summary>
    function IsUsed(const AIndex: Integer): Boolean;
    /// <summary>Where a mark is, on the map; AIndex must be in 0..Count-1</summary>
    function Point(const AIndex: Integer): TAutomapPoint;
  end;

implementation

end.
