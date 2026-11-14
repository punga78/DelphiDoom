{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiListGui, data for a listDef                   }
{                                                                              }
{  Port of ui\ListGUI.h, ListGUILocal.h and ListGUI.cpp (idListGUILocal, id     }
{  Software, GPL v3): a list of items with an id and a text that writes its    }
{  lines to the state of a gui (<c>name_item_N</c>) for a listDef.             }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.ListGui;

interface

uses
  System.Generics.Collections, DelphiDoom.Gui.UserInterface;

type
  /// <summary>
  ///   idListGUILocal. The time of the refresh (<c>com_frameTime</c>) is <c>FrameTime</c>, set by the host. The gui is not
  ///   owned.
  /// </summary>
  TGuiListGui = class
  strict private
    FGui: TGuiUserInterface;
    FName: AnsiString;
    FWater: Integer;
    FItems: TList<AnsiString>;
    FIds: TList<Integer>;
    FStateUpdates: Boolean;
    FFrameTime: Integer;
    procedure StateChanged;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Config(const AGui: TGuiUserInterface; const AName: AnsiString);
    /// <summary>Add: a new id appends an item, an id that exists replaces its text</summary>
    procedure Add(const AId: Integer; const AText: AnsiString);
    /// <summary>Push: the element count is the id</summary>
    procedure Push(const AText: AnsiString);
    function Del(const AId: Integer): Boolean;
    procedure Clear;
    /// <summary>GetSelection: the id of the selected item (-1 if none) and its text</summary>
    function GetSelection(out AText: AnsiString; const ASel: Integer = 0): Integer;
    procedure SetSelection(const ASel: Integer);
    function GetNumSelections: Integer;
    function IsConfigured: Boolean;
    procedure SetStateChanges(const AEnable: Boolean);
    procedure Shutdown;
    property Count: Integer read GetCount;
    property FrameTime: Integer read FFrameTime write FFrameTime;
  end;

implementation

uses
  System.SysUtils;

constructor TGuiListGui.Create;
begin
  inherited Create;
  FItems := TList<AnsiString>.Create;
  FIds := TList<Integer>.Create;
  FStateUpdates := True;
end;

destructor TGuiListGui.Destroy;
begin
  FIds.Free;
  FItems.Free;
  inherited Destroy;
end;

function TGuiListGui.GetCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TGuiListGui.Config(const AGui: TGuiUserInterface; const AName: AnsiString);
begin
  FGui := AGui;
  FName := AName;
end;

procedure TGuiListGui.StateChanged;
var
  LIndex: Integer;
begin
  if not FStateUpdates then
    Exit;
  for LIndex := 0 to FItems.Count - 1 do
    FGui.SetStateString(AnsiString(Format('%s_item_%d', [string(FName), LIndex])), FItems[LIndex]);
  for LIndex := FItems.Count to FWater - 1 do
    FGui.SetStateString(AnsiString(Format('%s_item_%d', [string(FName), LIndex])), '');
  FWater := FItems.Count;
  FGui.StateChanged(FFrameTime, False);
end;

procedure TGuiListGui.Add(const AId: Integer; const AText: AnsiString);
var
  LIndex: Integer;
begin
  LIndex := FIds.IndexOf(AId);
  if LIndex = -1 then
  begin
    FItems.Add(AText);
    FIds.Add(AId);
  end
  else
    FItems[LIndex] := AText;
  StateChanged;
end;

procedure TGuiListGui.Push(const AText: AnsiString);
begin
  FItems.Add(AText);
  FIds.Add(FIds.Count);
  StateChanged;
end;

function TGuiListGui.Del(const AId: Integer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FIds.IndexOf(AId);
  if LIndex = -1 then
    Exit(False);
  FIds.Delete(LIndex);
  FItems.Delete(LIndex);
  StateChanged;
  Result := True;
end;

procedure TGuiListGui.Clear;
begin
  FIds.Clear;
  FItems.Clear;
  if Assigned(FGui) then
    StateChanged;
end;

function TGuiListGui.GetNumSelections: Integer;
begin
  Result := FGui.GetStateInt(AnsiString(Format('%s_numsel', [string(FName)])));
end;

function TGuiListGui.GetSelection(out AText: AnsiString; const ASel: Integer): Integer;
var
  LSel: Integer;
begin
  AText := '';
  LSel := FGui.GetStateInt(AnsiString(Format('%s_sel_%d', [string(FName), ASel])), '-1');
  if (LSel = -1) or (LSel >= FIds.Count) then
    Exit(-1);
  AText := FGui.GetStateString(AnsiString(Format('%s_item_%d', [string(FName), LSel])), '');
  FGui.SetStateInt(AnsiString(Format('%s_selid_0', [string(FName)])), FIds[LSel]);
  Result := FIds[LSel];
end;

procedure TGuiListGui.SetSelection(const ASel: Integer);
begin
  FGui.SetStateInt(AnsiString(Format('%s_sel_0', [string(FName)])), ASel);
  StateChanged;
end;

function TGuiListGui.IsConfigured: Boolean;
begin
  Result := Assigned(FGui);
end;

procedure TGuiListGui.SetStateChanges(const AEnable: Boolean);
begin
  FStateUpdates := AEnable;
  StateChanged;
end;

procedure TGuiListGui.Shutdown;
begin
  FGui := nil;
  FName := '';
  Clear;
end;

end.
