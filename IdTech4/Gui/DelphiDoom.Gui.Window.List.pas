{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiListWindow (listDef)                          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\ListWindow.h,           }
{  ListWindow.cpp (idListWindow: the parse and the tab stops).                 }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.List;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context,
  DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Slider, DelphiDoom.Gui.Window.Keys;

const
  /// <summary>tabBorder of ListWindow.cpp</summary>
  GUI_LIST_TAB_BORDER = 4;
  /// <summary>TAB_TYPE_TEXT</summary>
  GUI_TAB_TYPE_TEXT = 0;
  /// <summary>TAB_TYPE_ICON</summary>
  GUI_TAB_TYPE_ICON = 1;
  /// <summary>MAX_LIST_ITEMS of Window.h</summary>
  GUI_MAX_LIST_ITEMS = 1024;

type
  /// <summary>idTabRect: a column of the list</summary>
  TGuiTabRect = record
    Start: Integer;
    Width: Integer;
    Align: Integer;
    VAlign: Integer;
    TabType: Integer;
    IconSize: TIdVec2;
    IconVOffset: Single;
  end;

  /// <summary>
  ///   idListWindow: the keys <c>horizontal</c>, <c>listname</c>, <c>multipleSel</c>, the tab strings
  ///   (<c>tabstops</c>, <c>tabaligns</c>, <c>tabvaligns</c>, <c>tabTypes</c>, <c>tabIconSizes</c>,
  ///   <c>tabIconVOffset</c>) cut into columns after the parse, and the <c>mtr_</c> icons (their names). Not ported:
  ///   the scroll bar, the list contents (they come from the game), the selection and the keys.
  /// </summary>
  TGuiListWindow = class(TGuiWindow)
  strict private
    FHorizontal: Boolean;
    FMultipleSel: Boolean;
    FListName: AnsiString;
    FTabStopStr: AnsiString;
    FTabAlignStr: AnsiString;
    FTabVAlignStr: AnsiString;
    FTabTypeStr: AnsiString;
    FTabIconSizeStr: AnsiString;
    FTabIconVOffsetStr: AnsiString;
    FIconMaterials: TDictionary<AnsiString, AnsiString>;
    FTabInfo: TList<TGuiTabRect>;
    FScroller: TGuiSliderWindow;
    FListItems: TList<AnsiString>;
    FCurrentSel: TList<Integer>;
    FTop: Integer;
    FTyped: AnsiString;
    FTypedTime: Integer;
    FClickTime: Integer;
    FSizeBias: Single;
    procedure InitScroller(const AHorizontal: Boolean);
    function IsSelected(const AIndex: Integer): Boolean;
    procedure ClearSelection(const AIndex: Integer);
    function ReadNumbers(const AText, AName: AnsiString): TArray<Single>;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString; override;
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString); override;
    procedure HandleBuddyUpdate(const ABuddy: TGuiWindow); override;
    procedure StateChanged(const ARedraw: Boolean); override;
    /// <summary>idListWindow::UpdateList: the items come from the state of the gui (<c>name_item_N</c>)</summary>
    procedure UpdateList;
    procedure SetCurrentSel(const ASel: Integer);
    procedure AddCurrentSel(const ASel: Integer);
    function GetCurrentSel: Integer;
    property ListItems: TList<AnsiString> read FListItems;
    property CurrentSel: TList<Integer> read FCurrentSel;
    property Top: Integer read FTop;
    property Scroller: TGuiSliderWindow read FScroller;
    property Horizontal: Boolean read FHorizontal;
    property MultipleSel: Boolean read FMultipleSel;
    property ListName: AnsiString read FListName;
    property TabInfo: TList<TGuiTabRect> read FTabInfo;
    /// <summary>The material names of the keys <c>mtr_...</c> by key (lower case)</summary>
    property IconMaterials: TDictionary<AnsiString, AnsiString> read FIconMaterials;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Rectangle,
  DelphiDoom.Gui.DrawContext, DelphiDoom.Gui.Material.Intf, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Gui.Window.Types;

