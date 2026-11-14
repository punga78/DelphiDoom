{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiChoiceWindow (choiceDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\ChoiceWindow.h,         }
{  ChoiceWindow.cpp (idChoiceWindow: the parse and the choice lists).          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Choice;

interface

uses
  System.Generics.Collections, DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window,
  DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Str,
  DelphiDoom.Gui.Window.Keys;

type
  /// <summary>
  ///   idChoiceWindow: the keys <c>choicetype</c> and <c>currentchoice</c>, the variables
  ///   <c>choices</c>, <c>values</c>, <c>cvar</c>, <c>gui</c>, <c>liveUpdate</c> and <c>updateGroup</c>, and the
  ///   lists of choices and values that are cut from the two strings after the parse. Not ported:
  ///   the cvar (<c>InitVars</c>, <c>UpdateVars</c>), the mouse and keys.
  /// </summary>
  TGuiChoiceWindow = class(TGuiWindow)
  strict private
    FCurrentChoice: Integer;
    FChoiceType: Integer;
    FLatchedChoices: AnsiString;
    FLatchedValues: AnsiString;
    FChoicesStr: TGuiWinStr;
    FChoiceVals: TGuiWinStr;
    FGuiStr: TGuiWinStr;
    FCvarStr: TGuiWinStr;
    FLiveUpdate: TGuiWinBool;
    FUpdateGroup: TGuiWinStr;
    FChoices: TList<AnsiString>;
    FValues: TList<AnsiString>;
    FUpdateStr: TList<TGuiWinVar>;
    FCvarFound: Boolean;
    FCvarName: AnsiString;
    procedure ValidateChoice;
    procedure InitVars;
    procedure UpdateChoice;
    procedure UpdateVars(const ARead: Boolean; const AForce: Boolean = False);
    function ChoiceText: AnsiString;
    function Tokens(const AText, AName: AnsiString; const AFlags: Integer): TArray<AnsiString>;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    function HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString; override;
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString); override;
    procedure RunNamedEvent(const AEventName: AnsiString); override;
    /// <summary>UpdateChoicesAndVals: cuts the strings at ";" when they changed since the last time</summary>
    procedure UpdateChoicesAndVals;
    property CurrentChoice: Integer read FCurrentChoice;
    property ChoiceType: Integer read FChoiceType;
    property Choices: TList<AnsiString> read FChoices;
    property Values: TList<AnsiString> read FValues;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.DrawContext, DelphiDoom.Gui.Rectangle,
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Gui.Window.Types;

constructor TGuiChoiceWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FChoicesStr := TGuiWinStr.Create;
  FChoiceVals := TGuiWinStr.Create;
  FGuiStr := TGuiWinStr.Create;
  FCvarStr := TGuiWinStr.Create;
  FLiveUpdate := TGuiWinBool.Create;
  FUpdateGroup := TGuiWinStr.Create;
  FChoices := TList<AnsiString>.Create;
  FValues := TList<AnsiString>.Create;
  FUpdateStr := TList<TGuiWinVar>.Create;
  FCurrentChoice := 0;
  FChoiceType := 0;
  FLiveUpdate.Value := True;
end;

destructor TGuiChoiceWindow.Destroy;
begin
  FUpdateStr.Free;
  FValues.Free;
  FChoices.Free;
  FUpdateGroup.Free;
  FLiveUpdate.Free;
  FCvarStr.Free;
  FGuiStr.Free;
  FChoiceVals.Free;
  FChoicesStr.Free;
  inherited Destroy;
end;

function TGuiChoiceWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  if TIdStrings.Icmp(AName, 'choicetype') = 0 then
  begin
    FChoiceType := ASource.ParseInt;
    Exit(True);
  end;
  if TIdStrings.Icmp(AName, 'currentchoice') = 0 then
  begin
    FCurrentChoice := ASource.ParseInt;
    Exit(True);
  end;
  Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiChoiceWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'choices') = 0 then
    Exit(FChoicesStr);
  if TIdStrings.Icmp(AName, 'values') = 0 then
    Exit(FChoiceVals);
  if TIdStrings.Icmp(AName, 'cvar') = 0 then
    Exit(FCvarStr);
  if TIdStrings.Icmp(AName, 'gui') = 0 then
    Exit(FGuiStr);
  if TIdStrings.Icmp(AName, 'liveUpdate') = 0 then
    Exit(FLiveUpdate);
  if TIdStrings.Icmp(AName, 'updateGroup') = 0 then
    Exit(FUpdateGroup);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

