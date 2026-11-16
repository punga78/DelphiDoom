{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the drawing interface (not implemented here)      }
{                                                                              }
{  The drawing part of displayContextDef_t (ui_shared.h) of Quake III Arena    }
{  and, for the .gui of Doom 3, the part of renderSystem that                  }
{  idDeviceContext calls (SetColor, DrawStretchPic). The classes of this       }
{  library read and model menus and windows; they never draw to a screen: a    }
{  host that paints implements this interface.                                 }
{  Based on the Quake III Arena GPL Source Code (id Software), GPL v2 or later,}
{  and on the Doom 3 GPL Source Code (id Software), GPL v3 with the additional }
{  terms of the Doom 3 Source Code License.                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.DeviceContext.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Types, DelphiDoom.Gui.Material.Intf;

type
  /// <summary>One corner of the quad of a picture: the position (already transformed) and the texture coordinates</summary>
  TGuiQuadVertex = record
    Xyz: TIdVec3;
    S: Single;
    T: Single;
  end;

  /// <summary>
  ///   The four vertices of idDeviceContext::DrawStretchPic in the order of the original: upper left,
  ///   upper right, lower right, lower left (the indices are always 3, 0, 2, 2, 0, 1)
  /// </summary>
  TGuiQuad = array[0..3] of TGuiQuadVertex;

  /// <summary>
  ///   The painting calls: the display context of Quake III menus (the first group) and what the device
  ///   context of the windows of Doom 3 sends to the renderer (the second group: <c>SetColor</c> with a
  ///   vector and <c>DrawStretchPic</c>). A host implements the group it needs and leaves the methods of
  ///   the other one empty.
  /// </summary>
  IGuiDeviceContext = interface
    ['{7A41E0B5-3D18-4B0A-8E0F-52C9D6F10B21}']
    // Quake III menus
    procedure SetColor(const AColor: TGuiColor); overload;
    procedure DrawHandlePic(const ARect: TGuiRect; const AAsset: Integer);
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
    procedure DrawRect(const ARect: TGuiRect; const ASize: Single; const AColor: TGuiColor);
    procedure DrawText(const AX, AY, AScale: Single; const AColor: TGuiColor; const AText: AnsiString;
      const AAdjust: Single; const ALimit, AStyle: Integer);
    function TextWidth(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    function TextHeight(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    // Doom 3 windows (renderSystem->SetColor, renderSystem->DrawStretchPic)
    /// <summary>renderSystem->SetColor: the color of the pictures that follow</summary>
    procedure SetColor(const AColor: TIdVec4); overload;
    /// <summary>
    ///   renderSystem->DrawStretchPic(verts, indexes, 4, 6, material, transformed): <c>ATransformed</c> is
    ///   true when the device context moved the vertices with the matrix of the window (or rotated them)
    /// </summary>
    procedure DrawStretchPic(const AQuad: TGuiQuad; const AMaterial: IGuiMaterial; const ATransformed: Boolean);
  end;

implementation

end.
