{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWindow, a window of a .gui of Doom 3          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.h, Window.cpp    }
{  (idWindow) and the data of ui\SimpleWindow.h (a window without scripts,     }
{  children or operations is "simple": see IsSimple). Copyright (C)            }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Scanner.IdParser,
  DelphiDoom.Gui.UncountedObject, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Float,
  DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.WinVar.Background, DelphiDoom.Gui.WinVar.Vec4,
  DelphiDoom.Gui.WinVar.Rectangle, DelphiDoom.Gui.Regs.Types, DelphiDoom.Gui.Regs.Intf,
  DelphiDoom.Gui.Regs.Store, DelphiDoom.Gui.Regs.RegisterList, DelphiDoom.Gui.Regs.Evaluator,
  DelphiDoom.Gui.Regs.Parser, DelphiDoom.Gui.Script, DelphiDoom.Gui.Script.Parser,
  DelphiDoom.Gui.Window.TimeLineEvent, DelphiDoom.Gui.Window.NamedEvent, DelphiDoom.Gui.Window.Transition;

type
  TGuiWindow = class;

  /// <summary>
  ///   Makes the window of a keyword (<c>editDef</c>, <c>choiceDef</c>...) or nil if there is none. The
  ///   <c>windowDef</c> is always a <c>TGuiWindow</c>; the composition root gives the creator that knows the rest.
  /// </summary>
  TGuiWindowCreator = reference to function(const AKeyword: AnsiString): TGuiWindow;

  /// <summary>drawWin_t: a window that is drawn, and whether it is a "simple" one (not a child that gets events)</summary>
  TGuiDrawWindow = record
    Window: TGuiWindow;
    IsSimple: Boolean;
  end;

  /// <summary>
  ///   idWindow: the state of a window (rectangle, colors, text, flags), its variables and registers, its
  ///   scripts, time line and transitions, and its child windows. It reads the window from the text of a
  ///   .gui (<c>Parse</c>), resolves the names after the parse (<c>FixupParms</c>) and runs the time of the
  ///   window (<c>RunTimeEvents</c>) without drawing. Not ported: drawing, mouse and keyboard
  ///   (<c>HandleEvent</c>, <c>Redraw</c>, focus and capture routing), the save game and demo files,
  ///   the gui editor, materials and cinematics (the background is its name), cvars.
  ///   A window that is "simple" in the original (a copy kept as <c>idSimpleWindow</c>) is kept as a window
  ///   in <c>DrawWindows</c> with <c>IsSimple</c> set; it is not a child. The window owns its children.
  /// </summary>
  TGuiWindow = class(TGuiUncountedObject, IGuiWindowNode, IGuiRegisterOwner, IGuiExpressionHost)
  strict private
    FContext: TGuiContext;
    FCreator: TGuiWindowCreator;
    FParent: TGuiWindow;
    FChildren: TList<TGuiWindow>;
    FOwned: TObjectList<TGuiWindow>;
    FDrawWindows: TList<TGuiDrawWindow>;
    FFocusedChild: TGuiWindow;
    FCaptureChild: TGuiWindow;
    FFlags: Cardinal;
    FChildId: Integer;
    FLastTimeRun: Integer;
    FTimeLine: Integer;
    FName: AnsiString;
    FComment: AnsiString;
    FCommand: AnsiString;
    FDrawRect: TGuiRectangle;
    FClientRect: TGuiRectangle;
    FTextRect: TGuiRectangle;
    FOrigin: TIdVec2;
    FShear: TIdVec2;
    FXOffset: Single;
    FYOffset: Single;
    FForceAspectWidth: Single;
    FForceAspectHeight: Single;
    FMatScaleX: Single;
    FMatScaleY: Single;
    FBorderSize: Single;
    FTextAlignX: Single;
    FTextAlignY: Single;
    FTextShadow: Integer;
    FFontNum: Integer;
    FCursor: Integer;
    FTextAlign: Integer;
    FNoTime: TGuiWinBool;
    FVisible: TGuiWinBool;
    FNoEvents: TGuiWinBool;
    FHideCursor: TGuiWinBool;
    FRect: TGuiWinRectangle;
    FBackColor: TGuiWinVec4;
    FMatColor: TGuiWinVec4;
    FForeColor: TGuiWinVec4;
    FHoverColor: TGuiWinVec4;
    FBorderColor: TGuiWinVec4;
    FTextScale: TGuiWinFloat;
    FRotate: TGuiWinFloat;
    FText: TGuiWinStr;
    FBackgroundName: TGuiWinBackground;
    FDefinedVars: TObjectList<TGuiWinVar>;
    FUpdateVars: TList<TGuiWinVar>;
    FScripts: array[TGuiScriptEvent] of TGuiScriptList;
    FTimeLineEvents: TObjectList<TGuiTimeLineEvent>;
    FNamedEvents: TObjectList<TGuiNamedEvent>;
    FTransitions: TObjectList<TGuiTransition>;
    FStore: TGuiExpressionStore;
    FRegList: TGuiRegisterList;
    FEvaluator: TGuiExpressionEvaluator;
    FExpressionParser: TGuiExpressionParser;
    FScriptParser: TGuiScriptParser;
    procedure CommonInit;
    procedure ParseWindowDef(const ASource: TIdParser; const ARebuild: Boolean; const AIsAnimation: Boolean);
    procedure AdoptSimple(const AWindow: TGuiWindow);
    procedure ParseKeywordWindow(const ASource: TIdParser; const ARebuild: Boolean; const AWindow: TGuiWindow);
    function ParseScriptEntry(const AName: AnsiString; const ASource: TIdParser): Boolean;
    function ParseRegEntry(const AName: AnsiString; const ASource: TIdParser): Boolean;
    procedure ParseDefineFloat(const ASource: TIdParser);
    procedure ParseDefineVec4(const ASource: TIdParser);
    procedure ParseOnTime(const ASource: TIdParser; var AOk: Boolean);
    procedure ParseOnNamedEvent(const ASource: TIdParser; var AOk: Boolean);
    procedure DisableRegister(const AName: AnsiString);
    procedure UpdateWinVars;
    procedure Transition;
    procedure Time;
    function GetSimpleWinVarByName(const AName: AnsiString): TGuiWinVar;
    function HostGetWinVarByName(const AName: AnsiString; const AFixup: Boolean): TGuiWinVar;
    function NodeFindChildByName(const AName: AnsiString; out AIsSimple: Boolean): IGuiWindowNode;
    procedure NodeSetFocus(const AWindow: IGuiWindowNode);
    function GetChildCount: Integer;
    function GetChildren(const AIndex: Integer): TGuiWindow;
    function GetDrawWindowCount: Integer;
    function GetDrawWindows(const AIndex: Integer): TGuiDrawWindow;
    function GetScripts(const AEvent: TGuiScriptEvent): TGuiScriptList;
    function GetTimeLineEventCount: Integer;
    function GetTimeLineEvents(const AIndex: Integer): TGuiTimeLineEvent;
    function GetNamedEventCount: Integer;
    function GetTransitionCount: Integer;
    function GetUpdateVarCount: Integer;
    function GetDefinedVarCount: Integer;
    function GetDefinedVars(const AIndex: Integer): TGuiWinVar;
    function GetDesktopWindow: TGuiWindow;
    function GetSourceFile: AnsiString;
    function GetGameHost: IGuiGameHost;
    function GetParentNode: IGuiWindowNode;
    function GetName: AnsiString;
    function GetCommand: AnsiString;
    procedure SetCommand(const AValue: AnsiString);
    function GetRectVar: TGuiWinVar;
    function GetDesktop: IGuiWindowNode;
    function GetStore: TGuiExpressionStore;
  protected
    property Context: TGuiContext read FContext;
    /// <summary>idWindow::ParseInternalVar: the keys that are not registers; the subclasses add their own</summary>
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; virtual;
    /// <summary>idWindow::PostParse: the subclasses finish their state here</summary>
    procedure PostParse; virtual;
    procedure ParseString(const ASource: TIdParser; var AOutput: AnsiString);
    procedure ParseVec4(const ASource: TIdParser; var AOutput: TIdVec4);
    procedure AddDefinedVarOwned(const AVariable: TGuiWinVar);
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); virtual;
    destructor Destroy; override;
    /// <summary>
    ///   idWindow::Parse: the window from the name after the keyword to the closing brace. False if the
    ///   text is wrong (the parser has reported it). <c>ARebuild</c> clears the window first.
    /// </summary>
    function Parse(const ASource: TIdParser; const ARebuild: Boolean = True): Boolean;
    /// <summary>CleanUp: frees what the parse made and starts again</summary>
    procedure CleanUp;
    /// <summary>
    ///   FixupParms: resolves the names the parse could not (scripts, operations), children first; the
    ///   desktop then calculates the rectangles
    /// </summary>
    procedure FixupParms;
    procedure SetInitialState(const AName: AnsiString);
    procedure SetupFromState;
    procedure CalcClientRect(const AXOffset, AYOffset: Single);
    procedure CalcRects(const AX, AY: Single);
    procedure SetFlag(const AFlag: Cardinal);
    procedure ClearFlag(const AFlag: Cardinal);
    procedure SetParent(const AWindow: TGuiWindow);
    procedure AddChild(const AWindow: TGuiWindow);
    procedure AddUpdateVar(const AVariable: TGuiWinVar);
    procedure AddDefinedVar(const AVariable: TGuiWinVar);
    function IsSimple: Boolean;
    function Interactive: Boolean;
    function ContainsStateVars: Boolean;
    function NumTransitions: Integer;
    /// <summary>idWindow::FindChildByName: this window, a window of <c>DrawWindows</c> or one under them, case-insensitive</summary>
    function FindDrawWindow(const AName: AnsiString; out AIsSimple: Boolean): TGuiWindow;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; virtual;
    function SetFocus(const AWindow: TGuiWindow; const AScripts: Boolean = True): TGuiWindow;
    procedure InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
    function ParseExpression(const ASource: TIdParser): Integer;
    function ExpressionConstant(const AValue: Single): Integer;
    function TranslateString(const AText: AnsiString): AnsiString;
    function HasOps: Boolean;
    function EvalRegs(const ATest: Integer = -1; const AForce: Boolean = False): Single;
    procedure AddCommand(const ACommand: AnsiString);
    procedure AddTransition(const AVariable: TGuiWinVar; const AFrom, ATo: TIdVec4; const ATime: Integer;
      const AAccelTime, ADecelTime: Single);
    procedure StartTransition;
    procedure ResetTime(const ATime: Integer);
    procedure ResetCinematics;
    function RunScript(const AEvent: TGuiScriptEvent): Boolean;
    function RunScriptList(const AList: TGuiScriptList): Boolean;
    /// <summary>
    ///   RunTimeEvents: at most once per USERCMD_MSEC; updates the gui variables, evaluates the registers,
    ///   moves the transitions, runs the time line and the onEvent script, then the children
    /// </summary>
    function RunTimeEvents(const ATime: Integer): Boolean;
    procedure RunNamedEvent(const AEventName: AnsiString);
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString);
    procedure Trigger;
    procedure StateChanged(const ARedraw: Boolean);
    procedure ClientToScreen(var ARect: TGuiRectangle);
    procedure ScreenToClient(var ARect: TGuiRectangle);
    procedure Warning(const AText: string);
    property Name: AnsiString read FName;
    property Comment: AnsiString read FComment;
    property Flags: Cardinal read FFlags;
    property Parent: TGuiWindow read FParent;
    property ChildCount: Integer read GetChildCount;
    property Children[const AIndex: Integer]: TGuiWindow read GetChildren;
    property DrawWindowCount: Integer read GetDrawWindowCount;
    property DrawWindows[const AIndex: Integer]: TGuiDrawWindow read GetDrawWindows;
    property Scripts[const AEvent: TGuiScriptEvent]: TGuiScriptList read GetScripts;
    property TimeLineEventCount: Integer read GetTimeLineEventCount;
    property TimeLineEvents[const AIndex: Integer]: TGuiTimeLineEvent read GetTimeLineEvents;
    property NamedEventCount: Integer read GetNamedEventCount;
    property TransitionCount: Integer read GetTransitionCount;
    property UpdateVarCount: Integer read GetUpdateVarCount;
    property DefinedVarCount: Integer read GetDefinedVarCount;
    property DefinedVars[const AIndex: Integer]: TGuiWinVar read GetDefinedVars;
    property Store: TGuiExpressionStore read FStore;
    property RegList: TGuiRegisterList read FRegList;
    property Command: AnsiString read FCommand write FCommand;
    property FocusedChild: TGuiWindow read FFocusedChild;
    property TimeLine: Integer read FTimeLine;
    property DrawRect: TGuiRectangle read FDrawRect;
    property ClientRect: TGuiRectangle read FClientRect;
    property TextRect: TGuiRectangle read FTextRect;
    property Origin: TIdVec2 read FOrigin;
    property Shear: TIdVec2 read FShear;
    property FontNum: Integer read FFontNum;
    property Cursor: Integer read FCursor;
    property TextAlign: Integer read FTextAlign;
    property TextAlignX: Single read FTextAlignX;
    property TextAlignY: Single read FTextAlignY;
    property TextShadow: Integer read FTextShadow;
    property BorderSize: Single read FBorderSize;
    property MatScaleX: Single read FMatScaleX;
    property MatScaleY: Single read FMatScaleY;
    property ForceAspectWidth: Single read FForceAspectWidth;
    property ForceAspectHeight: Single read FForceAspectHeight;
    property NoTime: TGuiWinBool read FNoTime;
    property Visible: TGuiWinBool read FVisible;
    property NoEvents: TGuiWinBool read FNoEvents;
    property HideCursor: TGuiWinBool read FHideCursor;
    property Rect: TGuiWinRectangle read FRect;
    property BackColor: TGuiWinVec4 read FBackColor;
    property MatColor: TGuiWinVec4 read FMatColor;
    property ForeColor: TGuiWinVec4 read FForeColor;
    property HoverColor: TGuiWinVec4 read FHoverColor;
    property BorderColor: TGuiWinVec4 read FBorderColor;
    property TextScale: TGuiWinFloat read FTextScale;
    property Rotate: TGuiWinFloat read FRotate;
    property Text: TGuiWinStr read FText;
    property BackgroundName: TGuiWinBackground read FBackgroundName;
  private
    // the interfaces; the methods that have another name in the class than in the interface
    function IGuiExpressionHost.GetWinVarByName = HostGetWinVarByName;
    function IGuiWindowNode.FindChildByName = NodeFindChildByName;
    procedure IGuiWindowNode.SetFocus = NodeSetFocus;
    function IGuiWindowNode.GetParent = GetParentNode;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Gui.WinVar.Int, DelphiDoom.Gui.Regs.Register;

