{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the small interfaces the menu code asks for       }
{                                                                              }
{  Replaces the display context (displayContextDef_t) and the trap_PC_* calls  }
{  of Quake III Arena (ui_shared.h). Based on the Quake III Arena GPL Source   }
{  Code (id Software), GPL v2 or later.                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types;

type
  /// <summary>trap_PC_ReadToken and trap_PC_SourceFileAndLine over one open source</summary>
  IGuiTokenSource = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A11}']
    /// <summary>The next token, false at the end of the source</summary>
    function ReadToken(out AToken: TGuiToken): Boolean;
    /// <summary>The name the source was opened with</summary>
    function FileName: AnsiString;
    /// <summary>The line where the precompiler is</summary>
    function Line: Integer;
  end;

  /// <summary>trap_PC_LoadSource</summary>
  IGuiSourceLoader = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A12}']
    /// <summary>Opens a menu file; nil when it cannot be read</summary>
    function Load(const AFileName: AnsiString): IGuiTokenSource;
  end;

  /// <summary>Where Com_Printf of the menu code goes</summary>
  IGuiLog = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A13}']
    /// <summary>PC_SourceError: "ERROR: file, line n: text"</summary>
    procedure Error(const AFileName: AnsiString; const ALine: Integer; const AText: string);
    /// <summary>PC_SourceWarning</summary>
    procedure Warning(const AFileName: AnsiString; const ALine: Integer; const AText: string);
    /// <summary>A plain line ("Parsing menu file:...", "RE_RegisterFont: ...")</summary>
    procedure Info(const AText: string);
  end;

  /// <summary>
  ///   registerShaderNoMip, registerModel and registerSound of the display context: the host gives back
  ///   the handles that the model keeps. Fonts register their glyph shaders here as well
  ///   (RE_RegisterShaderNoMip).
  /// </summary>
  IGuiAssetRegistry = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A14}']
    function RegisterShader(const AName: AnsiString): Integer;
    function RegisterModel(const AName: AnsiString): Integer;
    function RegisterSound(const AName: AnsiString; const ACompressed: Boolean): Integer;
  end;

  /// <summary>The numbers a script asks of the game: the random angle of a model item</summary>
  IGuiRandom = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A15}']
    /// <summary>A number from 0 to ARange - 1 (rand() % ARange)</summary>
    function Next(const ARange: Integer): Integer;
  end;

  /// <summary>What the commands of an action script ask of the game (the parts of the display context that are not drawing)</summary>
  IGuiScriptHost = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A16}']
    /// <summary>A command that Item_RunScript does not know (DC->runScript); the arguments run up to the next ";"</summary>
    procedure RunCommand(const AItem: TObject; const ACommand: AnsiString; const AArguments: TArray<AnsiString>);
    /// <summary>open, and the choice of conditionalopen (Menus_OpenByName)</summary>
    procedure OpenMenu(const AName: AnsiString);
    /// <summary>close (Menus_CloseByName)</summary>
    procedure CloseMenu(const AName: AnsiString);
    function GetCvarValue(const AName: AnsiString): Single;
    procedure SetCvar(const AName, AValue: AnsiString);
    /// <summary>exec</summary>
    procedure ExecuteText(const AWhen: Integer; const AText: AnsiString);
    /// <summary>setteamcolor: false when the host has no team color (getTeamColor is nil)</summary>
    function GetTeamColor(out AColor: TGuiColor): Boolean;
  end;

  /// <summary>Sound and cinematics (startLocalSound, startBackgroundTrack, stopCinematic...)</summary>
  IGuiMediaHost = interface
    ['{5D2B8C0E-2C61-4E43-9F52-6B7A1D0C4A17}']
    procedure StartLocalSound(const ASound, AChannel: Integer);
    procedure StartBackgroundTrack(const AIntro, ALoop: AnsiString);
    procedure StopBackgroundTrack;
    procedure StopCinematic(const AHandle: Integer);
  end;

implementation

end.