constructor TGuiListWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FIconMaterials := TDictionary<AnsiString, AnsiString>.Create;
  FTabInfo := TList<TGuiTabRect>.Create;
  FListItems := TList<AnsiString>.Create;
  FCurrentSel := TList<Integer>.Create;
  FScroller := TGuiSliderWindow.Create(AContext, ACreator);
end;

destructor TGuiListWindow.Destroy;
begin
  FCurrentSel.Free;
  FListItems.Free;
  FTabInfo.Free;
  FIconMaterials.Free;
  inherited Destroy;
end;

function TGuiListWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
var
  LMaterial: AnsiString;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'horizontal') = 0 then
    FHorizontal := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'listname') = 0 then
    ParseString(ASource, FListName)
  else if TIdStrings.Icmp(AName, 'tabstops') = 0 then
    ParseString(ASource, FTabStopStr)
  else if TIdStrings.Icmp(AName, 'tabaligns') = 0 then
    ParseString(ASource, FTabAlignStr)
  else if TIdStrings.Icmp(AName, 'multipleSel') = 0 then
    FMultipleSel := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'tabvaligns') = 0 then
    ParseString(ASource, FTabVAlignStr)
  else if TIdStrings.Icmp(AName, 'tabTypes') = 0 then
    ParseString(ASource, FTabTypeStr)
  else if TIdStrings.Icmp(AName, 'tabIconSizes') = 0 then
    ParseString(ASource, FTabIconSizeStr)
  else if TIdStrings.Icmp(AName, 'tabIconVOffset') = 0 then
    ParseString(ASource, FTabIconVOffsetStr)
  else if TIdStrings.Icmpn(AName, 'mtr_', 4) = 0 then
  begin
    LMaterial := '';
    ParseString(ASource, LMaterial);
    FIconMaterials.AddOrSetValue(AName, LMaterial);
  end
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiListWindow.ReadNumbers(const AText, AName: AnsiString): TArray<Single>;
var
  LParser: TIdParser;
  LToken: TIdToken;
  LList: TList<Single>;
begin
  // the numbers of a string, the commas skipped (atoi for the integer lists)
  LList := TList<Single>.Create;
  LParser := TIdParser.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS, Context.Log);
  try
    LToken := TIdToken.Create;
    if (AText <> '') and LParser.LoadMemory(AText, Length(AText), AName) then
      while LParser.ReadToken(LToken) do
      begin
        if LToken.IsText(',') then
          Continue;
        LList.Add(TIdCNumbers.Atof(LToken.Text));
      end;
    Result := LList.ToArray;
  finally
    LParser.Free;
    LList.Free;
  end;
end;

procedure TGuiListWindow.PostParse;
var
  LStops: TArray<Single>;
  LAligns: TArray<Single>;
  LVAligns: TArray<Single>;
  LTypes: TArray<Single>;
  LSizes: TArray<Single>;
  LOffsets: TArray<Single>;
  LIndex: Integer;
  LCount: Integer;
  LDoAligns: Boolean;
  LRect: TGuiTabRect;
