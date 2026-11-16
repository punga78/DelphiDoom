{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWindowEvents, the keys and the mouse of the   }
{  windows                                                                     }
{                                                                              }
{  Port of idWindow::HandleEvent and idWindow::RouteMouseCoords (ui\Window.cpp }
{  of Doom 3, id Software, GPL v3): the routing of a key, a character or a     }
{  movement of the mouse to the children, the focus (the tab key moves it),    }
{  the capture of the mouse and the scripts onAction, onActionRelease, onESC,  }
{  onMouseEnter and onMouseExit.                                               }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Events;

interface

uses
  DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Keys;

type
  /// <summary>The events of the windows; the methods of TGuiWindow call these</summary>
  TGuiWindowEvents = class
  public
    /// <summary>idWindow::HandleEvent</summary>
    class function HandleEvent(const AWindow: TGuiWindow; const AEvent: TGuiSysEvent;
      var AUpdateVisuals: Boolean): AnsiString; static;
    /// <summary>idWindow::RouteMouseCoords</summary>
    class function RouteMouseCoords(const AWindow: TGuiWindow; const AX, AY: Single): AnsiString; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Gui.Context, DelphiDoom.Gui.DrawContext, DelphiDoom.Gui.Window.Types;

function GuiEdit(const AContext: TGuiContext): Boolean;
begin
  Result := Assigned(AContext.Cvars) and AContext.Cvars.GetBool('gui_edit');
end;

function DesktopOf(const AWindow: TGuiWindow): TGuiWindow;
begin
  Result := AWindow.Context.Desktop as TGuiWindow;
end;

// the command a child left is handed to the desktop
procedure PassCommand(const AChild: TGuiWindow);
begin
  if AChild.Command <> '' then
  begin
    DesktopOf(AChild).AddCommand(AChild.Command);
    AChild.Command := '';
  end;
end;

class function TGuiWindowEvents.RouteMouseCoords(const AWindow: TGuiWindow; const AX, AY: Single): AnsiString;
var
  LContext: TGuiContext;
  LIndex: Integer;
  LChild: TGuiWindow;
begin
  LContext := AWindow.Context;
  Result := '';
  if (AWindow.GetCaptureChild <> nil) then
    // FIXME of the original: unkludge this whole mechanism
    Exit(AWindow.GetCaptureChild.RouteMouseCoords(AX, AY));
  if (AX = -2000) or (AY = -2000) then
    Exit;
  LIndex := AWindow.ChildCount;
  while LIndex > 0 do
  begin
    Dec(LIndex);
    LChild := AWindow.Children[LIndex];
    if LChild.Visible.Value and (not LChild.NoEvents.Value) and
      LChild.ContainsRect(LChild.DrawRect, LContext.CursorX, LContext.CursorY) then
    begin
      if Assigned(LContext.DrawContext) then
        LContext.DrawContext.SetCursor(LChild.Cursor);
      LChild.Hover := True;
      if AWindow.OverChild <> LChild then
      begin
        if Assigned(AWindow.OverChild) then
        begin
          AWindow.OverChild.MouseExit;
          PassCommand(AWindow.OverChild);
        end;
        AWindow.OverChild := LChild;
        AWindow.OverChild.MouseEnter;
        PassCommand(AWindow.OverChild);
      end
      else if (LChild.Flags and WIN_HOLDCAPTURE) = 0 then
        LChild.RouteMouseCoords(AX, AY);
      Exit;
    end;
  end;
  if Assigned(AWindow.OverChild) then
  begin
    AWindow.OverChild.MouseExit;
    PassCommand(AWindow.OverChild);
    AWindow.OverChild := nil;
  end;
end;

// the tab key: the focus goes to the next (or with shift the previous) window that can have it
procedure MoveFocus(const AWindow: TGuiWindow);
var
  LDirection, LIndex: Integer;
  LCurrent, LChild, LParent, LTest: TGuiWindow;
  LFound, LRecurse: Boolean;
