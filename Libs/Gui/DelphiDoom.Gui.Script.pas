{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiScript and TGuiScriptList, the scripts of a   }
{  window (onAction, onTime, ...)                                              }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\GuiScript.h,            }
{  GuiScript.cpp (idGuiScript, idGuiScriptList, the Script_* functions).       }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Script;

interface

uses
  System.Generics.Collections, DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.WinVar.Base,
  DelphiDoom.Gui.Window.Intf;

type
  /// <summary>The command of a script line (the <c>handler</c> function pointer of the original)</summary>
  TGuiScriptCommand = (scUnknown, scSet, scSetFocus, scEndGame, scResetTime, scShowCursor, scResetCinematics,
    scTransition, scLocalSound, scRunScript, scEvalRegs);

  /// <summary>idGSWinVar: a parameter of a command; owned if the script made it (a variable of a window is not)</summary>
  TGuiScriptParm = record
    Variable: TGuiWinVar;
    Owned: Boolean;
  end;

  TGuiScriptList = class;

  /// <summary>
  ///   idGuiScript: one command with its parameters (read as strings, then turned into variables by
  ///   <c>FixupParms</c>), or an <c>if</c> with its two lists. The commands are the ten of
  ///   <c>commandList</c>; they act on the window through <c>IGuiWindowNode</c> and on the game through <c>IGuiGameHost</c>.
  /// </summary>
  TGuiScript = class
  strict private
    FConditionReg: Integer;
    FIfList: TGuiScriptList;
    FElseList: TGuiScriptList;
    FParms: TList<TGuiScriptParm>;
    FCommand: TGuiScriptCommand;
    procedure SetParm(const AIndex: Integer; const AVariable: TGuiWinVar; const AOwned: Boolean);
    function StrParm(const AIndex: Integer): TGuiWinVar;
    procedure FixupSet(const AWindow: IGuiWindowNode);
    procedure FixupTransition(const AWindow: IGuiWindowNode);
    procedure ExecuteSet(const AWindow: IGuiWindowNode);
    procedure ExecuteTransition(const AWindow: IGuiWindowNode);
    procedure ExecuteResetTime(const AWindow: IGuiWindowNode);
    function GetParmCount: Integer;
    function GetParms(const AIndex: Integer): TGuiScriptParm;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   idGuiScript::Parse: the command name, then the parameters up to ";" (a "}" is left for the caller).
    ///   An unknown command or a wrong number of parameters is an error of the parser (a warning with the
    ///   flags of the gui); the line is kept.
    /// </summary>
    function Parse(const ASource: TIdParser): Boolean;
    procedure Execute(const AWindow: IGuiWindowNode);
    procedure FixupParms(const AWindow: IGuiWindowNode);
    property ConditionReg: Integer read FConditionReg write FConditionReg;
    property IfList: TGuiScriptList read FIfList write FIfList;
    property ElseList: TGuiScriptList read FElseList write FElseList;
    property Command: TGuiScriptCommand read FCommand;
    property ParmCount: Integer read GetParmCount;
    property Parms[const AIndex: Integer]: TGuiScriptParm read GetParms;
  end;

  /// <summary>idGuiScriptList: the commands of a script in order; it owns them</summary>
  TGuiScriptList = class
  strict private
    FList: TObjectList<TGuiScript>;
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TGuiScript;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Append(const AScript: TGuiScript);
    /// <summary>
    ///   Execute: a line with a condition evaluates the registers of the window (only if it has
    ///   operations) and runs the if or the else list, then the command of the line itself
    /// </summary>
    procedure Execute(const AWindow: IGuiWindowNode);
    procedure FixupParms(const AWindow: IGuiWindowNode);
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TGuiScript read GetItems; default;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.WinVar.Float,
  DelphiDoom.Gui.WinVar.Rectangle, DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.WinVar.Vec4;

type
  TGuiCommandDef = record
    Name: AnsiString;
    Command: TGuiScriptCommand;
    MinParms: Integer;
    MaxParms: Integer;
  end;

