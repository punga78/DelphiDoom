{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - the interfaces of the windows of Doom 3           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.WinVar.Base;

type
  IGuiGameHost = interface;

  /// <summary>
  ///   A window as the scripts, the expressions and the other windows see it. The implementations are not
  ///   reference counted: the parent window (or the user interface, for the desktop) owns and frees them.
  /// </summary>
  IGuiWindowNode = interface
    ['{7A2E91C4-35D8-4B6F-A0E1-2C9D4F8B6E11}']
    function GetName: AnsiString;
    function GetSourceFile: AnsiString;
    function GetParent: IGuiWindowNode;
    procedure SetFlag(const AFlag: Cardinal);
    procedure ClearFlag(const AFlag: Cardinal);
    function GetCommand: AnsiString;
    procedure SetCommand(const AValue: AnsiString);
    /// <summary>AddCommand: appends to the command text, separated by " ; "</summary>
    procedure AddCommand(const ACommand: AnsiString);
    function HasOps: Boolean;
    function EvalRegs(const ATest: Integer = -1; const AForce: Boolean = False): Single;
    /// <summary>
    ///   GetWinVarByName; <c>AOwner</c> is the window that holds the variable (nil if it has no parent, or the
    ///   variable was not found)
    /// </summary>
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean; out AOwner: IGuiWindowNode): TGuiWinVar;
    /// <summary>The "rect" variable of the window (a simple window answers to the same names as a window)</summary>
    function GetRectVar: TGuiWinVar;
    procedure InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
    procedure AddDefinedVar(const AVar: TGuiWinVar);
    function GetDesktop: IGuiWindowNode;
    /// <summary>FindChildByName on this window; <c>AIsSimple</c> if it is a simple window (no scripts, no children)</summary>
    function FindChildByName(const AName: AnsiString; out AIsSimple: Boolean): IGuiWindowNode;
    procedure SetFocus(const AWindow: IGuiWindowNode);
    procedure ResetTime(const ATime: Integer);
    procedure ResetCinematics;
    procedure AddTransition(const AVariable: TGuiWinVar; const AFrom, ATo: TIdVec4; const ATime: Integer;
      const AAccelTime, ADecelTime: Single);
    procedure StartTransition;
    procedure ClientToScreen(var ARect: TGuiRectangle);
    procedure ScreenToClient(var ARect: TGuiRectangle);
    procedure Warning(const AText: string);
    /// <summary>The game side of the scripts (nil if the gui has none)</summary>
    function GetGameHost: IGuiGameHost;
    function TranslateString(const AText: AnsiString): AnsiString;
  end;

  /// <summary>What the scripts ask of the game (<c>session->sw->PlayShaderDirectly</c>, <c>endGame</c>)</summary>
  IGuiGameHost = interface
    ['{7A2E91C4-35D8-4B6F-A0E1-2C9D4F8B6E12}']
    procedure LocalSound(const AName: AnsiString);
    /// <summary>Script_EndGame: set g_nightmare and disconnect</summary>
    procedure EndGame;
    /// <summary>The background of a window starts its cinematic again at the time</summary>
    procedure ResetCinematic(const ABackground: AnsiString; const ATime: Integer);
  end;

  /// <summary><c>dc->FindFont</c>: the number of a font by name</summary>
  IGuiFontLookup = interface
    ['{7A2E91C4-35D8-4B6F-A0E1-2C9D4F8B6E13}']
    function FindFont(const AName: AnsiString): Integer;
  end;

implementation

end.