function TGuiChoiceWindow.Tokens(const AText, AName: AnsiString; const AFlags: Integer): TArray<AnsiString>;
var
  LParser: TIdParser;
  LToken: TIdToken;
  LList: TList<AnsiString>;
begin
  LList := TList<AnsiString>.Create;
  LParser := TIdParser.Create(AFlags, Context.Log);
  try
    LToken := TIdToken.Create;
    if LParser.LoadMemory(AText, Length(AText), AName) then
      while LParser.ReadToken(LToken) do
        LList.Add(LToken.Text);
    Result := LList.ToArray;
  finally
    LParser.Free;
    LList.Free;
  end;
end;

procedure TGuiChoiceWindow.UpdateChoicesAndVals;
var
  LToken: AnsiString;
  LText: AnsiString;
  LNegative: Boolean;
begin
  if TIdStrings.Icmp(FLatchedChoices, FChoicesStr.AsText) <> 0 then
  begin
    FChoices.Clear;
    LText := '';
    for LToken in Tokens(FChoicesStr.AsText, '<ChoiceList>', LEXFL_NOFATALERRORS or LEXFL_ALLOWPATHNAMES or
      LEXFL_ALLOWMULTICHARLITERALS or LEXFL_ALLOWBACKSLASHSTRINGCONCAT) do
    begin
      if LToken = ';' then
      begin
        if LText <> '' then
        begin
          FChoices.Add(TranslateString(AnsiString(TrimRight(string(LText)))));
          LText := '';
        end;
        Continue;
      end;
      LText := LText + LToken + ' ';
    end;
    if LText <> '' then
      FChoices.Add(AnsiString(TrimRight(string(LText))));
    FLatchedChoices := FChoicesStr.AsText;
  end;
  if (FChoiceVals.Length > 0) and (TIdStrings.Icmp(FLatchedValues, FChoiceVals.AsText) <> 0) then
  begin
    FValues.Clear;
    LText := '';
    LNegative := False;
    for LToken in Tokens(FChoiceVals.AsText, '<ChoiceVals>', LEXFL_ALLOWPATHNAMES or LEXFL_ALLOWMULTICHARLITERALS or
      LEXFL_ALLOWBACKSLASHSTRINGCONCAT) do
    begin
      if LToken = '-' then
      begin
        LNegative := True;
        Continue;
      end;
      if LToken = ';' then
      begin
        if LText <> '' then
        begin
          FValues.Add(AnsiString(TrimRight(string(LText))));
          LText := '';
        end;
        Continue;
      end;
      if LNegative then
      begin
        LText := LText + '-';
        LNegative := False;
      end;
      LText := LText + LToken + ' ';
    end;
    if LText <> '' then
      FValues.Add(AnsiString(TrimRight(string(LText))));
    if FChoices.Count <> FValues.Count then
      Warning(Format('idChoiceWindow:: gui ''%s'' window ''%s'' has value count unequal to choices count',
        [string(Context.SourceFile), string(Name)]));
    FLatchedValues := FChoiceVals.AsText;
  end;
end;

procedure TGuiChoiceWindow.ValidateChoice;
begin
  if (FCurrentChoice < 0) or (FCurrentChoice >= FChoices.Count) then
    FCurrentChoice := 0;
  if FChoices.Count = 0 then
    FChoices.Add('No Choices Defined');
end;

procedure TGuiChoiceWindow.InitVars;
var
  LVar: TGuiWinVar;