const
  // commandList
  COMMANDS: array[0..9] of TGuiCommandDef = (
    (Name: 'set'; Command: scSet; MinParms: 2; MaxParms: 999),
    (Name: 'setFocus'; Command: scSetFocus; MinParms: 1; MaxParms: 1),
    (Name: 'endGame'; Command: scEndGame; MinParms: 0; MaxParms: 0),
    (Name: 'resetTime'; Command: scResetTime; MinParms: 0; MaxParms: 2),
    (Name: 'showCursor'; Command: scShowCursor; MinParms: 1; MaxParms: 1),
    (Name: 'resetCinematics'; Command: scResetCinematics; MinParms: 0; MaxParms: 2),
    (Name: 'transition'; Command: scTransition; MinParms: 4; MaxParms: 6),
    (Name: 'localSound'; Command: scLocalSound; MinParms: 1; MaxParms: 1),
    (Name: 'runScript'; Command: scRunScript; MinParms: 1; MaxParms: 1),
    (Name: 'evalRegs'; Command: scEvalRegs; MinParms: 0; MaxParms: 0));

  STRTABLE_ID = '#str_';

{ TGuiScript }

constructor TGuiScript.Create;
begin
  inherited Create;
  FConditionReg := -1;
  FCommand := scUnknown;
  FParms := TList<TGuiScriptParm>.Create;
end;

destructor TGuiScript.Destroy;
var
  LIndex: Integer;
begin
  FIfList.Free;
  FElseList.Free;
  for LIndex := 0 to FParms.Count - 1 do
    if FParms[LIndex].Owned then
      FParms[LIndex].Variable.Free;
  FParms.Free;
  inherited Destroy;
end;

function TGuiScript.GetParmCount: Integer;
begin
  Result := FParms.Count;
end;

function TGuiScript.GetParms(const AIndex: Integer): TGuiScriptParm;
begin
  Result := FParms[AIndex];
end;

procedure TGuiScript.SetParm(const AIndex: Integer; const AVariable: TGuiWinVar; const AOwned: Boolean);
var
  LParm: TGuiScriptParm;
begin
  LParm.Variable := AVariable;
  LParm.Owned := AOwned;
  FParms[AIndex] := LParm;
end;

function TGuiScript.StrParm(const AIndex: Integer): TGuiWinVar;
begin
  Result := nil;
  if (AIndex < FParms.Count) and (FParms[AIndex].Variable is TGuiWinStr) then
    Result := FParms[AIndex].Variable;
end;

function TGuiScript.Parse(const ASource: TIdParser): Boolean;
var
  LToken: TIdToken;
  LIndex: Integer;
  LDefIndex: Integer;
  LParm: TGuiScriptParm;
  LString: TGuiWinStr;
begin
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
  begin
    ASource.Error('Unexpected end of file');
    Exit(False);
  end;
  FCommand := scUnknown;
  LDefIndex := -1;
  for LIndex := Low(COMMANDS) to High(COMMANDS) do
    if TIdStrings.Icmp(LToken.Text, COMMANDS[LIndex].Name) = 0 then
    begin
      FCommand := COMMANDS[LIndex].Command;
      LDefIndex := LIndex;
      Break;
    end;
  if FCommand = scUnknown then
    ASource.Error('Uknown script call ' + string(LToken.Text));
  // the parameters up to ";" are strings; FixupParms makes them variables
  while True do
  begin
    if not ASource.ReadToken(LToken) then
    begin
      ASource.Error('Unexpected end of file');
      Exit(False);
    end;
    if TIdStrings.Icmp(LToken.Text, ';') = 0 then
      Break;
    if TIdStrings.Icmp(LToken.Text, '}') = 0 then
    begin
      ASource.UnreadToken(LToken);
      Break;
    end;
    LString := TGuiWinStr.Create;
    LString.Value := LToken.Text;
    LParm.Variable := LString;
    LParm.Owned := True;
    FParms.Add(LParm);
  end;
  if (LDefIndex >= 0) and ((FParms.Count < COMMANDS[LDefIndex].MinParms) or
    (FParms.Count > COMMANDS[LDefIndex].MaxParms)) then
    ASource.Error('incorrect number of parameters for script ' + string(COMMANDS[LDefIndex].Name));
  Result := True;
