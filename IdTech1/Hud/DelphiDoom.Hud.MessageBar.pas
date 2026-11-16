{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the messages at the top of the screen}
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.MessageBar;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.ScrollingText;

type
  /// <summary>
  ///   The messages the player reads at the top of the screen (the message part of HU_Ticker): a
  ///   window of text, the time it stays on and the rule that a message that must be read is not
  ///   replaced by the next one
  /// </summary>
  THudMessageBar = class sealed(TInterfacedObject, IHudMessageTarget)
  strict private
    FFlags: IHudFlags;
    FMessages: IHudPlayerMessage;
    FSettings: IHudSettings;
    FWindow: THudScrollingText;
    FTimeout: Integer;
    FCounter: Integer;
    FVisible: Boolean;
    FProtected: Boolean;
  public
    /// <summary>
    ///   A bar that keeps each message for ATimeout tics, takes the messages of the player from
    ///   AMessages and copies them with AEcho
    /// </summary>
    constructor Create(const ATimeout: Integer; const AFlags: IHudFlags;
      const AMessages: IHudPlayerMessage; const ASettings: IHudSettings; const AEcho: IHudEcho);
    destructor Destroy; override;
    /// <summary>A level starts: the window is as new, nothing is shown (the message part of HU_Start)</summary>
    procedure Start(const AX, AY, AHeight, ALineHeight, AStartChar: Integer);
    /// <summary>A tic: the time of the message goes down and a new message of the player is taken</summary>
    procedure Tick;
    procedure Refresh;
    procedure PostChat(const APrefix, AText: string);
    /// <summary>The window of text</summary>
    property Window: THudScrollingText read FWindow;
    /// <summary>A message is on the screen (message_on)</summary>
    property Visible: Boolean read FVisible;
    /// <summary>The message on the screen must not be replaced (message_nottobefuckedwith)</summary>
    property Locked: Boolean read FProtected;
    /// <summary>Tics the message will stay (message_counter)</summary>
    property Counter: Integer read FCounter;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SMissingService = 'The message bar needs the %s';

{ THudMessageBar }

constructor THudMessageBar.Create(const ATimeout: Integer; const AFlags: IHudFlags;
  const AMessages: IHudPlayerMessage; const ASettings: IHudSettings; const AEcho: IHudEcho);
begin
  inherited Create;
  if not Assigned(AFlags) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['flags']);
  if not Assigned(AMessages) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['player message']);
  if not Assigned(ASettings) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['settings']);
  FFlags := AFlags;
  FMessages := AMessages;
  FSettings := ASettings;
  FTimeout := ATimeout;
  FWindow := THudScrollingText.Create(AEcho);
end;

destructor THudMessageBar.Destroy;
begin
  FWindow.Free;
  inherited Destroy;
end;

procedure THudMessageBar.Start(const AX, AY, AHeight, ALineHeight, AStartChar: Integer);
begin
  FVisible := False;
  FProtected := False;
  FWindow.Initialize(AX, AY, AHeight, ALineHeight, AStartChar);
end;

procedure THudMessageBar.Tick;
var
  LMessage: string;
begin
  // tick down the message counter if a message is up
  if FCounter <> 0 then
  begin
    Dec(FCounter);
    if FCounter = 0 then
    begin
      FWindow.RemoveRow;
      FVisible := FWindow.Current.Length > 0;
      if FVisible then
        FCounter := FTimeout;
      FProtected := False;
    end;
  end;

  if FSettings.AreMessagesShown or FFlags.MessageForced then
  begin
    // display the message of the player if necessary
    LMessage := FMessages.ReadMessage;
    if (LMessage <> '') and (not FProtected or FFlags.MessageForced) then
    begin
      FWindow.AddMessageBelow('', LMessage);
      FMessages.WriteMessage('');
      FVisible := True;
      FCounter := FTimeout;
      FProtected := FFlags.MessageForced;
      FFlags.MessageForced := False;
    end;
  end;
end;

procedure THudMessageBar.Refresh;
begin
  FVisible := True;
  FCounter := FTimeout;
end;

procedure THudMessageBar.PostChat(const APrefix, AText: string);
begin
  FWindow.AddMessage(APrefix, AText);
  FProtected := True;
  FVisible := True;
  FCounter := FTimeout;
end;

end.