begin
  inherited PostParse;
  InitScroller(FHorizontal);
  LStops := ReadNumbers(FTabStopStr, 'tabstops');
  LAligns := ReadNumbers(FTabAlignStr, 'tabaligns');
  LVAligns := ReadNumbers(FTabVAlignStr, 'tabvaligns');
  LTypes := ReadNumbers(FTabTypeStr, 'tabtypes');
  // the sizes are pairs "w , h" (the numbers of the list are the integer parts, as atoi gives)
  LSizes := ReadNumbers(FTabIconSizeStr, 'tabiconsizes');
  LOffsets := ReadNumbers(FTabIconVOffsetStr, 'tabiconvoffsets');
  LCount := Length(LStops);
  LDoAligns := Length(LAligns) = LCount;
  FTabInfo.Clear;
  for LIndex := 0 to LCount - 1 do
  begin
    LRect := Default(TGuiTabRect);
    LRect.Start := Trunc(LStops[LIndex]);
    if LIndex < LCount - 1 then
      LRect.Width := Trunc(LStops[LIndex + 1]) - LRect.Start - GUI_LIST_TAB_BORDER
    else
      LRect.Width := -1;
    if LDoAligns then
      LRect.Align := Trunc(LAligns[LIndex]);
    // a list shorter than the stops is undefined in the original; here the missing ones keep the default
    if Length(LVAligns) > LIndex then
      LRect.VAlign := Trunc(LVAligns[LIndex]);
    if Length(LTypes) > LIndex then
      LRect.TabType := Trunc(LTypes[LIndex])
    else
      LRect.TabType := GUI_TAB_TYPE_TEXT;
    if Length(LSizes) > LIndex * 2 + 1 then
      LRect.IconSize := TIdVec2.Create(Trunc(LSizes[LIndex * 2]), Trunc(LSizes[LIndex * 2 + 1]));
    if Length(LOffsets) > LIndex then
      LRect.IconVOffset := LOffsets[LIndex];
    FTabInfo.Add(LRect);
  end;
  SetFlag(WIN_CANFOCUS);
end;

const
  PIXEL_OFFSET = 3;
  DOUBLE_CLICK_SPEED = 300;

procedure TGuiListWindow.InitScroller(const AHorizontal: Boolean);
const
  THUMB_IMAGE = 'guis/assets/scrollbar_thumb.tga';
var
  LBarImage, LName: AnsiString;
  LMaterial: IGuiMaterial;
  LRect: TGuiRectangle;
begin
  LBarImage := 'guis/assets/scrollbarv.tga';
  LName := '_scrollerWinV';
  if AHorizontal then
  begin
    LBarImage := 'guis/assets/scrollbarh.tga';
    LName := '_scrollerWinH';
  end;
  if not Assigned(Context.Materials) then
    Exit;
  LMaterial := Context.Materials.FindMaterial(LBarImage);
  LMaterial.SetGuiSort;
  FSizeBias := LMaterial.GetImageWidth;
  if AHorizontal then
  begin
    FSizeBias := LMaterial.GetImageHeight;
    LRect := TGuiRectangle.Create(0, ClientRect.H - FSizeBias, ClientRect.W, FSizeBias);
  end
  else
    LRect := TGuiRectangle.Create(ClientRect.W - FSizeBias, 0, FSizeBias, ClientRect.H);
  FScroller.InitWithDefaults(LName, LRect, ForeColor.Value, MatColor.Value, LMaterial.GetName, THUMB_IMAGE,
    not AHorizontal, True);
  InsertChild(FScroller, nil);
  FScroller.SetBuddy(Self);
end;

procedure TGuiListWindow.SetCurrentSel(const ASel: Integer);
begin
  FCurrentSel.Clear;
  FCurrentSel.Add(ASel);
end;

procedure TGuiListWindow.ClearSelection(const AIndex: Integer);
var
  LCurrent: Integer;
begin
  LCurrent := FCurrentSel.IndexOf(AIndex);
  if LCurrent >= 0 then
    FCurrentSel.Delete(LCurrent);
end;

procedure TGuiListWindow.AddCurrentSel(const ASel: Integer);
begin
  FCurrentSel.Add(ASel);
end;

function TGuiListWindow.GetCurrentSel: Integer;
begin
  if FCurrentSel.Count > 0 then
    Result := FCurrentSel[0]
  else
    Result := 0;
end;

function TGuiListWindow.IsSelected(const AIndex: Integer): Boolean;
begin
  Result := FCurrentSel.IndexOf(AIndex) >= 0;
end;

procedure TGuiListWindow.HandleBuddyUpdate(const ABuddy: TGuiWindow);
begin
  FTop := TIdMath.Ftoi(FScroller.GetValue);
end;

procedure TGuiListWindow.StateChanged(const ARedraw: Boolean);
begin
  UpdateList;
end;

procedure TGuiListWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
begin
  inherited Activate(AActivate, AAct);
  if AActivate then
    UpdateList;
end;