end;

procedure TGuiScript.ExecuteSet(const AWindow: IGuiWindowNode);
var
  LDest: TGuiWinVar;
  LValue: AnsiString;
  LIndex: Integer;
begin
  LDest := StrParm(0);
  if Assigned(LDest) and (TIdStrings.Icmp(LDest.AsText, 'cmd') = 0) then
  begin
    LDest := StrParm(1);
    if not Assigned(LDest) then
      Exit;
    if FParms.Count > 2 then
    begin
      LValue := LDest.AsText;
      for LIndex := 2 to FParms.Count - 1 do
        LValue := LValue + ' "' + FParms[LIndex].Variable.AsText + '"';
      AWindow.AddCommand(LValue);
    end
    else
      AWindow.AddCommand(LDest.AsText);
    Exit;
  end;
  // a line with too few parameters was reported by the parser; it does nothing
  if FParms.Count < 2 then
    Exit;
  FParms[0].Variable.SetFromText(FParms[1].Variable.AsText);
  FParms[0].Variable.Eval := False;
end;

procedure TGuiScript.ExecuteResetTime(const AWindow: IGuiWindowNode);
var
  LNode: IGuiWindowNode;
  LSimple: Boolean;
  LParm: TGuiWinVar;
  LTime: Integer;
begin
  LNode := nil;
  LSimple := False;
  LParm := StrParm(0);
  if Assigned(LParm) and (FParms.Count > 1) then
  begin
    LNode := AWindow.GetDesktop.FindChildByName(LParm.AsText, LSimple);
    LParm := StrParm(1);
  end;
  if Assigned(LParm) then
    LTime := TIdCNumbers.Atoi(LParm.AsText)
  else
    LTime := 0;
  if Assigned(LNode) and not LSimple then
  begin
    LNode.ResetTime(LTime);
    LNode.EvalRegs(-1, True);
  end
  else
  begin
    AWindow.ResetTime(LTime);
    AWindow.EvalRegs(-1, True);
  end;
end;

procedure TGuiScript.ExecuteTransition(const AWindow: IGuiWindowNode);
var
  LDest: TGuiWinVar;
  LFrom: TGuiWinVar;
  LTo: TGuiWinVar;
  LTimeStr: TGuiWinVar;
  LTime: Integer;
  LAccel: Single;
  LDecel: Single;
begin
  // transitions always affect a rectangle, a vec4 or a float
  if FParms.Count < 4 then
    Exit;
  LDest := FParms[0].Variable;
  LFrom := FParms[1].Variable;
  LTo := FParms[2].Variable;
  LTimeStr := StrParm(3);
  if not (((LDest is TGuiWinVec4) or (LDest is TGuiWinRectangle) or (LDest is TGuiWinFloat)) and
    (LFrom is TGuiWinVec4) and (LTo is TGuiWinVec4) and Assigned(LTimeStr)) then
  begin
    AWindow.Warning(Format('Bad transition in gui %s in window %s', [string(AWindow.GetSourceFile),
      string(AWindow.GetName)]));
    Exit;
  end;
  LTime := TIdCNumbers.Atoi(LTimeStr.AsText);
  LAccel := 0.0;
  LDecel := 0.0;
  if (FParms.Count > 5) and Assigned(StrParm(4)) and Assigned(StrParm(5)) then
  begin
    LAccel := TIdCNumbers.Atof(StrParm(4).AsText);
    LDecel := TIdCNumbers.Atof(StrParm(5).AsText);
  end;
  LDest.Eval := False;
  AWindow.AddTransition(LDest, TGuiWinVec4(LFrom).Value, TGuiWinVec4(LTo).Value, LTime, LAccel, LDecel);
  AWindow.StartTransition;
end;

procedure TGuiScript.Execute(const AWindow: IGuiWindowNode);
var
  LParm: TGuiWinVar;
  LNode: IGuiWindowNode;
  LSimple: Boolean;
  LHost: IGuiGameHost;