begin
  LDirection := 1;
  if Assigned(AWindow.Context.Keys) and AWindow.Context.Keys.IsDown(GUI_K_SHIFT) then
    LDirection := -1;
  LCurrent := AWindow.GetFocusedChild;
  LChild := AWindow.GetFocusedChild;
  LParent := LChild.Parent;
  while Assigned(LParent) do
  begin
    LFound := False;
    LRecurse := False;
    LIndex := 0;
    if Assigned(LChild) then
      LIndex := LParent.GetChildIndex(LChild) + LDirection
    else if LDirection < 0 then
      LIndex := LParent.ChildCount - 1;
    while (LIndex < LParent.ChildCount) and (LIndex >= 0) do
    begin
      LTest := LParent.Children[LIndex];
      if LTest = LCurrent then
      begin
        // we managed to wrap around and get back to our starting window
        LFound := True;
        Break;
      end;
      if Assigned(LTest) and (not LTest.NoEvents.Value) and LTest.Visible.Value then
      begin
        if (LTest.Flags and WIN_CANFOCUS) <> 0 then
        begin
          AWindow.SetFocus(LTest);
          LFound := True;
          Break;
        end
        else if LTest.ChildCount > 0 then
        begin
          LParent := LTest;
          LChild := nil;
          LRecurse := True;
          Break;
        end;
      end;
      Inc(LIndex, LDirection);
    end;
    if LFound then
      Break
    else if LRecurse then
      Continue
    else
    begin
      // we didn't find anything, so go back up to our parent
      LChild := LParent;
      LParent := LChild.Parent;
      if LParent = DesktopOf(AWindow) then
      begin
        // we got back to the desktop, so wrap around but don't actually go to the desktop
        LParent := nil;
        LChild := nil;
      end;
    end;
  end;
end;

class function TGuiWindowEvents.HandleEvent(const AWindow: TGuiWindow; const AEvent: TGuiSysEvent;
  var AUpdateVisuals: Boolean): AnsiString;
var
  LContext: TGuiContext;
  LDesktop, LChild: TGuiWindow;
  LIndex: Integer;
  LReturn: AnsiString;

  // the child with the focus gets the event; true if it answered with a command
  function FocusedChildAnswers: Boolean;
  begin
    Result := False;
    if (AWindow.GetFocusedChild <> nil) then
    begin
      LReturn := AWindow.GetFocusedChild.HandleEvent(AEvent, AUpdateVisuals);
      Result := LReturn <> '';
    end;
  end;

