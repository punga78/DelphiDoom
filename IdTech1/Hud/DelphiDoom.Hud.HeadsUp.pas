{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the heads-up display                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.HeadsUp;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.View, DelphiDoom.Hud.TextLine,
  DelphiDoom.Hud.InputText, DelphiDoom.Hud.ScrollingText, DelphiDoom.Hud.FpsCounter,
  DelphiDoom.Hud.MessageBar, DelphiDoom.Hud.Chat;

type
  /// <summary>
  ///   The model of the heads-up display (what hu_stuff.pas did with its globals): the message
  ///   bar, the chat, the title of the map, the time of the level and the frames per second.
  ///   It does not draw: the drawing of the engine reads it through IHudView once for every frame
  /// </summary>
  THeadsUp = class sealed(TInterfacedObject, IHeadsUp, IHudView)
  strict private
    FRules: THudRules;
    FFlags: IHudFlags;
    FMessages: IHudPlayerMessage;
    FSettings: IHudSettings;
    FBar: THudMessageBar;
    FBarTarget: IHudMessageTarget;
    FChat: THudChat;
    FFps: THudFpsCounter;
    FTitle: THudTextLine;
    FLevelTime: THudTextLine;
    FShiftTable: THudShiftTable;
  public
    /// <summary>
    ///   A heads-up display that follows the rules of a game and works through the services of the
    ///   engine; every service is needed
    /// </summary>
    constructor Create(const ARules: THudRules; const AFlags: IHudFlags; const APlayers: IHudPlayers;
      const AMessages: IHudPlayerMessage; const ASettings: IHudSettings;
      const ASound: IHudChatSound; const AEcho: IHudEcho);
    destructor Destroy; override;
    { IHeadsUp }
    procedure Initialize;
    procedure Start(const AParams: THudStartParams);
    procedure Ticker;
    function Responder(const AKey: Integer; const AIsKeyDown: Boolean): Boolean;
    function DequeueChatChar: Char;
    procedure RecordFrameTime(const ATime: Integer);
    function FramesPerSecond: Integer;
    function GetShiftTable: THudShiftTable;
    { IHudView }
    function GetMessageWindow: THudScrollingText;
    function GetMessageVisible: Boolean;
    function GetChatLine: THudInputText;
    function GetChatVisible: Boolean;
    function GetTitle: THudTextLine;
    function GetLevelTime: THudTextLine;
    function GetFpsText: string;
    procedure UpdateLevelTime(const ALevelTime: Integer);
    /// <summary>The message bar, for the tests and the tools that look inside the model</summary>
    property Bar: THudMessageBar read FBar;
    /// <summary>The chat, for the tests and the tools that look inside the model</summary>
    property Chat: THudChat read FChat;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.KeyTables, DelphiDoom.Hud.LevelTime;

{ THeadsUp }

constructor THeadsUp.Create(const ARules: THudRules; const AFlags: IHudFlags;
  const APlayers: IHudPlayers; const AMessages: IHudPlayerMessage; const ASettings: IHudSettings;
  const ASound: IHudChatSound; const AEcho: IHudEcho);
var
  LBar: THudMessageBar;
begin
  inherited Create;
  FRules := ARules;
  FFlags := AFlags;
  FMessages := AMessages;
  FSettings := ASettings;
  LBar := THudMessageBar.Create(ARules.MessageTimeout, AFlags, AMessages, ASettings, AEcho);
  // the bar is reference counted: the interface keeps it alive, the object reference only reads it
  FBarTarget := LBar;
  FBar := LBar;
  FChat := THudChat.Create(ARules, AFlags, APlayers, AMessages, ASettings, ASound, FBarTarget);
  FFps := THudFpsCounter.Create(ARules.TicRate, ARules.FpsLongHistory);
  FTitle := THudTextLine.Create(0, 0, 0);
  FLevelTime := THudTextLine.Create(0, 0, 0);
  FShiftTable := THudKeyTables.ShiftTransform(False);
end;

destructor THeadsUp.Destroy;
begin
  FLevelTime.Free;
  FTitle.Free;
  FFps.Free;
  FChat.Free;
  FBar := nil;
  FBarTarget := nil;
  inherited Destroy;
end;

procedure THeadsUp.Initialize;
begin
  FShiftTable := THudKeyTables.ShiftTransform(FSettings.IsFrench);
  FChat.UseShiftTable(FShiftTable);
  FFps.Clear;
end;

procedure THeadsUp.Start(const AParams: THudStartParams);
begin
  FMessages.AttachConsolePlayer;
  FFlags.ChatOn := False;
  FFlags.MessageForced := False;

  // the message window, the map title, the time of the level and the chat line
  FBar.Start(AParams.MessageX, AParams.MessageY, AParams.MessageHeight, AParams.LineHeight,
    AParams.StartChar);
  FTitle.Initialize(AParams.TitleX, AParams.TitleY, AParams.StartChar);
  FLevelTime.Initialize(AParams.LevelTimeX, AParams.LevelTimeY, AParams.StartChar);
  FTitle.AddText(AParams.Title);
  FChat.Start(AParams.InputX, AParams.InputY, AParams.StartChar);
end;

procedure THeadsUp.Ticker;
begin
  FFps.Tick;
  FBar.Tick;
  FChat.Tick;
end;

function THeadsUp.Responder(const AKey: Integer; const AIsKeyDown: Boolean): Boolean;
begin
  Result := FChat.Responder(AKey, AIsKeyDown);
end;

function THeadsUp.DequeueChatChar: Char;
begin
  Result := FChat.DequeueChar;
end;

procedure THeadsUp.RecordFrameTime(const ATime: Integer);
begin
  FFps.AddFrame(ATime);
end;

function THeadsUp.FramesPerSecond: Integer;
begin
  Result := FFps.FramesPerSecond;
end;

function THeadsUp.GetShiftTable: THudShiftTable;
begin
  Result := FShiftTable;
end;

function THeadsUp.GetMessageWindow: THudScrollingText;
begin
  Result := FBar.Window;
end;

function THeadsUp.GetMessageVisible: Boolean;
begin
  Result := FBar.Visible;
end;

function THeadsUp.GetChatLine: THudInputText;
begin
  Result := FChat.Input;
end;

function THeadsUp.GetChatVisible: Boolean;
begin
  Result := FFlags.ChatOn;
end;

function THeadsUp.GetTitle: THudTextLine;
begin
  Result := FTitle;
end;

function THeadsUp.GetLevelTime: THudTextLine;
begin
  Result := FLevelTime;
end;

function THeadsUp.GetFpsText: string;
begin
  Result := FFps.Text;
end;

procedure THeadsUp.UpdateLevelTime(const ALevelTime: Integer);
begin
  FLevelTime.Replace(THudLevelTime.Format(ALevelTime, FRules.TicRate));
end;

end.
