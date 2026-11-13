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
  DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Str;

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
    FHasUpdateVar: Boolean;
    procedure ValidateChoice;
    procedure InitVars;
    procedure UpdateChoice;
    function Tokens(const AText, AName: AnsiString; const AFlags: Integer): TArray<AnsiString>;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    /// <summary>UpdateChoicesAndVals: cuts the strings at ";" when they changed since the last time</summary>
    procedure UpdateChoicesAndVals;
    property CurrentChoice: Integer read FCurrentChoice;
    property ChoiceType: Integer read FChoiceType;
    property Choices: TList<AnsiString> read FChoices;
    property Values: TList<AnsiString> read FValues;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
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
  FCurrentChoice := 0;
  FChoiceType := 0;
  FLiveUpdate.Value := True;
end;

destructor TGuiChoiceWindow.Destroy;
begin
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
begin
  // the cvar of the original is not ported: only the variable of the gui is updated
  FHasUpdateVar := FGuiStr.Length > 0;
  if FHasUpdateVar then
  begin
    FGuiStr.SetGuiInfo(Context.StateDict, FGuiStr.AsText);
    FGuiStr.Update;
  end;
end;

procedure TGuiChoiceWindow.UpdateChoice;
var
  LCount: Integer;
  LIndex: Integer;
  LList: TList<AnsiString>;
begin
  if not FHasUpdateVar then
    Exit;
  FGuiStr.Update;
  if FChoiceType = 0 then
  begin
    // the choice is an integer in the gui (or the cvar)
    if FGuiStr.NeedsUpdate then
      FCurrentChoice := TIdCNumbers.Atoi(FGuiStr.AsText);
    ValidateChoice;
  end
  else
  begin
    // the choice is a string, searched in the values (or the choices)
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
  SetFlag(WIN_CANFOCUS);
end;

end.
