{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiUserInterface, a .gui of Doom 3               }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\UserInterface.cpp,      }
{  UserInterfaceLocal.h (idUserInterfaceLocal: InitFromFile, the state, time   }
{  and events). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.UserInterface;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Factory,
  DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.Regs.Intf;

type
  /// <summary>
  ///   idUserInterfaceLocal: reads a .gui (<c>InitFromFile</c>), owns the desktop window and the
  ///   dictionary of the <c>gui::</c> variables, and passes the time and the events to the windows
  ///   (<c>RunFrame</c>, <c>StateChanged</c>, <c>Activate</c>, <c>Trigger</c>, <c>HandleNamedEvent</c>). No drawing
  ///   and no input: the game, the sounds, the fonts, the language and the tables come as interfaces
  ///   (all optional). Not ported: the manager (<c>idUserInterfaceManagerLocal</c>: the list of guis,
  ///   reloading, uniqueness), the cursor, key bindings and the save game and demo files.
  /// </summary>
  TGuiUserInterface = class
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    FFactory: TGuiWindowFactory;
    FContext: TGuiContext;
    FDesktop: TGuiWindow;
    FInteractive: Boolean;
    FStrict: Boolean;
    function GetTime: Integer;
    function GetActive: Boolean;
    function GetSourceFile: AnsiString;
    function GetPendingCommand: AnsiString;
    procedure SetPendingCommand(const AValue: AnsiString);
    procedure SetStrict(const AValue: Boolean);
  public
    /// <summary>The factory is owned; the services are optional</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog; const AFactory: TGuiWindowFactory;
      const AGameHost: IGuiGameHost = nil; const ALanguage: IGuiLanguage = nil; const ATables: IGuiTables = nil;
      const AFonts: IGuiFontLookup = nil);
    destructor Destroy; override;
    /// <summary>
    ///   InitFromFile: parses the first <c>windowDef</c> of the file (the other text is skipped). True also
    ///   when the file does not exist (the desktop is then "Invalid GUI" as in the original) or does not parse
    ///   (the parser reports it); an empty name is False. In strict mode a window that does not
    ///   parse raises <c>EGuiWindowParseException</c>.
    /// </summary>
    function InitFromFile(const AName: AnsiString; const ARebuild: Boolean = True): Boolean;
    /// <summary>Time and the events of the windows of a frame (what Redraw does for the desktop, without the drawing)</summary>
    procedure RunFrame(const ATime: Integer);
    procedure HandleNamedEvent(const AEventName: AnsiString);
    procedure StateChanged(const ATime: Integer; const ARedraw: Boolean);
    /// <summary>Activate: the commands that the windows left for the game</summary>
    function Activate(const AActivate: Boolean; const ATime: Integer): AnsiString;
    procedure Trigger(const ATime: Integer);
    procedure SetStateString(const AName, AValue: AnsiString);
    procedure SetStateBool(const AName: AnsiString; const AValue: Boolean);
    procedure SetStateInt(const AName: AnsiString; const AValue: Integer);
    procedure SetStateFloat(const AName: AnsiString; const AValue: Single);
    function GetStateString(const AName: AnsiString; const ADefault: AnsiString = ''): AnsiString;
    function GetStateBool(const AName: AnsiString; const ADefault: AnsiString = '0'): Boolean;
    function GetStateInt(const AName: AnsiString; const ADefault: AnsiString = '0'): Integer;
    function GetStateFloat(const AName: AnsiString; const ADefault: AnsiString = '0'): Single;
    procedure DeleteStateVar(const AName: AnsiString);
    property Desktop: TGuiWindow read FDesktop;
    property Context: TGuiContext read FContext;
    property Interactive: Boolean read FInteractive;
    property StrictParsing: Boolean read FStrict write SetStrict;
    property SourceFile: AnsiString read GetSourceFile;
    property Time: Integer read GetTime;
    property Active: Boolean read GetActive;
    property PendingCommand: AnsiString read GetPendingCommand write SetPendingCommand;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdParser, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Rectangle, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Window.Types;

constructor TGuiUserInterface.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog;
  const AFactory: TGuiWindowFactory; const AGameHost: IGuiGameHost; const ALanguage: IGuiLanguage;
  const ATables: IGuiTables; const AFonts: IGuiFontLookup);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
  FFactory := AFactory;
  FContext := TGuiContext.Create(ALog);
  FContext.GameHost := AGameHost;
  FContext.Language := ALanguage;
  FContext.Tables := ATables;
  FContext.Fonts := AFonts;
  FFactory.Attach(FContext);
  // so the register evaluation of the parse does not get a bogus time
  FContext.Time := 0;
end;

destructor TGuiUserInterface.Destroy;
begin
  FContext.Desktop := nil;
  FDesktop.Free;
  FContext.Free;
  FFactory.Free;
  inherited Destroy;
end;

procedure TGuiUserInterface.SetStrict(const AValue: Boolean);
begin
  FStrict := AValue;
end;

function TGuiUserInterface.GetTime: Integer;
begin
  Result := FContext.Time;
end;

function TGuiUserInterface.GetActive: Boolean;
begin
  Result := FContext.Active;
end;

function TGuiUserInterface.GetSourceFile: AnsiString;
begin
  Result := FContext.SourceFile;
end;

function TGuiUserInterface.GetPendingCommand: AnsiString;
begin
  Result := FContext.PendingCommand;