procedure TGuiListWindow.UpdateList;
var
  LIndex, LFit: Integer;
  LText: AnsiString;
  LVert, LValue, LTemp: Single;
begin
  FListItems.Clear;
  for LIndex := 0 to GUI_MAX_LIST_ITEMS - 1 do
  begin
    if Context.StateDict.GetString(AnsiString(Format('%s_item_%d', [string(FListName), LIndex])), '', LText) then
    begin
      if LText <> '' then
        FListItems.Add(LText);
    end
    else
      Break;
  end;
  LVert := GetMaxCharHeight;
  LTemp := TextRect.H / LVert;
  LFit := TIdMath.Ftoi(LTemp);
  if FListItems.Count < LFit then
    FScroller.SetRange(0.0, 0.0, 1.0)
  else
    FScroller.SetRange(0.0, (FListItems.Count - LFit) + 1.0, 1.0);
  SetCurrentSel(Context.StateDict.GetInt(AnsiString(Format('%s_sel_0', [string(FListName)]))));
  LValue := FScroller.GetValue;
  if LValue > FListItems.Count - 1 then
    LValue := FListItems.Count - 1;
  if LValue < 0.0 then
    LValue := 0.0;
  FScroller.SetValue(LValue);
  FTop := TIdMath.Ftoi(LValue);
  FTypedTime := 0;
  FClickTime := 0;
  FTyped := '';
end;

function TGuiListWindow.HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString;
var
  LVert, LTemp: Single;
  LNumVisible, LKey, LCur, LNumLines, LIndex: Integer;
  LCtrl: Boolean;
  LEvent: TGuiSysEvent;