type
  TGuiRegisterEntry = record
    Name: AnsiString;
    RegisterType: TGuiRegisterType;
  end;

const
  // idWindow::RegisterVars
  REGISTER_VARS: array[0..25] of TGuiRegisterEntry = (
    (Name: 'forecolor'; RegisterType: rtVec4), (Name: 'hovercolor'; RegisterType: rtVec4),
    (Name: 'backcolor'; RegisterType: rtVec4), (Name: 'bordercolor'; RegisterType: rtVec4),
    (Name: 'rect'; RegisterType: rtRectangle), (Name: 'matcolor'; RegisterType: rtVec4),
    (Name: 'scale'; RegisterType: rtVec2), (Name: 'translate'; RegisterType: rtVec2),
    (Name: 'rotate'; RegisterType: rtFloat), (Name: 'textscale'; RegisterType: rtFloat),
    (Name: 'visible'; RegisterType: rtBool), (Name: 'noevents'; RegisterType: rtBool),
    (Name: 'text'; RegisterType: rtString), (Name: 'background'; RegisterType: rtString),
    (Name: 'runscript'; RegisterType: rtString), (Name: 'varbackground'; RegisterType: rtString),
    (Name: 'cvar'; RegisterType: rtString), (Name: 'choices'; RegisterType: rtString),
    (Name: 'choiceVar'; RegisterType: rtString), (Name: 'bind'; RegisterType: rtString),
    (Name: 'modelRotate'; RegisterType: rtVec4), (Name: 'modelOrigin'; RegisterType: rtVec4),
    (Name: 'lightOrigin'; RegisterType: rtVec4), (Name: 'lightColor'; RegisterType: rtVec4),
    (Name: 'viewOffset'; RegisterType: rtVec4), (Name: 'hideCursor'; RegisterType: rtBool));