begin
  if FCvarStr.Length > 0 then
  begin
    FCvarFound := Assigned(Context.Cvars) and Context.Cvars.Exists(FCvarStr.AsText);
    if not FCvarFound then
    begin
      Warning(Format('idChoiceWindow::InitVars: gui ''%s'' window ''%s'' references undefined cvar ''%s''',
        [string(Context.SourceFile), string(Name), string(FCvarStr.AsText)]));
      Exit;
    end;
    FCvarName := FCvarStr.AsText;
    FUpdateStr.Add(FCvarStr);
  end;
  if FGuiStr.Length > 0 then
    FUpdateStr.Add(FGuiStr);
  // idMultiWinVar::SetGuiInfo: each variable is bound to the key that is its own text
  for LVar in FUpdateStr do
    LVar.SetGuiInfo(Context.StateDict, LVar.AsText);
  for LVar in FUpdateStr do
    LVar.Update;
end;

procedure TGuiChoiceWindow.UpdateVars(const ARead: Boolean; const AForce: Boolean);
begin
  if AForce or FLiveUpdate.Value then
  begin
    if FCvarFound and FCvarStr.NeedsUpdate then
    begin
      if ARead then
        FCvarStr.SetFromText(Context.Cvars.GetString(FCvarName))
      else
        Context.Cvars.SetString(FCvarName, FCvarStr.AsText);
    end;
    if (not ARead) and FGuiStr.NeedsUpdate then
      FGuiStr.SetFromText(AnsiString(IntToStr(FCurrentChoice)));
  end;
end;

procedure TGuiChoiceWindow.UpdateChoice;
var
  LCount, LIndex: Integer;
  LList: TList<AnsiString>;
  LVar: TGuiWinVar;
begin
  if FUpdateStr.Count = 0 then
    Exit;
  UpdateVars(True);
  for LVar in FUpdateStr do
    LVar.Update;
  if FChoiceType = 0 then
  begin
    // the choice is an integer in the cvar or the gui; the cvar wins
    if FUpdateStr[0].NeedsUpdate then
      FCurrentChoice := TIdCNumbers.Atoi(FUpdateStr[0].AsText);
    ValidateChoice;
  end
  else
  begin
    if FValues.Count > 0 then
      LList := FValues
    else
      LList := FChoices;
    LCount := LList.Count;
    LIndex := 0;
    while LIndex < LCount do
    begin
      if TIdStrings.Icmp(FCvarStr.AsText, LList[LIndex]) = 0 then
        Break;
      Inc(LIndex);
    end;
    if LIndex = LCount then
      LIndex := 0;
    FCurrentChoice := LIndex;
    ValidateChoice;
  end;
end;

procedure TGuiChoiceWindow.PostParse;
begin
  inherited PostParse;
  UpdateChoicesAndVals;
  InitVars;
  UpdateChoice;
  UpdateVars(False);
  SetFlag(WIN_CANFOCUS);
end;

function TGuiChoiceWindow.ChoiceText: AnsiString;
begin
  // the original reads choices[currentChoice] whatever the index
  if (FCurrentChoice >= 0) and (FCurrentChoice < FChoices.Count) then
    Result := FChoices[FCurrentChoice]
  else
    Result := '';
end;

procedure TGuiChoiceWindow.RunNamedEvent(const AEventName: AnsiString);
var
  LGroup: AnsiString;
begin
  if TIdStrings.Icmpn(AEventName, 'cvar read ', 10) = 0 then
  begin
    // idStr::Cmpn is case sensitive
    if Copy(AEventName, 1, 10) = 'cvar read ' then
    begin
      LGroup := Copy(AEventName, 11, MaxInt);
      if LGroup = FUpdateGroup.AsText then
        UpdateVars(True, True);
    end;
  end
  else if Copy(AEventName, 1, 11) = 'cvar write ' then
  begin
    LGroup := Copy(AEventName, 12, MaxInt);
    if LGroup = FUpdateGroup.AsText then
      UpdateVars(False, True);
  end;
end;

function TGuiChoiceWindow.HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString;
var
  LKey, LIndex, LPotential: Integer;
  LRunAction, LRunAction2: Boolean;
  LFirst: Integer;