begin
  case FCommand of
    scSet:
      ExecuteSet(AWindow);
    scSetFocus:
      begin
        LParm := StrParm(0);
        if Assigned(LParm) then
        begin
          LNode := AWindow.GetDesktop.FindChildByName(LParm.AsText, LSimple);
          if Assigned(LNode) and not LSimple then
            AWindow.SetFocus(LNode);
        end;
      end;
    scShowCursor:
      begin
        LParm := StrParm(0);
        if Assigned(LParm) then
        begin
          if TIdCNumbers.Atoi(LParm.AsText) <> 0 then
            AWindow.GetDesktop.ClearFlag(WIN_NOCURSOR)
          else
            AWindow.GetDesktop.SetFlag(WIN_NOCURSOR);
        end;
      end;
    scRunScript:
      begin
        LParm := StrParm(0);
        if Assigned(LParm) then
          AWindow.SetCommand(AWindow.GetCommand + ' ; runScript ' + LParm.AsText);
      end;
    scLocalSound:
      begin
        LParm := StrParm(0);
        LHost := AWindow.GetGameHost;
        if Assigned(LParm) and Assigned(LHost) then
          LHost.LocalSound(LParm.AsText);
      end;
    scEvalRegs:
      AWindow.EvalRegs(-1, True);
    scEndGame:
      begin
        LHost := AWindow.GetGameHost;
        if Assigned(LHost) then
          LHost.EndGame;
      end;
    scResetTime:
      ExecuteResetTime(AWindow);
    scResetCinematics:
      AWindow.ResetCinematics;
    scTransition:
      ExecuteTransition(AWindow);
  end;
end;

procedure TGuiScript.FixupSet(const AWindow: IGuiWindowNode);
var
  LString: TGuiWinVar;
  LDest: TGuiWinVar;
  LOwner: IGuiWindowNode;
  LDefined: TGuiWinStr;
  LIndex: Integer;
  LText: AnsiString;
begin
  LString := StrParm(0);
  if not Assigned(LString) then
    Exit;
  LDest := AWindow.GetWinVarByName(LString.AsText, True, LOwner);
  if Assigned(LDest) then
  begin
    FParms[0].Variable.Free;
    SetParm(0, LDest, False);
  end;
  for LIndex := 1 to FParms.Count - 1 do
  begin
    LString := StrParm(LIndex);
    if not Assigned(LString) then
      Continue;
    LText := LString.AsText;
    if TIdStrings.Icmpn(LText, 'gui::', 5) = 0 then
    begin
      // always a string; the window owns it (the original makes a duplicate each time)
      LDefined := TGuiWinStr.Create;
      AWindow.InitVar(LDefined, LText);
      AWindow.AddDefinedVar(LDefined);
      FParms[LIndex].Variable.Free;
      SetParm(LIndex, LDefined, False);
    end
    else if (LText <> '') and (LText[1] = '$') then
    begin
      LDest := AWindow.GetDesktop.GetWinVarByName(Copy(LText, 2, MaxInt), True, LOwner);
      if Assigned(LDest) then
      begin
        FParms[LIndex].Variable.Free;
        SetParm(LIndex, LDest, False);
      end;
    end
    else if TIdStrings.Cmpn(LText, STRTABLE_ID, Length(STRTABLE_ID)) = 0 then
      LString.SetFromText(AWindow.TranslateString(LText));
  end;
end;

procedure TGuiScript.FixupTransition(const AWindow: IGuiWindowNode);
var
  LString: TGuiWinVar;
  LDest: TGuiWinVar;
  LDestOwner: IGuiWindowNode;
  LOwner: IGuiWindowNode;
  LVec: TGuiWinVec4;
  LIndex: Integer;
  LText: AnsiString;
  LRect: TGuiRectangle;
  LIgnored: IGuiWindowNode;
