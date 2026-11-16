{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - what the menu input asks of the host              }
{                                                                              }
{  The parts of displayContextDef_t (ui_shared.h, Quake III Arena, id          }
{  Software, GPL v2 or later) that the input and the stack of menus read:      }
{  the cursor, the clock, the feeders, the text cvars, the owner draw keys.    }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.Intf;

interface

type
  /// <summary>
  ///   The display context as the input code of ui_shared.c sees it (the drawing is <c>IGuiDeviceContext</c>,
  ///   the commands of a script <c>IGuiScriptHost</c>, sound and cinematics <c>IGuiMediaHost</c>)
  /// </summary>
  IGuiInputHost = interface
    ['{3C9E7A52-6D41-4F0B-8B13-0E5A2C7D9F31}']
    /// <summary>DC->cursorx</summary>
    function CursorX: Integer;
    /// <summary>DC->cursory</summary>
    function CursorY: Integer;
    /// <summary>DC->realTime (milliseconds)</summary>
    function RealTime: Integer;
    /// <summary>DC->feederCount: the number of lines of the list the feeder gives</summary>
    function FeederCount(const AFeeder: Single): Integer;
    /// <summary>DC->feederSelection</summary>
    procedure FeederSelection(const AFeeder: Single; const AIndex: Integer);
    /// <summary>DC->getCVarString (the original reads at most 1023 characters)</summary>
    function GetCvarString(const AName: AnsiString): AnsiString;
    /// <summary>DC->getOverstrikeMode</summary>
    function GetOverstrikeMode: Boolean;
    /// <summary>DC->setOverstrikeMode</summary>
    procedure SetOverstrikeMode(const AOverstrike: Boolean);
    /// <summary>DC->ownerDrawHandleKey: false when the game does not handle the key</summary>
    function OwnerDrawHandleKey(const AOwnerDraw, AFlags: Integer; var ASpecial: Single; const AKey: Integer): Boolean;
    /// <summary>DC->Pause (the game stops when no menu is visible)</summary>
    procedure Pause(const APause: Boolean);
    /// <summary>DC->Print: the slider prints "slider handle key exit" every time a key is not used</summary>
    procedure Print(const AMessage: AnsiString);
  end;

implementation

end.