begin
  Result := inherited HandleEvent(AEvent, AUpdateVisuals);
  LVert := GetMaxCharHeight;
  LTemp := TextRect.H / LVert;
  LNumVisible := TIdMath.Ftoi(LTemp);
  LKey := AEvent.Value;
  LCtrl := Assigned(Context.Keys) and Context.Keys.IsDown(GUI_K_CTRL);
  if AEvent.EventType = GUI_SE_KEY then
  begin
    if AEvent.Value2 = 0 then
      Exit;
    if (LKey = GUI_K_MOUSE1) or (LKey = GUI_K_MOUSE2) then
      if FScroller.ContainsPoint(Context.CursorX, Context.CursorY) then
        Exit;
    if (LKey = GUI_K_ENTER) or (LKey = GUI_K_KP_ENTER) then
    begin
      RunScript(seEnter);
      Exit(Command);
    end;
    if LKey = GUI_K_MWHEELUP then
      LKey := GUI_K_UPARROW
    else if LKey = GUI_K_MWHEELDOWN then
      LKey := GUI_K_DOWNARROW;
    if LKey = GUI_K_MOUSE1 then
    begin
      if ContainsPoint(Context.CursorX, Context.CursorY) then
      begin
        LTemp := Context.CursorY - ActualY;
        LTemp := LTemp - PIXEL_OFFSET;
        LTemp := LTemp / LVert;
        LCur := TIdMath.Ftoi(LTemp) + FTop;
        if (LCur >= 0) and (LCur < FListItems.Count) then
        begin
          if FMultipleSel and LCtrl then
          begin
            if IsSelected(LCur) then
              ClearSelection(LCur)
            else
              AddCurrentSel(LCur);
          end
          else
          begin
            if IsSelected(LCur) and (Context.Time < FClickTime + DOUBLE_CLICK_SPEED) then
            begin
              RunScript(seEnter);
              Exit(Command);
            end;
            SetCurrentSel(LCur);
            FClickTime := Context.Time;
          end;
        end
        else
          SetCurrentSel(FListItems.Count - 1);
      end;
    end
    else if (LKey = GUI_K_UPARROW) or (LKey = GUI_K_PGUP) or (LKey = GUI_K_DOWNARROW) or (LKey = GUI_K_PGDN) then
    begin
      LNumLines := 1;
      if (LKey = GUI_K_PGUP) or (LKey = GUI_K_PGDN) then
        LNumLines := LNumVisible div 2;
      if (LKey = GUI_K_UPARROW) or (LKey = GUI_K_PGUP) then
        LNumLines := -LNumLines;
      if LCtrl then
        FTop := FTop + LNumLines
      else
        SetCurrentSel(GetCurrentSel + LNumLines);
    end
    else
      Exit;
  end
  else if AEvent.EventType = GUI_SE_CHAR then
  begin
    if not TIdStrings.CharIsPrintable(LKey) then
      Exit;
    if Context.Time > FTypedTime + 1000 then
      FTyped := '';
    FTypedTime := Context.Time;
    FTyped := FTyped + AnsiChar(LKey and $FF);
    for LIndex := 0 to FListItems.Count - 1 do
      if TIdStrings.Icmpn(FTyped, FListItems[LIndex], Length(FTyped)) = 0 then
      begin
        SetCurrentSel(LIndex);
        Break;
      end;
  end
  else
    Exit;
  if GetCurrentSel < 0 then
    SetCurrentSel(0);
  if GetCurrentSel >= FListItems.Count then
    SetCurrentSel(FListItems.Count - 1);
  if FScroller.GetHigh > 0.0 then
  begin
    if not LCtrl then
    begin
      if FTop > GetCurrentSel - 1 then
        FTop := GetCurrentSel - 1;
      if FTop < GetCurrentSel - LNumVisible + 2 then
        FTop := GetCurrentSel - LNumVisible + 2;
    end;
    if FTop > FListItems.Count - 2 then
      FTop := FListItems.Count - 2;
    if FTop < 0 then
      FTop := 0;
    FScroller.SetValue(FTop);
  end
  else
  begin
    FTop := 0;
    FScroller.SetValue(0.0);
  end;
  if LKey <> GUI_K_MOUSE1 then
  begin
    LEvent := TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_MOUSE1, 1);
    inherited HandleEvent(LEvent, AUpdateVisuals);
  end;
  if FCurrentSel.Count > 0 then
  begin
    for LIndex := 0 to FCurrentSel.Count - 1 do
      Context.StateDict.SetInt(AnsiString(Format('%s_sel_%d', [string(FListName), LIndex])), FCurrentSel[LIndex]);
  end
  else
    Context.StateDict.SetInt(AnsiString(Format('%s_sel_0', [string(FListName)])), 0);
  Context.StateDict.SetInt(AnsiString(Format('%s_numsel', [string(FListName)])), FCurrentSel.Count);
end;

procedure TGuiListWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LDc: TGuiDrawContext;
  LColor, LRectColor: TIdVec4;
  LCount, LIndex, LStart, LTab, LStop: Integer;
  LRect, LIconRect: TGuiRectangle;
  LScale, LLineHeight, LBottom, LWidth, LTemp: Single;
  LItem, LWork: AnsiString;
  LMaterial: IGuiMaterial;
  LInfo: TGuiTabRect;
  LName: AnsiString;