end;

procedure TGuiUserInterface.SetPendingCommand(const AValue: AnsiString);
begin
  FContext.PendingCommand := AValue;
end;

function TGuiUserInterface.InitFromFile(const AName: AnsiString; const ARebuild: Boolean): Boolean;
var
  LParser: TIdParser;
  LToken: TIdToken;
  LParsed: Boolean;
begin
  if AName = '' then
    Exit(False);
  if ARebuild or (not Assigned(FDesktop)) then
  begin
    FContext.Desktop := nil;
    FreeAndNil(FDesktop);
    FContext.LastEvalWindow := nil;
    FDesktop := TGuiWindow.Create(FContext, FFactory.GetCreator());
    FContext.Desktop := FDesktop;
  end;
  FContext.SourceFile := AName;
  FContext.StateDict.SetValue('text', 'Test Text!');
  LParser := TIdParser.Create(LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_ALLOWMULTICHARLITERALS or
    LEXFL_ALLOWBACKSLASHSTRINGCONCAT, FLog, FFileSystem);
  try
    if LParser.LoadFile(AName) then
    begin
      LToken := TIdToken.Create;
      while LParser.ReadToken(LToken) do
        if TIdStrings.Icmp(LToken.Text, 'windowDef') = 0 then
        begin
          LParsed := FDesktop.Parse(LParser, ARebuild);
          if LParsed then
          begin
            FDesktop.SetFlag(WIN_DESKTOP);
            FDesktop.FixupParms;
          end
          else if FStrict then
            raise EGuiWindowParseException.Create(string(AName), LParser.LineNum, 'the window does not parse');
        end;
      FContext.StateDict.SetValue('name', AName);
    end
    else
    begin
      if Assigned(FLog) then
        FLog.Warning(Format('Couldn''t load gui: ''%s''', [string(AName)]));
      FDesktop.SetInitialState('Desktop');
      FDesktop.SetFlag(WIN_DESKTOP);
      FDesktop.Text.Value := AnsiString(Format('Invalid GUI: %s', [string(AName)]));
      FDesktop.Rect.Value := TGuiRectangle.Create(0.0, 0.0, 640.0, 480.0);
      FDesktop.ForeColor.Value := TIdVec4.Create(1.0, 1.0, 1.0, 1.0);
      FDesktop.BackColor.Value := TIdVec4.Create(0.0, 0.0, 0.0, 1.0);
      FDesktop.SetupFromState;
    end;
  finally
    LParser.Free;
  end;
  FInteractive := FDesktop.Interactive;
  Result := True;
end;

procedure TGuiUserInterface.RunFrame(const ATime: Integer);
begin
  FContext.Time := ATime;
  if Assigned(FDesktop) then
    FDesktop.RunTimeEvents(ATime);
end;

procedure TGuiUserInterface.HandleNamedEvent(const AEventName: AnsiString);
begin
  if Assigned(FDesktop) then
    FDesktop.RunNamedEvent(AEventName);
end;

procedure TGuiUserInterface.StateChanged(const ATime: Integer; const ARedraw: Boolean);
begin
  FContext.Time := ATime;
  if Assigned(FDesktop) then
    FDesktop.StateChanged(ARedraw);
  if FContext.StateDict.GetBool('noninteractive') then
    FInteractive := False
  else
    FInteractive := Assigned(FDesktop) and FDesktop.Interactive;
end;

function TGuiUserInterface.Activate(const AActivate: Boolean; const ATime: Integer): AnsiString;
begin
  FContext.Time := ATime;
  FContext.Active := AActivate;
  Result := '';
  if Assigned(FDesktop) then
    FDesktop.Activate(AActivate, Result);
end;

procedure TGuiUserInterface.Trigger(const ATime: Integer);
begin
  FContext.Time := ATime;
  if Assigned(FDesktop) then
    FDesktop.Trigger;
end;

procedure TGuiUserInterface.SetStateString(const AName, AValue: AnsiString);
begin
  FContext.StateDict.SetValue(AName, AValue);
end;

procedure TGuiUserInterface.SetStateBool(const AName: AnsiString; const AValue: Boolean);
begin
  FContext.StateDict.SetBool(AName, AValue);
end;

procedure TGuiUserInterface.SetStateInt(const AName: AnsiString; const AValue: Integer);
begin
  FContext.StateDict.SetInt(AName, AValue);
end;

procedure TGuiUserInterface.SetStateFloat(const AName: AnsiString; const AValue: Single);
begin
  FContext.StateDict.SetFloat(AName, AValue);
end;

function TGuiUserInterface.GetStateString(const AName, ADefault: AnsiString): AnsiString;
begin
  Result := FContext.StateDict.GetString(AName, ADefault);
end;

function TGuiUserInterface.GetStateBool(const AName, ADefault: AnsiString): Boolean;
begin
  Result := FContext.StateDict.GetBool(AName, ADefault);
end;

function TGuiUserInterface.GetStateInt(const AName, ADefault: AnsiString): Integer;
begin
  Result := FContext.StateDict.GetInt(AName, ADefault);
end;

function TGuiUserInterface.GetStateFloat(const AName, ADefault: AnsiString): Single;
begin
  Result := FContext.StateDict.GetFloat(AName, ADefault);
end;

procedure TGuiUserInterface.DeleteStateVar(const AName: AnsiString);
begin
  FContext.StateDict.Delete(AName);
end;

end.
