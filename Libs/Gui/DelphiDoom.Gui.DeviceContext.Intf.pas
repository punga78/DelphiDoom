{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the drawing interface (not implemented here)      }
{                                                                              }
{  The drawing part of displayContextDef_t (ui_shared.h) of Quake III Arena.   }
{  The classes of this library read and model menus; they never draw: a host   }
{  that paints implements this interface. A GUI of another engine (idUserInter-}
{  face of Doom 3) can use the same interface for its own window painting.     }
{  Based on the Quake III Arena GPL Source Code (id Software), GPL v2 or later.}
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.DeviceContext.Intf;

interface

uses
  DelphiDoom.Gui.Types;

type
  /// <summary>The painting calls of a display context; nothing in Libs\Gui implements or calls them yet</summary>
  IGuiDeviceContext = interface
    ['{7A41E0B5-3D18-4B0A-8E0F-52C9D6F10B21}']
    procedure SetColor(const AColor: TGuiColor);
    procedure DrawHandlePic(const ARect: TGuiRect; const AAsset: Integer);
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
    procedure DrawRect(const ARect: TGuiRect; const ASize: Single; const AColor: TGuiColor);
    procedure DrawText(const AX, AY, AScale: Single; const AColor: TGuiColor; const AText: AnsiString;
      const AAdjust: Single; const ALimit, AStyle: Integer);
    function TextWidth(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    function TextHeight(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
  end;

implementation

end.
