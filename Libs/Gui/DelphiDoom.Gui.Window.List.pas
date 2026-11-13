{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiListWindow (listDef)                          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\ListWindow.h,           }
{  ListWindow.cpp (idListWindow: the parse and the tab stops).                 }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.List;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context,
  DelphiDoom.Gui.Window;

const
  /// <summary>tabBorder of ListWindow.cpp</summary>
  GUI_LIST_TAB_BORDER = 4;
  /// <summary>TAB_TYPE_TEXT</summary>
  GUI_TAB_TYPE_TEXT = 0;

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
    function ReadNumbers(const AText, AName: AnsiString): TArray<Single>;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    property Horizontal: Boolean read FHorizontal;
    property MultipleSel: Boolean read FMultipleSel;
    property ListName: AnsiString read FListName;
    property TabInfo: TList<TGuiTabRect> read FTabInfo;
    /// <summary>The material names of the keys <c>mtr_...</c> by key (lower case)</summary>
    property IconMaterials: TDictionary<AnsiString, AnsiString> read FIconMaterials;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Gui.Window.Types;

constructor TGuiListWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FIconMaterials := TDictionary<AnsiString, AnsiString>.Create;
  FTabInfo := TList<TGuiTabRect>.Create;
end;

destructor TGuiListWindow.Destroy;
begin
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
    FIconMaterials.AddOrSetValue(TIdStrings.ToLower(AName), LMaterial);
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

end.