begin
  if FParms.Count < 4 then
    AWindow.Warning(Format('Window %s in gui %s has a bad transition definition', [string(AWindow.GetName),
      string(AWindow.GetSourceFile)]));
  LString := StrParm(0);
  if not Assigned(LString) then
    Exit;
  LDest := AWindow.GetWinVarByName(LString.AsText, True, LDestOwner);
  if Assigned(LDest) then
  begin
    FParms[0].Variable.Free;
    SetParm(0, LDest, False);
  end
  else
    AWindow.Warning(Format('Window %s in gui %s: a transition does not have a valid destination var %s',
      [string(AWindow.GetName), string(AWindow.GetSourceFile), string(LString.AsText)]));
  // the start and end values can be variables ("$name")
  for LIndex := 1 to 2 do
  begin
    LString := StrParm(LIndex);
    if not Assigned(LString) then
      Continue;
    LText := LString.AsText;
    LVec := TGuiWinVec4.Create;
    SetParm(LIndex, LVec, True);
    LDest := nil;
    LOwner := nil;
    if (LText <> '') and (LText[1] = '$') then
      LDest := AWindow.GetWinVarByName(Copy(LText, 2, MaxInt), True, LOwner);
    if Assigned(LDest) then
    begin
      if Assigned(LOwner) and Assigned(LDestOwner) and Assigned(LOwner.GetParent) and
        Assigned(LDestOwner.GetParent) and (LDest = LOwner.GetWinVarByName('rect', False, LIgnored)) and
        (LDest is TGuiWinRectangle) then
      begin
        // a rectangle of another window: from its parent's client space to the one of the destination's parent
        LRect := TGuiWinRectangle(LDest).Value;
        LOwner.GetParent.ClientToScreen(LRect);
        LDestOwner.GetParent.ScreenToClient(LRect);
        LVec.Value := LRect.ToVec4;
      end
      else
        LVec.SetFromText(LDest.AsText);
    end
    else
      LVec.SetFromText(LText);
    LString.Free;
  end;
end;

procedure TGuiScript.FixupParms(const AWindow: IGuiWindowNode);
var
  LIndex: Integer;
begin
  case FCommand of
    scSet:
      FixupSet(AWindow);
    scTransition:
      FixupTransition(AWindow);
  else
    for LIndex := 0 to FParms.Count - 1 do
      AWindow.InitVar(FParms[LIndex].Variable, FParms[LIndex].Variable.AsText);
  end;
end;

{ TGuiScriptList }

constructor TGuiScriptList.Create;
begin
  inherited Create;
  FList := TObjectList<TGuiScript>.Create(True);
end;

destructor TGuiScriptList.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

function TGuiScriptList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TGuiScriptList.GetItems(const AIndex: Integer): TGuiScript;
begin
  Result := FList[AIndex];
end;

procedure TGuiScriptList.Append(const AScript: TGuiScript);
begin
  FList.Add(AScript);
end;

procedure TGuiScriptList.Execute(const AWindow: IGuiWindowNode);
var
  LIndex: Integer;
  LScript: TGuiScript;
begin
  for LIndex := 0 to FList.Count - 1 do
  begin
    LScript := FList[LIndex];
    if LScript.ConditionReg >= 0 then
    begin
      if AWindow.HasOps then
      begin
        if AWindow.EvalRegs(LScript.ConditionReg) <> 0.0 then
        begin
          if Assigned(LScript.IfList) then
            LScript.IfList.Execute(AWindow);
        end
        else if Assigned(LScript.ElseList) then
          LScript.ElseList.Execute(AWindow);
      end;
    end;
    LScript.Execute(AWindow);
  end;
end;

procedure TGuiScriptList.FixupParms(const AWindow: IGuiWindowNode);
var
  LIndex: Integer;
  LScript: TGuiScript;
begin
  for LIndex := 0 to FList.Count - 1 do
  begin
    LScript := FList[LIndex];
    LScript.FixupParms(AWindow);
    if Assigned(LScript.IfList) then
      LScript.IfList.FixupParms(AWindow);
    if Assigned(LScript.ElseList) then
      LScript.ElseList.FixupParms(AWindow);
  end;
end;

end.
