{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiEditWindow (editDef)                          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\EditWindow.h,           }
{  EditWindow.cpp (idEditWindow: the parse). Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Edit;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Str;

type
  /// <summary>
  ///   idEditWindow: the keys <c>maxchars</c>, <c>numeric</c>, <c>wrap</c>, <c>readonly</c>,
  ///   <c>forceScroll</c>, <c>source</c>, <c>password</c>, <c>cvarMax</c> and the variables <c>cvar</c>,
  ///   <c>password</c>, <c>liveUpdate</c>, <c>cvarGroup</c>. Not ported: the file named by <c>source</c> (the
  ///   name is kept), the cvar, the scroll bar, the cursor and the keys.
  /// </summary>
  TGuiEditWindow = class(TGuiWindow)
  strict private
    FMaxChars: Integer;
    FNumeric: Boolean;
    FWrap: Boolean;
    FReadOnly: Boolean;
    FForceScroll: Boolean;
    FCvarMax: Integer;
    FSourceFile: AnsiString;
    FCvarStr: TGuiWinStr;
    FCvarGroup: TGuiWinStr;
    FPassword: TGuiWinBool;
    FLiveUpdate: TGuiWinBool;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    property MaxChars: Integer read FMaxChars;
    property Numeric: Boolean read FNumeric;
    property Wrap: Boolean read FWrap;
    property ReadOnly: Boolean read FReadOnly;
    property ForceScroll: Boolean read FForceScroll;
    property CvarMax: Integer read FCvarMax;
    property TextSourceFile: AnsiString read FSourceFile;
    property Password: TGuiWinBool read FPassword;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Window.Types;

constructor TGuiEditWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FCvarStr := TGuiWinStr.Create;
  FCvarGroup := TGuiWinStr.Create;
  FPassword := TGuiWinBool.Create;
  FLiveUpdate := TGuiWinBool.Create;
  FMaxChars := 128;
  FLiveUpdate.Value := True;
end;

destructor TGuiEditWindow.Destroy;
begin
  FLiveUpdate.Free;
  FPassword.Free;
  FCvarGroup.Free;
  FCvarStr.Free;
  inherited Destroy;
end;

function TGuiEditWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'maxchars') = 0 then
    FMaxChars := ASource.ParseInt
  else if TIdStrings.Icmp(AName, 'numeric') = 0 then
    FNumeric := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'wrap') = 0 then
    FWrap := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'readonly') = 0 then
    FReadOnly := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'forceScroll') = 0 then
    FForceScroll := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'source') = 0 then
    ParseString(ASource, FSourceFile)
  else if TIdStrings.Icmp(AName, 'password') = 0 then
    FPassword.Value := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'cvarMax') = 0 then
    FCvarMax := ASource.ParseInt
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiEditWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'cvar') = 0 then
    Exit(FCvarStr);
  if TIdStrings.Icmp(AName, 'password') = 0 then
    Exit(FPassword);
  if TIdStrings.Icmp(AName, 'liveUpdate') = 0 then
    Exit(FLiveUpdate);
  if TIdStrings.Icmp(AName, 'cvarGroup') = 0 then
    Exit(FCvarGroup);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

procedure TGuiEditWindow.PostParse;
begin
  inherited PostParse;
  if FMaxChars = 0 then
    FMaxChars := 10;
  SetFlag(WIN_CANFOCUS);
end;

end.