begin
  LContext := AWindow.Context;
  AWindow.Command := '';
  if (AWindow.Flags and WIN_DESKTOP) <> 0 then
  begin
    LContext.ActionDownRun := False;
    LContext.ActionUpRun := False;
    if (AWindow.Store.RegisterCount > 0) and (AWindow.Store.OpCount > 0) then
      AWindow.EvalRegs;
    AWindow.RunTimeEvents(LContext.Time);
    AWindow.CalcRects(0, 0);
    if Assigned(LContext.DrawContext) then
      LContext.DrawContext.SetCursor(GUI_CURSOR_ARROW);
  end;
  LDesktop := DesktopOf(AWindow);
  if AWindow.Visible.Value and (not AWindow.NoEvents.Value) then
  begin
    if AEvent.EventType = GUI_SE_KEY then
    begin
      AWindow.EvalRegs(-1, True);
      AUpdateVisuals := True;
      if AEvent.Value = GUI_K_MOUSE1 then
      begin
        if (AEvent.Value2 = 0) and (AWindow.GetCaptureChild <> nil) then
        begin
          AWindow.GetCaptureChild.LoseCapture;
          LDesktop.CaptureChildRaw := nil;
          Exit('');
        end;
        LIndex := AWindow.ChildCount;
        while LIndex > 0 do
        begin
          Dec(LIndex);
          LChild := AWindow.Children[LIndex];
          if LChild.Visible.Value and LChild.ContainsRect(LChild.DrawRect, LContext.CursorX, LContext.CursorY) and
            (not LChild.NoEvents.Value) then
          begin
            if AEvent.Value2 <> 0 then
            begin
              AWindow.BringToTop(LChild);
              AWindow.SetFocus(LChild);
              if (LChild.Flags and WIN_HOLDCAPTURE) <> 0 then
                AWindow.SetCapture(LChild);
            end;
            if LChild.ContainsRect(LChild.ClientRect, LContext.CursorX, LContext.CursorY) then
            begin
              AWindow.SetFocus(LChild);
              LReturn := LChild.HandleEvent(AEvent, AUpdateVisuals);
              if LReturn <> '' then
                Exit(LReturn);
              if (LChild.Flags and WIN_MODAL) <> 0 then
                Exit('');
            end
            else if AEvent.Value2 <> 0 then
            begin
              AWindow.SetFocus(LChild);
              if ((LChild.Flags and WIN_MOVABLE) <> 0) or GuiEdit(LContext) then
                AWindow.SetCapture(LChild);
              Exit('');
            end;
          end;
          // the original keeps looking at the windows below, with the index of the list it had
          if LIndex > AWindow.ChildCount then
            LIndex := AWindow.ChildCount;
        end;
        if (AEvent.Value2 <> 0) and (not LContext.ActionDownRun) then
          LContext.ActionDownRun := AWindow.RunScript(seAction)
        else if not LContext.ActionUpRun then
          LContext.ActionUpRun := AWindow.RunScript(seActionRelease);
      end
      else if AEvent.Value = GUI_K_MOUSE2 then
      begin
        if (AEvent.Value2 = 0) and (AWindow.GetCaptureChild <> nil) then
        begin
          AWindow.GetCaptureChild.LoseCapture;
          LDesktop.CaptureChildRaw := nil;
          Exit('');
        end;
        LIndex := AWindow.ChildCount;
        while LIndex > 0 do
        begin
          Dec(LIndex);
          LChild := AWindow.Children[LIndex];
          if LChild.Visible.Value and LChild.ContainsRect(LChild.DrawRect, LContext.CursorX, LContext.CursorY) and
            (not LChild.NoEvents.Value) then
          begin
            if AEvent.Value2 <> 0 then
            begin
              AWindow.BringToTop(LChild);
              AWindow.SetFocus(LChild);
            end;
            if LChild.ContainsRect(LChild.ClientRect, LContext.CursorX, LContext.CursorY) or
              (AWindow.GetCaptureChild = LChild) then
            begin
              if (GuiEdit(LContext) and ((LChild.Flags and WIN_SELECTED) <> 0)) or
                ((not GuiEdit(LContext)) and ((LChild.Flags and WIN_MOVABLE) <> 0)) then
                AWindow.SetCapture(LChild);
              LReturn := LChild.HandleEvent(AEvent, AUpdateVisuals);
              if LReturn <> '' then
                Exit(LReturn);
              if (LChild.Flags and WIN_MODAL) <> 0 then
                Exit('');
            end;
          end;
          if LIndex > AWindow.ChildCount then
            LIndex := AWindow.ChildCount;
        end;
      end
      else if AEvent.Value = GUI_K_MOUSE3 then
      begin
        if GuiEdit(LContext) then
          for LIndex := 0 to AWindow.ChildCount - 1 do
            if AWindow.Children[LIndex].DrawRect.Contains(LContext.CursorX, LContext.CursorY) then
              if AEvent.Value2 <> 0 then
              begin
                if (AWindow.Children[LIndex].Flags and WIN_SELECTED) <> 0 then
                  AWindow.Children[LIndex].ClearFlag(WIN_SELECTED)
                else
                  AWindow.Children[LIndex].SetFlag(WIN_SELECTED);
                if (AWindow.Children[LIndex].Flags and WIN_SELECTED) <> 0 then
                begin
                  AWindow.ClearFlag(WIN_SELECTED);
                  Exit('childsel');
                end;
              end;
      end
      else if (AEvent.Value = GUI_K_TAB) and (AEvent.Value2 <> 0) then
      begin
        if (AWindow.GetFocusedChild <> nil) then
        begin
          if FocusedChildAnswers then
            Exit(LReturn);
          // If the window didn't handle the tab, then move the focus to the next window
          // or the previous window if shift is held down
          MoveFocus(AWindow);
        end;
      end
      else if (AEvent.Value = GUI_K_ESCAPE) and (AEvent.Value2 <> 0) then
      begin
        if (AWindow.GetFocusedChild <> nil) and FocusedChildAnswers then
          Exit(LReturn);
        AWindow.RunScript(seEsc);
      end
      else if AEvent.Value = GUI_K_ENTER then
      begin
        if (AWindow.GetFocusedChild <> nil) and FocusedChildAnswers then
          Exit(LReturn);
        if (AWindow.Flags and WIN_WANTENTER) <> 0 then
        begin
          if AEvent.Value2 <> 0 then
            AWindow.RunScript(seAction)
          else
            AWindow.RunScript(seActionRelease);
        end;
      end
      else
      begin
        if (AWindow.GetFocusedChild <> nil) and FocusedChildAnswers then
          Exit(LReturn);
      end;
    end
    else if AEvent.EventType = GUI_SE_MOUSE then
    begin
      AUpdateVisuals := True;
      LReturn := AWindow.RouteMouseCoords(AEvent.Value, AEvent.Value2);
      if LReturn <> '' then
        Exit(LReturn);
    end
    else if AEvent.EventType = GUI_SE_NONE then
    begin
    end
    else if AEvent.EventType = GUI_SE_CHAR then
    begin
      if (AWindow.GetFocusedChild <> nil) and FocusedChildAnswers then
        Exit(LReturn);
    end;
  end;
  LContext.ReturnCommand := AWindow.Command;
  if LContext.PendingCommand <> '' then
  begin
    LContext.ReturnCommand := LContext.ReturnCommand + ' ; ' + LContext.PendingCommand;
    LContext.PendingCommand := '';
  end;
  AWindow.Command := '';
  Result := LContext.ReturnCommand;
end;

end.