{ TGuiWindow }

constructor TGuiWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
var
  LEvent: TGuiScriptEvent;
begin
  inherited Create;
  FContext := AContext;
  FCreator := ACreator;
  FChildren := TList<TGuiWindow>.Create;
  FOwned := TObjectList<TGuiWindow>.Create(True);
  FDrawWindows := TList<TGuiDrawWindow>.Create;
  FDefinedVars := TObjectList<TGuiWinVar>.Create(True);
  FUpdateVars := TList<TGuiWinVar>.Create;
  FTimeLineEvents := TObjectList<TGuiTimeLineEvent>.Create(True);
  FNamedEvents := TObjectList<TGuiNamedEvent>.Create(True);
  FTransitions := TObjectList<TGuiTransition>.Create(True);
  FNoTime := TGuiWinBool.Create;
  FVisible := TGuiWinBool.Create;
  FNoEvents := TGuiWinBool.Create;
  FHideCursor := TGuiWinBool.Create;
  FRect := TGuiWinRectangle.Create;
  FBackColor := TGuiWinVec4.Create;
  FMatColor := TGuiWinVec4.Create;
  FForeColor := TGuiWinVec4.Create;
  FHoverColor := TGuiWinVec4.Create;
  FBorderColor := TGuiWinVec4.Create;
  FTextScale := TGuiWinFloat.Create;
  FRotate := TGuiWinFloat.Create;
  FText := TGuiWinStr.Create;
  FBackgroundName := TGuiWinBackground.Create;
  FStore := TGuiExpressionStore.Create(AContext.SourceFile, AContext.Log);
  FRegList := TGuiRegisterList.Create;
  FEvaluator := TGuiExpressionEvaluator.Create(AContext.Tables, AContext.Log);
  FExpressionParser := TGuiExpressionParser.Create(FStore, Self, AContext.Tables);
  FScriptParser := TGuiScriptParser.Create(Self);
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    FScripts[LEvent] := nil;
  CommonInit;
end;

destructor TGuiWindow.Destroy;
begin
  CleanUp;
  FScriptParser.Free;
  FExpressionParser.Free;
  FEvaluator.Free;
  FRegList.Free;
  FStore.Free;
  FBackgroundName.Free;
  FText.Free;
  FRotate.Free;
  FTextScale.Free;
  FBorderColor.Free;
  FHoverColor.Free;
  FForeColor.Free;
  FMatColor.Free;
  FBackColor.Free;
  FRect.Free;
  FHideCursor.Free;
  FNoEvents.Free;
  FVisible.Free;
  FNoTime.Free;
  FTransitions.Free;
  FNamedEvents.Free;
  FTimeLineEvents.Free;
  FUpdateVars.Free;
  FDefinedVars.Free;
  FDrawWindows.Free;
  FOwned.Free;
  FChildren.Free;
  inherited Destroy;
end;

procedure TGuiWindow.CommonInit;
var
  LEvent: TGuiScriptEvent;
  LOne: TIdVec4;
begin
  FChildId := 0;
  FFlags := 0;
  FLastTimeRun := 0;
  FOrigin.Zero;
  FFontNum := 0;
  FTimeLine := -1;
  FXOffset := 0.0;
  FYOffset := 0.0;
  FCursor := 0;
  FForceAspectWidth := 640;
  FForceAspectHeight := 480;
  FMatScaleX := 1;
  FMatScaleY := 1;
  FBorderSize := 0;
  FNoTime.Value := False;
  FVisible.Value := True;
  FTextAlign := 0;
  FTextAlignX := 0;
  FTextAlignY := 0;
  FNoEvents.Value := False;
  FRotate.Value := 0;
  FShear.Zero;
  FTextScale.Value := 0.35;
  FBackColor.Zero;
  LOne := TIdVec4.Create(1, 1, 1, 1);
  FForeColor.Value := LOne;
  FHoverColor.Value := LOne;
  FMatColor.Value := LOne;
  FBorderColor.Zero;
  FBackgroundName.Value := '';
  FFocusedChild := nil;
  FCaptureChild := nil;
  FParent := nil;
  FTextShadow := 0;
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    FScripts[LEvent] := nil;
  FHideCursor.Value := False;
end;

procedure TGuiWindow.CleanUp;
var
  LEvent: TGuiScriptEvent;
begin
  // the register list and the operations refer to the variables that are about to be freed
  FRegList.Reset;
  FStore.Clear;
  FNamedEvents.Clear;
  FDrawWindows.Clear;
  FChildren.Clear;
  FOwned.Clear;
  FUpdateVars.Clear;
  FTransitions.Clear;
  FDefinedVars.Clear;
  FTimeLineEvents.Clear;
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    FreeAndNil(FScripts[LEvent]);
  CommonInit;
end;

procedure TGuiWindow.Warning(const AText: string);
begin
  if Assigned(FContext.Log) then
    FContext.Log.Warning(AText);
end;

function TGuiWindow.GetSourceFile: AnsiString;
begin
  Result := FContext.SourceFile;
end;

function TGuiWindow.GetGameHost: IGuiGameHost;
begin
  Result := FContext.GameHost;
end;

function TGuiWindow.GetParentNode: IGuiWindowNode;
begin
  if Assigned(FParent) then
    Result := FParent
  else
    Result := nil;
end;

function TGuiWindow.GetName: AnsiString;
begin
  Result := FName;
end;

function TGuiWindow.GetCommand: AnsiString;
begin
  Result := FCommand;
end;

procedure TGuiWindow.SetCommand(const AValue: AnsiString);
begin
  FCommand := AValue;
end;

function TGuiWindow.GetRectVar: TGuiWinVar;
begin
  Result := FRect;
end;

function TGuiWindow.GetDesktop: IGuiWindowNode;
begin
  Result := FContext.Desktop;
end;

function TGuiWindow.GetStore: TGuiExpressionStore;
begin
  Result := FStore;
end;

function TGuiWindow.GetDesktopWindow: TGuiWindow;
begin
  Result := nil;
  if Assigned(FContext.Desktop) then
    Result := FContext.Desktop as TGuiWindow;
end;

function TGuiWindow.GetChildCount: Integer;
begin
  Result := FChildren.Count;
end;

function TGuiWindow.GetChildren(const AIndex: Integer): TGuiWindow;
begin
  Result := FChildren[AIndex];
end;

function TGuiWindow.GetDrawWindowCount: Integer;
begin
  Result := FDrawWindows.Count;
end;

function TGuiWindow.GetDrawWindows(const AIndex: Integer): TGuiDrawWindow;
begin
  Result := FDrawWindows[AIndex];
end;

function TGuiWindow.GetScripts(const AEvent: TGuiScriptEvent): TGuiScriptList;
begin
  Result := FScripts[AEvent];
end;

function TGuiWindow.GetTimeLineEventCount: Integer;
begin
  Result := FTimeLineEvents.Count;
end;