begin
  LRunAction := False;
  LRunAction2 := False;
  if AEvent.EventType = GUI_SE_KEY then
  begin
    LKey := AEvent.Value;
    if (LKey = GUI_K_RIGHTARROW) or (LKey = GUI_K_KP_RIGHTARROW) or (LKey = GUI_K_MOUSE1) then
    begin
      // never affects the state, but we want to execute script handlers anyway
      if AEvent.Value2 = 0 then
      begin
        RunScript(seActionRelease);
        Exit(Command);
      end;
      Inc(FCurrentChoice);
      if FCurrentChoice >= FChoices.Count then
        FCurrentChoice := 0;
      LRunAction := True;
    end;
    if (LKey = GUI_K_LEFTARROW) or (LKey = GUI_K_KP_LEFTARROW) or (LKey = GUI_K_MOUSE2) then
    begin
      if AEvent.Value2 = 0 then
      begin
        RunScript(seActionRelease);
        Exit(Command);
      end;
      Dec(FCurrentChoice);
      if FCurrentChoice < 0 then
        FCurrentChoice := FChoices.Count - 1;
      LRunAction := True;
    end;
    if AEvent.Value2 = 0 then
      // is a key release with no action catch
      Exit('');
  end
  else if AEvent.EventType = GUI_SE_CHAR then
  begin
    LKey := AEvent.Value;
    LPotential := -1;
    for LIndex := 0 to FChoices.Count - 1 do
    begin
      if FChoices[LIndex] = '' then
        LFirst := 0
      else
        LFirst := Ord(FChoices[LIndex][1]);
      if (LKey < 128) and (LFirst < 128) and (Ord(UpCase(Chr(LKey and $7F))) = Ord(UpCase(Chr(LFirst)))) or
        ((LKey >= 128) and (LKey = LFirst)) then
      begin
        if (LIndex < FCurrentChoice) and (LPotential < 0) then
          LPotential := LIndex
        else if LIndex > FCurrentChoice then
        begin
          LPotential := -1;
          FCurrentChoice := LIndex;
          Break;
        end;
      end;
    end;
    if LPotential >= 0 then
      FCurrentChoice := LPotential;
    LRunAction := True;
    LRunAction2 := True;
  end
  else
    Exit('');
  if LRunAction then
    RunScript(seAction);
  if FChoiceType = 0 then
    FCvarStr.SetFromText(AnsiString(IntToStr(FCurrentChoice)))
  else if FValues.Count > 0 then
  begin
    if (FCurrentChoice >= 0) and (FCurrentChoice < FValues.Count) then
      FCvarStr.SetFromText(FValues[FCurrentChoice])
    else
      FCvarStr.SetFromText('');
  end
  else
    FCvarStr.SetFromText(ChoiceText);
  UpdateVars(False);
  if LRunAction2 then
    RunScript(seActionRelease);
  Result := Command;
end;

procedure TGuiChoiceWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LColor: TIdVec4;
  LDc: TGuiDrawContext;
  LShadow: TGuiRectangle;
begin
  LColor := ForeColor.Value;
  LDc := Context.DrawContext;
  UpdateChoicesAndVals;
  UpdateChoice;
  // FIXME of the original: textAlign would be nice, but many guis have it set wrong
  TextAlign := 0;
  if TextShadow <> 0 then
  begin
    LShadow := TextRect;
    LShadow.X := LShadow.X + TextShadow;
    LShadow.Y := LShadow.Y + TextShadow;
    LDc.DrawText(TIdStrings.RemoveColors(ChoiceText), TextScale.Value, TextAlign, LDc.ColorBlack, LShadow, False, -1);
  end;
  if Hover and (not NoEvents.Value) and ContainsPoint(Context.CursorX, Context.CursorY) then
    LColor := HoverColor.Value
  else
    Hover := False;
  if (Flags and WIN_FOCUS) <> 0 then
    LColor := HoverColor.Value;
  LDc.DrawText(ChoiceText, TextScale.Value, TextAlign, LColor, TextRect, False, -1);
end;

procedure TGuiChoiceWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
begin
  inherited Activate(AActivate, AAct);
  if AActivate then
    // sets the gui state based on the current choice the window contains
    UpdateChoice;
end;
end.