begin
  LDc := Context.DrawContext;
  LCount := FListItems.Count;
  LRect := TextRect;
  LScale := TextScale.Value;
  LLineHeight := GetMaxCharHeight;
  LBottom := TextRect.Bottom;
  LWidth := TextRect.W;
  if FScroller.GetHigh > 0.0 then
  begin
    if FHorizontal then
      LBottom := LBottom - FSizeBias
    else
    begin
      LWidth := LWidth - FSizeBias;
      LRect.W := LWidth;
    end;
  end;
  if NoEvents.Value or (not ContainsPoint(Context.CursorX, Context.CursorY)) then
    Hover := False;
  LIndex := FTop;
  while LIndex < LCount do
  begin
    if IsSelected(LIndex) then
    begin
      LRect.H := LLineHeight;
      LTemp := LRect.Y + PIXEL_OFFSET;
      LDc.DrawFilledRect(LRect.X, LTemp, LRect.W, LRect.H, BorderColor.Value);
      if (Flags and WIN_FOCUS) <> 0 then
      begin
        LRectColor := BorderColor.Value;
        LRectColor.W := 1.0;
        LDc.DrawRect(LRect.X, LTemp, LRect.W, LRect.H, 1.0, LRectColor);
      end;
    end;
    LRect.Y := LRect.Y + 1;
    LRect.H := LLineHeight - 1;
    if Hover and (not NoEvents.Value) and ContainsRect(LRect, Context.CursorX, Context.CursorY) then
      LColor := HoverColor.Value
    else
      LColor := ForeColor.Value;
    LRect.H := LLineHeight + PIXEL_OFFSET;
    LRect.Y := LRect.Y - 1;
    LItem := FListItems[LIndex];
    if FTabInfo.Count > 0 then
    begin
      LStart := 0;
      LTab := 0;
      LStop := Pos(#9, string(LItem)) - 1;
      while LStart < Length(LItem) do
      begin
        if LTab >= FTabInfo.Count then
        begin
          Warning(Format('idListWindow::Draw: gui ''%s'' window ''%s'' tabInfo.Num() exceeded',
            [string(Context.SourceFile), string(Name)]));
          Break;
        end;
        // idStr::Mid(start, len): nothing for a length of zero or less (an item without a tab starts with an empty column)
        if (LStop - LStart <= 0) or (LStart >= Length(LItem)) then
          LWork := ''
        else
          LWork := Copy(LItem, LStart + 1, LStop - LStart);
        LInfo := FTabInfo[LTab];
        LRect.X := TextRect.X + LInfo.Start;
        if LInfo.Width = -1 then
          LRect.W := LWidth - LInfo.Start
        else
          LRect.W := LInfo.Width;
        LDc.PushClipRect(LRect);
        if LInfo.TabType = GUI_TAB_TYPE_TEXT then
          LDc.DrawText(LWork, LScale, LInfo.Align, LColor, LRect, False, -1)
        else if LInfo.TabType = GUI_TAB_TYPE_ICON then
        begin
          if LWork <> '' then
          begin
            if FIconMaterials.TryGetValue(LWork, LName) then
              LMaterial := Context.Materials.FindMaterial(LName)
            else
              LMaterial := Context.Materials.FindMaterial('_default');
            LIconRect.W := LInfo.IconSize.X;
            LIconRect.H := LInfo.IconSize.Y;
            if LInfo.Align = GUI_ALIGN_LEFT then
              LIconRect.X := LRect.X
            else if LInfo.Align = GUI_ALIGN_CENTER then
              LIconRect.X := LRect.X + LRect.W / 2.0 - LIconRect.W / 2.0
            else if LInfo.Align = GUI_ALIGN_RIGHT then
              LIconRect.X := LRect.X + LRect.W - LIconRect.W;
            if LInfo.VAlign = 0 then
              LIconRect.Y := LRect.Y + LInfo.IconVOffset
            else if LInfo.VAlign = 1 then
              LIconRect.Y := LRect.Y + LRect.H / 2.0 - LIconRect.H / 2.0 + LInfo.IconVOffset
            else if LInfo.VAlign = 2 then
              LIconRect.Y := LRect.Y + LRect.H - LIconRect.H + LInfo.IconVOffset;
            LDc.DrawMaterial(LIconRect.X, LIconRect.Y, LIconRect.W, LIconRect.H, LMaterial,
              TIdVec4.Create(1.0, 1.0, 1.0, 1.0), 1.0, 1.0);
          end;
        end;
        LDc.PopClipRect;
        LStart := LStop + 1;
        LStop := Pos(#9, Copy(string(LItem), LStart + 1, MaxInt));
        if LStop <= 0 then
          LStop := Length(LItem)
        else
          LStop := LStart + LStop - 1;
        Inc(LTab);
      end;
      LRect.X := TextRect.X;
      LRect.W := LWidth;
    end
    else
      LDc.DrawText(LItem, LScale, 0, LColor, LRect, False, -1);
    LRect.Y := LRect.Y + LLineHeight;
    if LRect.Y > LBottom then
      Break;
    Inc(LIndex);
  end;
end;

end.