function TGuiWindow.GetTimeLineEvents(const AIndex: Integer): TGuiTimeLineEvent;
begin
  Result := FTimeLineEvents[AIndex];
end;

function TGuiWindow.GetNamedEventCount: Integer;
begin
  Result := FNamedEvents.Count;
end;

function TGuiWindow.GetTransitionCount: Integer;
begin
  Result := FTransitions.Count;
end;

function TGuiWindow.GetUpdateVarCount: Integer;
begin
  Result := FUpdateVars.Count;
end;

function TGuiWindow.GetDefinedVarCount: Integer;
begin
  Result := FDefinedVars.Count;
end;

function TGuiWindow.GetDefinedVars(const AIndex: Integer): TGuiWinVar;
begin
  Result := FDefinedVars[AIndex];
end;

procedure TGuiWindow.SetFlag(const AFlag: Cardinal);
begin
  FFlags := FFlags or AFlag;
end;

procedure TGuiWindow.ClearFlag(const AFlag: Cardinal);
begin
  FFlags := FFlags and (not AFlag);
end;

procedure TGuiWindow.SetParent(const AWindow: TGuiWindow);
begin
  FParent := AWindow;
end;

procedure TGuiWindow.AddChild(const AWindow: TGuiWindow);
begin
  AWindow.FChildId := FChildren.Add(AWindow);
  FOwned.Add(AWindow);
end;

procedure TGuiWindow.AddUpdateVar(const AVariable: TGuiWinVar);
begin
  if FUpdateVars.IndexOf(AVariable) < 0 then
    FUpdateVars.Add(AVariable);
end;

procedure TGuiWindow.AddDefinedVar(const AVariable: TGuiWinVar);
begin
  if FDefinedVars.IndexOf(AVariable) < 0 then
    FDefinedVars.Add(AVariable);
end;

procedure TGuiWindow.AddDefinedVarOwned(const AVariable: TGuiWinVar);
begin
  FDefinedVars.Add(AVariable);
end;

procedure TGuiWindow.InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
begin
  if AVar.Init(AName, FContext.StateDict) then
    AddUpdateVar(AVar);
end;

function TGuiWindow.ParseExpression(const ASource: TIdParser): Integer;
begin
  Result := FExpressionParser.ParseExpression(ASource);
end;

function TGuiWindow.ExpressionConstant(const AValue: Single): Integer;
begin
  Result := FStore.ExpressionConstant(AValue);
end;

function TGuiWindow.TranslateString(const AText: AnsiString): AnsiString;
begin
  if Assigned(FContext.Language) then
    Result := FContext.Language.GetString(AText)
  else
    Result := AText;
end;

function TGuiWindow.HasOps: Boolean;
begin
  Result := FStore.OpCount > 0;
end;

procedure TGuiWindow.SetInitialState(const AName: AnsiString);
begin
  FName := AName;
  FMatScaleX := 1.0;
  FMatScaleY := 1.0;
  FForceAspectWidth := 640.0;
  FForceAspectHeight := 480.0;
  FNoTime.Value := False;
  FVisible.Value := True;
  FFlags := 0;
end;

procedure TGuiWindow.ParseString(const ASource: TIdParser; var AOutput: AnsiString);
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if ASource.ReadToken(LToken) then
    AOutput := LToken.Text;
end;

procedure TGuiWindow.ParseVec4(const ASource: TIdParser; var AOutput: TIdVec4);
var
  LToken: TIdToken;
  LIndex: Integer;
begin
  LToken := TIdToken.Create;
  for LIndex := 0 to 3 do
  begin
    ASource.ReadToken(LToken);
    AOutput[LIndex] := TIdCNumbers.Atof(LToken.Text);
    if LIndex < 3 then
      ASource.ExpectTokenString(',');
  end;
end;

function TGuiWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
var
  LToken: TIdToken;
  LFont: AnsiString;
  LText: AnsiString;

  function Is_(const AKey: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(AName, AKey) = 0;
  end;

  procedure FlagIfTrue(const AFlag: Cardinal);
  begin
    if ASource.ParseBool then
      FFlags := FFlags or AFlag;
  end;

begin
  Result := True;
  if Is_('showtime') then
    FlagIfTrue(WIN_SHOWTIME)
  else if Is_('showcoords') then
    FlagIfTrue(WIN_SHOWCOORDS)
  else if Is_('forceaspectwidth') then
    FForceAspectWidth := ASource.ParseFloat
  else if Is_('forceaspectheight') then
    FForceAspectHeight := ASource.ParseFloat
  else if Is_('matscalex') then
    FMatScaleX := ASource.ParseFloat
  else if Is_('matscaley') then
    FMatScaleY := ASource.ParseFloat
  else if Is_('bordersize') then
    FBorderSize := ASource.ParseFloat
  else if Is_('nowrap') then
    FlagIfTrue(WIN_NOWRAP)
  else if Is_('shadow') then
    FTextShadow := ASource.ParseInt
  else if Is_('textalign') then
    FTextAlign := ASource.ParseInt
  else if Is_('textalignx') then
    FTextAlignX := ASource.ParseFloat
  else if Is_('textaligny') then
    FTextAlignY := ASource.ParseFloat
  else if Is_('shear') then
  begin
    FShear.X := ASource.ParseFloat;
    LToken := TIdToken.Create;
    ASource.ReadToken(LToken);
    if TIdStrings.Icmp(LToken.Text, ',') <> 0 then
    begin
      ASource.Error('Expected comma in shear definiation');
      Exit(False);
    end;
    FShear.Y := ASource.ParseFloat;
  end
  else if Is_('wantenter') then
    FlagIfTrue(WIN_WANTENTER)
  else if Is_('naturalmatscale') then
    FlagIfTrue(WIN_NATURALMAT)
  else if Is_('noclip') then
    FlagIfTrue(WIN_NOCLIP)
  else if Is_('nocursor') then
    FlagIfTrue(WIN_NOCURSOR)
  else if Is_('menugui') then
    FlagIfTrue(WIN_MENUGUI)
  else if Is_('modal') then
    FlagIfTrue(WIN_MODAL)
  else if Is_('invertrect') then
    FlagIfTrue(WIN_INVERTRECT)
  else if Is_('name') then
    ParseString(ASource, FName)
  else if Is_('play') then
  begin
    Warning('play encountered during gui parse.. see Robert');
    LText := '';
    ParseString(ASource, LText);
  end
  else if Is_('comment') then
    ParseString(ASource, FComment)
  else if Is_('font') then
  begin
    LFont := '';
    ParseString(ASource, LFont);
    if Assigned(FContext.Fonts) then
      FFontNum := FContext.Fonts.FindFont(LFont)
    else
      FFontNum := 0;
  end
  else
    Result := False;
end;

procedure TGuiWindow.PostParse;
begin
end;

procedure TGuiWindow.DisableRegister(const AName: AnsiString);
var
  LRegister: TGuiRegister;
begin
  LRegister := FRegList.FindReg(AName);
  if Assigned(LRegister) then
    LRegister.Enabled := False;
end;

function TGuiWindow.GetSimpleWinVarByName(const AName: AnsiString): TGuiWinVar;
begin
  // idSimpleWindow::GetWinVarByName: fewer names than a window (no hovercolor, noevents, notime)
  Result := nil;
  if TIdStrings.Icmp(AName, 'background') = 0 then
    Result := FBackgroundName;
  if TIdStrings.Icmp(AName, 'visible') = 0 then
    Result := FVisible;
  if TIdStrings.Icmp(AName, 'rect') = 0 then
    Result := FRect;
  if TIdStrings.Icmp(AName, 'backColor') = 0 then
    Result := FBackColor;
  if TIdStrings.Icmp(AName, 'matColor') = 0 then
    Result := FMatColor;
  if TIdStrings.Icmp(AName, 'foreColor') = 0 then
    Result := FForeColor;
  if TIdStrings.Icmp(AName, 'borderColor') = 0 then
    Result := FBorderColor;
  if TIdStrings.Icmp(AName, 'textScale') = 0 then
    Result := FTextScale;
  if TIdStrings.Icmp(AName, 'rotate') = 0 then
    Result := FRotate;
  if TIdStrings.Icmp(AName, 'text') = 0 then
    Result := FText;
end;

function TGuiWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
var
  LResult: TGuiWinVar;
  LGuiVar: Boolean;
  LIndex: Integer;
  LLength: Integer;
  LPosition: Integer;
  LWindowName: AnsiString;
  LVarName: AnsiString;
  LDesktop: TGuiWindow;
  LFound: TGuiWindow;
  LSimple: Boolean;
  LOwnerWindow: TGuiWindow;
  LNew: TGuiWinStr;
begin
  AOwner := nil;
  LResult := nil;
  if TIdStrings.Icmp(AName, 'notime') = 0 then
    LResult := FNoTime;
  if TIdStrings.Icmp(AName, 'background') = 0 then
    LResult := FBackgroundName;
  if TIdStrings.Icmp(AName, 'visible') = 0 then
    LResult := FVisible;
  if TIdStrings.Icmp(AName, 'rect') = 0 then
    LResult := FRect;
  if TIdStrings.Icmp(AName, 'backColor') = 0 then
    LResult := FBackColor;
  if TIdStrings.Icmp(AName, 'matColor') = 0 then
    LResult := FMatColor;
  if TIdStrings.Icmp(AName, 'foreColor') = 0 then
    LResult := FForeColor;
  if TIdStrings.Icmp(AName, 'hoverColor') = 0 then
    LResult := FHoverColor;
  if TIdStrings.Icmp(AName, 'borderColor') = 0 then
    LResult := FBorderColor;
  if TIdStrings.Icmp(AName, 'textScale') = 0 then
    LResult := FTextScale;
  if TIdStrings.Icmp(AName, 'rotate') = 0 then
    LResult := FRotate;
  if TIdStrings.Icmp(AName, 'noEvents') = 0 then
    LResult := FNoEvents;
  if TIdStrings.Icmp(AName, 'text') = 0 then
    LResult := FText;
  if TIdStrings.Icmp(AName, 'backGroundName') = 0 then
    LResult := FBackgroundName;
  if TIdStrings.Icmp(AName, 'hidecursor') = 0 then
    LResult := FHideCursor;

  LGuiVar := TIdStrings.FindText(AName, GUI_VAR_PREFIX) >= 0;
  for LIndex := 0 to FDefinedVars.Count - 1 do
    if TIdStrings.Icmp(AName, FDefinedVars[LIndex].GetName) = 0 then
    begin
      LResult := FDefinedVars[LIndex];
      Break;
    end;

  if Assigned(LResult) then
  begin
    if AFixup and ((AName = '') or (AName[1] <> '$')) then
      DisableRegister(AName);
    if Assigned(FParent) then
    begin
      LOwnerWindow := FParent.FindDrawWindow(FName, LSimple);
      if Assigned(LOwnerWindow) then
        AOwner := LOwnerWindow;
    end;
    Exit(LResult);
  end;

  LLength := Length(AName);
  if (LLength > 5) and LGuiVar then
  begin
    LNew := TGuiWinStr.Create;
    InitVar(LNew, AName);
    FDefinedVars.Add(LNew);
    Exit(LNew);
  end
  else if AFixup then
  begin
    LPosition := Pos('::', string(AName)) - 1;
    if LPosition > 0 then
    begin
      LWindowName := Copy(AName, 1, LPosition);
      LVarName := Copy(AName, LPosition + 3, MaxInt);
      LDesktop := GetDesktopWindow;
      if Assigned(LDesktop) then
      begin
        LFound := LDesktop.FindDrawWindow(LWindowName, LSimple);
        if Assigned(LFound) then
        begin
          if not LSimple then
            Exit(LFound.GetWinVarByName(LVarName, False, AOwner));
          AOwner := LFound;
          Exit(LFound.GetSimpleWinVarByName(LVarName));
        end;
      end;
    end;
  end;
  Result := nil;
end;

function TGuiWindow.HostGetWinVarByName(const AName: AnsiString; const AFixup: Boolean): TGuiWinVar;
var
  LOwner: IGuiWindowNode;
begin
  Result := GetWinVarByName(AName, AFixup, LOwner);
end;

function TGuiWindow.FindDrawWindow(const AName: AnsiString; out AIsSimple: Boolean): TGuiWindow;
var
  LIndex: Integer;
  LDraw: TGuiDrawWindow;
  LFound: TGuiWindow;
  LNestedSimple: Boolean;
begin
  AIsSimple := False;
  if TIdStrings.Icmp(FName, AName) = 0 then
    Exit(Self);
  for LIndex := 0 to FDrawWindows.Count - 1 do
  begin
    LDraw := FDrawWindows[LIndex];
    if TIdStrings.Icmp(LDraw.Window.FName, AName) = 0 then
    begin
      AIsSimple := LDraw.IsSimple;
      Exit(LDraw.Window);
    end;
    if not LDraw.IsSimple then
    begin
      LFound := LDraw.Window.FindDrawWindow(AName, LNestedSimple);
      if Assigned(LFound) then
      begin
        AIsSimple := LNestedSimple;
        Exit(LFound);
      end;
    end;
  end;
  Result := nil;
end;

function TGuiWindow.NodeFindChildByName(const AName: AnsiString; out AIsSimple: Boolean): IGuiWindowNode;
var
  LWindow: TGuiWindow;
begin
  LWindow := FindDrawWindow(AName, AIsSimple);
  if Assigned(LWindow) then
    Result := LWindow
  else
    Result := nil;
end;

function TGuiWindow.SetFocus(const AWindow: TGuiWindow; const AScripts: Boolean): TGuiWindow;
var
  LDesktop: TGuiWindow;
begin
  // only one child can have the focus; it is remembered by the desktop
  Result := nil;
  LDesktop := GetDesktopWindow;
  if (not Assigned(LDesktop)) or ((AWindow.FFlags and WIN_CANFOCUS) = 0) then
    Exit;
  Result := LDesktop.FFocusedChild;
  if Assigned(Result) then
    Result.ClearFlag(WIN_FOCUS);
  AWindow.SetFlag(WIN_FOCUS);
  LDesktop.FFocusedChild := AWindow;
end;

procedure TGuiWindow.NodeSetFocus(const AWindow: IGuiWindowNode);
begin
  if Assigned(AWindow) then
    SetFocus(AWindow as TGuiWindow);
end;

procedure TGuiWindow.ParseDefineFloat(const ASource: TIdParser);
var
  LToken: TIdToken;
  LWork: AnsiString;
  LVariable: TGuiWinFloat;
begin
  LToken := TIdToken.Create;
  ASource.ReadToken(LToken);
  LWork := TIdStrings.ToLower(LToken.Text);
  LVariable := TGuiWinFloat.Create;
  LVariable.SetName(LWork);
  FDefinedVars.Add(LVariable);
  FRegList.AddReg(LWork, rtFloat, ASource, Self, LVariable);
end;

procedure TGuiWindow.ParseDefineVec4(const ASource: TIdParser);
var
  LToken: TIdToken;
  LWork: AnsiString;
  LVariable: TGuiWinVec4;
  LDesktop: TGuiWindow;
begin
  LToken := TIdToken.Create;
  ASource.ReadToken(LToken);
  LWork := TIdStrings.ToLower(LToken.Text);
  LVariable := TGuiWinVec4.Create;
  LVariable.SetName(LWork);
  // the desktop keeps it, so that it outlives the window that defines it
  LDesktop := GetDesktopWindow;
  if not Assigned(LDesktop) then
    LDesktop := Self;
  LDesktop.FDefinedVars.Add(LVariable);
  LDesktop.FRegList.AddReg(LWork, rtVec4, ASource, LDesktop, LVariable);
end;

function TGuiWindow.ParseScriptEntry(const AName: AnsiString; const ASource: TIdParser): Boolean;
var
  LEvent: TGuiScriptEvent;
begin
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    if TIdStrings.Icmp(AName, GUI_SCRIPT_NAMES[LEvent]) = 0 then
    begin
      FScripts[LEvent].Free;
      FScripts[LEvent] := TGuiScriptList.Create;
      Exit(FScriptParser.ParseScript(ASource, FScripts[LEvent]));
    end;
  Result := False;
end;

function TGuiWindow.ParseRegEntry(const AName: AnsiString; const ASource: TIdParser): Boolean;
var
  LWork: AnsiString;
  LVariable: TGuiWinVar;
  LIndex: Integer;
  LOwner: IGuiWindowNode;
  LToken: TIdToken;
  LInt: TGuiWinInt;
  LFloat: TGuiWinFloat;
  LString: TGuiWinStr;
begin
  LWork := TIdStrings.ToLower(AName);
  LVariable := GetWinVarByName(LWork, False, LOwner);
  if Assigned(LVariable) then
    for LIndex := Low(REGISTER_VARS) to High(REGISTER_VARS) do
      if TIdStrings.Icmp(LWork, REGISTER_VARS[LIndex].Name) = 0 then
      begin
        FRegList.AddReg(LWork, REGISTER_VARS[LIndex].RegisterType, ASource, Self, LVariable);
        Exit(True);
      end;
  // not predefined: the next token is a value that is added to the state
  LToken := TIdToken.Create;
  if ASource.ReadToken(LToken) then
  begin
    if Assigned(LVariable) then
    begin
      LVariable.SetFromText(LToken.Text);
      Exit(True);
    end;
    if (LToken.TokenType = TT_NUMBER) and ((LToken.SubType and TT_INTEGER) <> 0) then
    begin
      LInt := TGuiWinInt.Create;
      LInt.Value := TIdCNumbers.Atoi(LToken.Text);
      LInt.SetName(LWork);
      FDefinedVars.Add(LInt);
    end
    else if (LToken.TokenType = TT_NUMBER) and ((LToken.SubType and TT_FLOAT) <> 0) then
    begin
      LFloat := TGuiWinFloat.Create;
      LFloat.Value := TIdCNumbers.Atof(LToken.Text);
      LFloat.SetName(LWork);
      FDefinedVars.Add(LFloat);
    end
    else
    begin
      LString := TGuiWinStr.Create;
      LString.Value := LToken.Text;
      LString.SetName(LWork);
      FDefinedVars.Add(LString);
    end;
  end;
  Result := True;
end;

procedure TGuiWindow.ParseOnTime(const ASource: TIdParser; var AOk: Boolean);
var
  LToken: TIdToken;
  LEvent: TGuiTimeLineEvent;
begin
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
  begin
    ASource.Error('Unexpected end of file');
    AOk := False;
    Exit;
  end;
  LEvent := TGuiTimeLineEvent.Create;
  LEvent.Time := TIdCNumbers.Atoi(LToken.Text);
  if not FScriptParser.ParseScript(ASource, LEvent.Script) then
  begin
    LEvent.Free;
    AOk := False;
    Exit;
  end;
  LEvent.Pending := True;
  FTimeLineEvents.Add(LEvent);
end;

procedure TGuiWindow.ParseOnNamedEvent(const ASource: TIdParser; var AOk: Boolean);
var
  LToken: TIdToken;
  LEvent: TGuiNamedEvent;
begin
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
  begin
    ASource.Error('Expected event name');
    AOk := False;
    Exit;
  end;
  LEvent := TGuiNamedEvent.Create(LToken.Text);
  if not FScriptParser.ParseScript(ASource, LEvent.Script) then
  begin
    LEvent.Free;
    AOk := False;
    Exit;
  end;
  FNamedEvents.Add(LEvent);
end;

function TGuiWindow.IsSimple: Boolean;
var
  LEvent: TGuiScriptEvent;
begin
  if HasOps then
    Exit(False);
  if (FFlags and (WIN_HCENTER or WIN_VCENTER)) <> 0 then
    Exit(False);
  if (FChildren.Count > 0) or (FDrawWindows.Count > 0) then
    Exit(False);
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    if Assigned(FScripts[LEvent]) then
      Exit(False);
  if FTimeLineEvents.Count > 0 then
    Exit(False);
  Result := FNamedEvents.Count = 0;
end;

procedure TGuiWindow.AdoptSimple(const AWindow: TGuiWindow);
var
  LDraw: TGuiDrawWindow;

  procedure Track(const AVariable: TGuiWinVar);
  begin
    if AVariable.NeedsUpdate then
      AddUpdateVar(AVariable);
  end;

begin
  FOwned.Add(AWindow);
  LDraw.Window := AWindow;
  LDraw.IsSimple := True;
  FDrawWindows.Add(LDraw);
  // idSimpleWindow::idSimpleWindow: the parent updates the variables bound to the state
  Track(AWindow.FText);
  Track(AWindow.FVisible);
  Track(AWindow.FRect);
  Track(AWindow.FBackColor);
  Track(AWindow.FMatColor);
  Track(AWindow.FForeColor);
  Track(AWindow.FBorderColor);
  Track(AWindow.FTextScale);
  Track(AWindow.FRotate);
  Track(AWindow.FBackgroundName);
end;

procedure TGuiWindow.ParseWindowDef(const ASource: TIdParser; const ARebuild: Boolean; const AIsAnimation: Boolean);
var
  LToken: TIdToken;
  LName: AnsiString;
  LExisting: TGuiWindow;
  LWindow: TGuiWindow;
  LSimple: Boolean;
  LDraw: TGuiDrawWindow;
begin
  // as in the original, an animationDef hides and empties this window, not the new one
  if AIsAnimation then
  begin
    FVisible.Value := False;
    FRect.Value := TGuiRectangle.Create(0, 0, 0, 0);
  end;
  LToken := TIdToken.Create;
  ASource.ExpectTokenType(TT_NAME, 0, LToken);
  LName := LToken.Text;
  ASource.UnreadToken(LToken);
  LExisting := FindDrawWindow(LName, LSimple);
  if Assigned(LExisting) and (not LSimple) then
    LExisting.Parse(ASource, ARebuild)
  else
  begin
    LWindow := TGuiWindow.Create(FContext, FCreator);
    LWindow.Parse(ASource, ARebuild);
    LWindow.SetParent(Self);
    if LWindow.IsSimple then
      AdoptSimple(LWindow)
    else
    begin
      AddChild(LWindow);
      SetFocus(LWindow, False);
      LDraw.Window := LWindow;
      LDraw.IsSimple := False;
      FDrawWindows.Add(LDraw);
    end;
  end;
end;

procedure TGuiWindow.ParseKeywordWindow(const ASource: TIdParser; const ARebuild: Boolean; const AWindow: TGuiWindow);
var
  LDraw: TGuiDrawWindow;
begin
  AWindow.Parse(ASource, ARebuild);
  AddChild(AWindow);
  AWindow.SetParent(Self);
  LDraw.Window := AWindow;
  LDraw.IsSimple := False;
  FDrawWindows.Add(LDraw);
end;

function TGuiWindow.Parse(const ASource: TIdParser; const ARebuild: Boolean): Boolean;
var
  LToken: TIdToken;
  LWindow: TGuiWindow;
begin
  if ARebuild then
    CleanUp;
  FTimeLineEvents.Clear;
  FTransitions.Clear;
  FNamedEvents.Clear;
  LToken := TIdToken.Create;
  ASource.ExpectTokenType(TT_NAME, 0, LToken);
  SetInitialState(LToken.Text);
  ASource.ExpectTokenString('{');
  ASource.ExpectAnyToken(LToken);
  Result := True;
  while not LToken.IsText('}') do
  begin
    if LToken.IsText('windowDef') then
      ParseWindowDef(ASource, ARebuild, False)
    else if LToken.IsText('animationDef') then
      ParseWindowDef(ASource, ARebuild, True)
    else if LToken.IsText('onNamedEvent') then
    begin
      ParseOnNamedEvent(ASource, Result);
      if not Result then
        Break;
    end
    else if LToken.IsText('onTime') then
    begin
      ParseOnTime(ASource, Result);
      if not Result then
        Break;
    end
    else if LToken.IsText('definefloat') or LToken.IsText('float') then
      ParseDefineFloat(ASource)
    else if LToken.IsText('definevec4') then
      ParseDefineVec4(ASource)
    else
    begin
      LWindow := nil;
      if Assigned(FCreator) then
        LWindow := FCreator(LToken.Text);
      if Assigned(LWindow) then
        ParseKeywordWindow(ASource, ARebuild, LWindow)
      else if ParseScriptEntry(LToken.Text, ASource) then
      begin
        // a script
      end
      else if ParseInternalVar(LToken.Text, ASource) then
      begin
        // a key that is not a register
      end
      else
        ParseRegEntry(LToken.Text, ASource);
    end;
    if not ASource.ReadToken(LToken) then
    begin
      ASource.Error('Unexpected end of file');
      Result := False;
      Break;
    end;
  end;
  if Result then
    EvalRegs(-1, True);
  SetupFromState;
  PostParse;
end;

procedure TGuiWindow.SetupFromState;
begin
  if FBorderSize <> 0 then
    FFlags := FFlags or WIN_BORDER;
  if Assigned(FRegList.FindReg('rotate')) or Assigned(FRegList.FindReg('shear')) then
    FFlags := FFlags or WIN_TRANSFORM;
  CalcClientRect(0, 0);
  if Assigned(FScripts[seAction]) then
  begin
    FCursor := GUI_CURSOR_HAND;
    FFlags := FFlags or WIN_CANFOCUS;
  end;
end;

procedure TGuiWindow.CalcClientRect(const AXOffset, AYOffset: Single);
var
  LRect: TGuiRectangle;
begin
  LRect := FRect.Value;
  FDrawRect := LRect;
  if (FFlags and WIN_INVERTRECT) <> 0 then
  begin
    FDrawRect.X := LRect.X - LRect.W;
    FDrawRect.Y := LRect.Y - LRect.H;
  end;
  if ((FFlags and (WIN_HCENTER or WIN_VCENTER)) <> 0) and Assigned(FParent) then
  begin
    // the offsets are absolute top left coordinates: the original position is ignored
    if (FFlags and WIN_HCENTER) <> 0 then
      FDrawRect.X := (FParent.FRect.Value.W - LRect.W) / 2
    else
      FDrawRect.Y := (FParent.FRect.Value.H - LRect.H) / 2;
  end;
  FDrawRect.X := FDrawRect.X + AXOffset;
  FDrawRect.Y := FDrawRect.Y + AYOffset;
  FClientRect := FDrawRect;
  if (LRect.H > 0.0) and (LRect.W > 0.0) then
  begin
    if ((FFlags and WIN_BORDER) <> 0) and (FBorderSize <> 0.0) then
    begin
      FClientRect.X := FClientRect.X + FBorderSize;
      FClientRect.Y := FClientRect.Y + FBorderSize;
      FClientRect.W := FClientRect.W - FBorderSize;
      FClientRect.H := FClientRect.H - FBorderSize;
    end;
    FTextRect := FClientRect;
    FTextRect.X := FTextRect.X + 2.0;
    FTextRect.W := FTextRect.W - 2.0;
    FTextRect.Y := FTextRect.Y + 2.0;
    FTextRect.H := FTextRect.H - 2.0;
    FTextRect.X := FTextRect.X + FTextAlignX;
    FTextRect.Y := FTextRect.Y + FTextAlignY;
  end;
  FOrigin.X := LRect.X + (LRect.W / 2);
  FOrigin.Y := LRect.Y + (LRect.H / 2);
end;

procedure TGuiWindow.CalcRects(const AX, AY: Single);
var
  LIndex: Integer;
begin
  CalcClientRect(0, 0);
  FDrawRect.Offset(AX, AY);
  FClientRect.Offset(AX, AY);
  for LIndex := 0 to FDrawWindows.Count - 1 do
    if not FDrawWindows[LIndex].IsSimple then
      FDrawWindows[LIndex].Window.CalcRects(FClientRect.X + FXOffset, FClientRect.Y + FYOffset);
  FDrawRect.Offset(-AX, -AY);
  FClientRect.Offset(-AX, -AY);
end;

procedure TGuiWindow.FixupParms;
var
  LIndex: Integer;
  LEvent: TGuiScriptEvent;
  LOp: TGuiOp;
  LVariable: TGuiWinVar;
  LOwner: IGuiWindowNode;
  LNode: IGuiWindowNode;
begin
  for LIndex := 0 to FChildren.Count - 1 do
    FChildren[LIndex].FixupParms;
  LNode := Self;
  for LEvent := Low(TGuiScriptEvent) to High(TGuiScriptEvent) do
    if Assigned(FScripts[LEvent]) then
      FScripts[LEvent].FixupParms(LNode);
  for LIndex := 0 to FTimeLineEvents.Count - 1 do
    FTimeLineEvents[LIndex].Script.FixupParms(LNode);
  for LIndex := 0 to FNamedEvents.Count - 1 do
    FNamedEvents[LIndex].Script.FixupParms(LNode);
  for LIndex := 0 to FStore.OpCount - 1 do
  begin
    LOp := FStore.Ops[LIndex];
    if LOp.B = -2 then
    begin
      // a name the parse could not resolve
      LVariable := GetWinVarByName(LOp.PendingName, True, LOwner);
      LOp.PendingName := '';
      LOp.Variable := LVariable;
      LOp.B := -1;
      FStore.Ops[LIndex] := LOp;
    end;
  end;
  if (FFlags and WIN_DESKTOP) <> 0 then
    CalcRects(0, 0);
end;

function TGuiWindow.EvalRegs(const ATest: Integer; const AForce: Boolean): Single;
begin
  if (not AForce) and (ATest >= 0) and (ATest < GUI_MAX_EXPRESSION_REGISTERS) and
    (FContext.LastEvalWindow = Self) then
    Exit(FContext.EvalRegisters[ATest]);
  FContext.LastEvalWindow := Self;
  if FStore.RegisterCount > 0 then
  begin
    FRegList.SetToRegs(FContext.EvalRegisters);
    FEvaluator.Evaluate(FStore, FContext.Time, FContext.EvalRegisters, FName, FContext.SourceFile);
    FRegList.GetFromRegs(FContext.EvalRegisters);
  end;
  if (ATest >= 0) and (ATest < GUI_MAX_EXPRESSION_REGISTERS) then
    Result := FContext.EvalRegisters[ATest]
  else
    Result := 0.0;
end;

procedure TGuiWindow.AddCommand(const ACommand: AnsiString);
begin
  if FCommand <> '' then
    FCommand := FCommand + ' ; ' + ACommand
  else
    FCommand := ACommand;
end;

procedure TGuiWindow.AddTransition(const AVariable: TGuiWinVar; const AFrom, ATo: TIdVec4; const ATime: Integer;
  const AAccelTime, ADecelTime: Single);
var
  LTransition: TGuiTransition;
begin
  LTransition := TGuiTransition.Create(AVariable);
  LTransition.Interpolator.Init(FContext.Time, AAccelTime * ATime, ADecelTime * ATime, ATime, AFrom, ATo);
  FTransitions.Add(LTransition);
end;

procedure TGuiWindow.StartTransition;
begin
  FFlags := FFlags or WIN_INTRANSITION;
end;

procedure TGuiWindow.ResetCinematics;
begin
  if Assigned(FContext.GameHost) and (FBackgroundName.AsText <> '') then
    FContext.GameHost.ResetCinematic(FBackgroundName.AsText, FContext.Time);
end;

procedure TGuiWindow.ResetTime(const ATime: Integer);
var
  LIndex: Integer;
begin
  FTimeLine := FContext.Time - ATime;
  for LIndex := 0 to FTimeLineEvents.Count - 1 do
    if FTimeLineEvents[LIndex].Time >= ATime then
      FTimeLineEvents[LIndex].Pending := True;
  FNoTime.Value := False;
  LIndex := 0;
  while LIndex < FTransitions.Count do
  begin
    if FTransitions[LIndex].Interpolator.IsDone(FContext.Time) and Assigned(FTransitions[LIndex].Variable) then
      FTransitions.Delete(LIndex)
    else
      Inc(LIndex);
  end;
end;

function TGuiWindow.RunScriptList(const AList: TGuiScriptList): Boolean;
begin
  if not Assigned(AList) then
    Exit(False);
  AList.Execute(Self);
  Result := True;
end;

function TGuiWindow.RunScript(const AEvent: TGuiScriptEvent): Boolean;
begin
  Result := RunScriptList(FScripts[AEvent]);
end;

procedure TGuiWindow.UpdateWinVars;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FUpdateVars.Count - 1 do
    FUpdateVars[LIndex].Update;
end;

procedure TGuiWindow.Transition;
var
  LIndex: Integer;
  LClear: Boolean;
  LTransition: TGuiTransition;
  LValue: TIdVec4;
begin
  LClear := True;
  for LIndex := 0 to FTransitions.Count - 1 do
  begin
    LTransition := FTransitions[LIndex];
    if LTransition.Interpolator.IsDone(FContext.Time) and Assigned(LTransition.Variable) then
      LValue := LTransition.Interpolator.EndValue
    else
    begin
      LClear := False;
      if not Assigned(LTransition.Variable) then
      begin
        Warning(Format('Invalid transitional data for window %s in gui %s', [string(FName),
          string(FContext.SourceFile)]));
        Continue;
      end;
      LValue := LTransition.Interpolator.GetCurrentValue(FContext.Time);
    end;
    if LTransition.Variable is TGuiWinVec4 then
      TGuiWinVec4(LTransition.Variable).Value := LValue
    else if LTransition.Variable is TGuiWinFloat then
      TGuiWinFloat(LTransition.Variable).Value := LValue.X
    else if LTransition.Variable is TGuiWinRectangle then
      TGuiWinRectangle(LTransition.Variable).Value := TGuiRectangle.FromVec4(LValue);
  end;
  if LClear then
  begin
    FTransitions.Clear;
    FFlags := FFlags and (not WIN_INTRANSITION);
  end;
end;

procedure TGuiWindow.Time;
var
  LIndex: Integer;
  LEvent: TGuiTimeLineEvent;
begin
  if FNoTime.Value then
    Exit;
  if FTimeLine = -1 then
    FTimeLine := FContext.Time;
  FCommand := '';
  for LIndex := 0 to FTimeLineEvents.Count - 1 do
  begin
    LEvent := FTimeLineEvents[LIndex];
    if LEvent.Pending and (FContext.Time - FTimeLine >= LEvent.Time) then
    begin
      LEvent.Pending := False;
      RunScriptList(LEvent.Script);
    end;
  end;
  if FContext.Active then
    FContext.PendingCommand := FContext.PendingCommand + FCommand;
end;

function TGuiWindow.RunTimeEvents(const ATime: Integer): Boolean;
var
  LIndex: Integer;
begin
  if ATime - FLastTimeRun < GUI_USERCMD_MSEC then
    Exit(False);
  FLastTimeRun := ATime;
  UpdateWinVars;
  if (FStore.RegisterCount > 0) and (FStore.OpCount > 0) then
    EvalRegs;
  if (FFlags and WIN_INTRANSITION) <> 0 then
    Transition;
  Time;
  RunScript(seFrame);
  for LIndex := 0 to FChildren.Count - 1 do
    FChildren[LIndex].RunTimeEvents(ATime);
  Result := True;
end;

procedure TGuiWindow.RunNamedEvent(const AEventName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FNamedEvents.Count - 1 do
    if TIdStrings.Icmp(FNamedEvents[LIndex].Name, AEventName) = 0 then
    begin
      UpdateWinVars;
      if (FStore.RegisterCount > 0) and (FStore.OpCount > 0) then
        EvalRegs(-1, True);
      RunScriptList(FNamedEvents[LIndex].Script);
      Break;
    end;
  for LIndex := 0 to FChildren.Count - 1 do
    FChildren[LIndex].RunNamedEvent(AEventName);
end;

procedure TGuiWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
var
  LIndex: Integer;
begin
  UpdateWinVars;
  if AActivate then
    RunScript(seActivate)
  else
    RunScript(seDeactivate);
  for LIndex := 0 to FChildren.Count - 1 do
    FChildren[LIndex].Activate(AActivate, AAct);
  if AAct <> '' then
    AAct := AAct + ' ; ';
end;

procedure TGuiWindow.Trigger;
var
  LIndex: Integer;
begin
  RunScript(seTrigger);
  for LIndex := 0 to FChildren.Count - 1 do
    FChildren[LIndex].Trigger;
  StateChanged(True);
end;

procedure TGuiWindow.StateChanged(const ARedraw: Boolean);
var
  LIndex: Integer;
begin
  UpdateWinVars;
  if (FStore.RegisterCount > 0) and (FStore.OpCount > 0) then
    EvalRegs;
  for LIndex := 0 to FDrawWindows.Count - 1 do
    if not FDrawWindows[LIndex].IsSimple then
      FDrawWindows[LIndex].Window.StateChanged(ARedraw);
end;

function TGuiWindow.Interactive: Boolean;
var
  LIndex: Integer;
begin
  if Assigned(FScripts[seAction]) then
    Exit(True);
  for LIndex := 0 to FChildren.Count - 1 do
    if FChildren[LIndex].Interactive then
      Exit(True);
  Result := False;
end;

function TGuiWindow.ContainsStateVars: Boolean;
var
  LIndex: Integer;
begin
  if FUpdateVars.Count > 0 then
    Exit(True);
  for LIndex := 0 to FChildren.Count - 1 do
    if FChildren[LIndex].ContainsStateVars then
      Exit(True);
  Result := False;
end;

function TGuiWindow.NumTransitions: Integer;
var
  LIndex: Integer;
begin
  Result := FTransitions.Count;
  for LIndex := 0 to FChildren.Count - 1 do
    Inc(Result, FChildren[LIndex].NumTransitions);
end;

procedure TGuiWindow.ClientToScreen(var ARect: TGuiRectangle);
var
  LWindow: TGuiWindow;
  LX: Integer;
  LY: Integer;
begin
  LX := 0;
  LY := 0;
  LWindow := Self;
  while Assigned(LWindow) do
  begin
    // the sums are integers in the original
    LX := Trunc(LX + LWindow.FRect.Value.X);
    LY := Trunc(LY + LWindow.FRect.Value.Y);
    LWindow := LWindow.FParent;
  end;
  ARect.X := ARect.X + LX;
  ARect.Y := ARect.Y + LY;
end;

procedure TGuiWindow.ScreenToClient(var ARect: TGuiRectangle);
var
  LWindow: TGuiWindow;
  LX: Integer;
  LY: Integer;
begin
  LX := 0;
  LY := 0;
  LWindow := Self;
  while Assigned(LWindow) do
  begin
    LX := Trunc(LX + LWindow.FRect.Value.X);
    LY := Trunc(LY + LWindow.FRect.Value.Y);
    LWindow := LWindow.FParent;
  end;
  ARect.X := ARect.X - LX;
  ARect.Y := ARect.Y - LY;
end;

end.
