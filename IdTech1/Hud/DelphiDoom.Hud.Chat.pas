{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the chat                             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.Chat;

interface

uses
  DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.InputText, DelphiDoom.Hud.ChatQueue;

type
  /// <summary>
  ///   The chat between players of a network game (HU_Responder, the chat part of HU_Ticker and
  ///   HU_queueChatChar): the key that opens the line, the keys that write in it, the macros, the
  ///   characters that wait to be sent and the ones that come from the others
  /// </summary>
  THudChat = class sealed
  strict private
    FRules: THudRules;
    FFlags: IHudFlags;
    FPlayers: IHudPlayers;
    FMessages: IHudPlayerMessage;
    FSettings: IHudSettings;
    FSound: IHudChatSound;
    FTarget: IHudMessageTarget;
    FInput: THudInputText;
    FBuffers: array[0..HUD_MAX_PLAYERS - 1] of THudInputText;
    FDestination: array[0..HUD_MAX_PLAYERS - 1] of Integer;
    FQueue: THudChatQueue;
    FShiftTable: THudShiftTable;
    FShiftDown: Boolean;
    FAltDown: Boolean;
    FLastMessage: string;
    FTalkToSelfCount: Integer;
    procedure QueueChar(const AChar: Char);
    function CountPlayers: Integer;
    function OutsideChat(const AKey, APlayerCount: Integer): Boolean;
    function InsideChat(const AKey: Integer): Boolean;
    function SendMacro(const ACode: Integer): Boolean;
    procedure TalkToSelf;
    procedure ReceiveCharacter(const APlayer: Integer; const ACode: Integer);
  public
    /// <summary>A chat that works through the given services; every one is needed</summary>
    constructor Create(const ARules: THudRules; const AFlags: IHudFlags; const APlayers: IHudPlayers;
      const AMessages: IHudPlayerMessage; const ASettings: IHudSettings;
      const ASound: IHudChatSound; const ATarget: IHudMessageTarget);
    destructor Destroy; override;
    /// <summary>A level starts: the line of the player is put at the given place (the chat part of HU_Start)</summary>
    procedure Start(const AX, AY, AStartChar: Integer);
    /// <summary>Chooses the keyboard map used when shift is down</summary>
    procedure UseShiftTable(const ATable: THudShiftTable);
    /// <summary>A key (HU_Responder), true if the chat ate it</summary>
    function Responder(const AKey: Integer; const AIsKeyDown: Boolean): Boolean;
    /// <summary>A tic: the characters the other players typed are read (the chat part of HU_Ticker)</summary>
    procedure Tick;
    /// <summary>The next character to send, #0 if none (HU_dequeueChatChar)</summary>
    function DequeueChar: Char;
    /// <summary>The line where the player types</summary>
    property Input: THudInputText read FInput;
    /// <summary>The line where the text of a player is collected until the return key (w_inputbuffer)</summary>
    function Buffer(const APlayer: Integer): THudInputText;
    /// <summary>Who the player is writing to (chat_dest): a player number plus one, or the broadcast code</summary>
    function Destination(const APlayer: Integer): Integer;
    /// <summary>The last message the player sent (lastmessage)</summary>
    property LastMessage: string read FLastMessage;
    /// <summary>Times the player tried to talk to himself (num_nobrainers)</summary>
    property TalkToSelfCount: Integer read FTalkToSelfCount;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.KeyTables;

resourcestring
  SMissingService = 'The chat needs the %s';
  STooManyPlayers = 'The chat holds from 1 to %d players, not %d';

{ THudChat }

constructor THudChat.Create(const ARules: THudRules; const AFlags: IHudFlags;
  const APlayers: IHudPlayers; const AMessages: IHudPlayerMessage; const ASettings: IHudSettings;
  const ASound: IHudChatSound; const ATarget: IHudMessageTarget);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AFlags) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['flags']);
  if not Assigned(APlayers) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['players']);
  if not Assigned(AMessages) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['player message']);
  if not Assigned(ASettings) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['settings']);
  if not Assigned(ASound) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['chat sound']);
  if not Assigned(ATarget) then
    raise EArgumentNilException.CreateFmt(SMissingService, ['message target']);
  if (ARules.MaxPlayers < 1) or (ARules.MaxPlayers > HUD_MAX_PLAYERS) then
    raise EHudException.CreateFmt(STooManyPlayers, [HUD_MAX_PLAYERS, ARules.MaxPlayers]);
  FRules := ARules;
  FFlags := AFlags;
  FPlayers := APlayers;
  FMessages := AMessages;
  FSettings := ASettings;
  FSound := ASound;
  FTarget := ATarget;
  FInput := THudInputText.Create(ARules.Keys);
  for LIndex := 0 to HUD_MAX_PLAYERS - 1 do
    FBuffers[LIndex] := THudInputText.Create(ARules.Keys);
  FQueue := THudChatQueue.Create;
  FShiftTable := THudKeyTables.ShiftTransform(False);
end;

destructor THudChat.Destroy;
var
  LIndex: Integer;
begin
  FQueue.Free;
  for LIndex := 0 to HUD_MAX_PLAYERS - 1 do
    FBuffers[LIndex].Free;
  FInput.Free;
  inherited Destroy;
end;

procedure THudChat.Start(const AX, AY, AStartChar: Integer);
var
  LIndex: Integer;
begin
  FInput.Initialize(AX, AY, AStartChar);
  for LIndex := 0 to FRules.MaxPlayers - 1 do
    FBuffers[LIndex].Initialize(0, 0, 0);
end;

procedure THudChat.UseShiftTable(const ATable: THudShiftTable);
begin
  FShiftTable := ATable;
end;

procedure THudChat.QueueChar(const AChar: Char);
begin
  if not FQueue.Enqueue(AChar) then
    FMessages.WriteMessage(FSettings.QueueFullMessage);
end;

function THudChat.DequeueChar: Char;
begin
  Result := FQueue.Dequeue;
end;

function THudChat.Buffer(const APlayer: Integer): THudInputText;
begin
  Result := FBuffers[APlayer];
end;

function THudChat.Destination(const APlayer: Integer): Integer;
begin
  Result := FDestination[APlayer];
end;

function THudChat.CountPlayers: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FRules.MaxPlayers - 1 do
    if FPlayers.IsInGame(LIndex) then
      Inc(Result);
end;

procedure THudChat.TalkToSelf;
begin
  Inc(FTalkToSelfCount);
  if FTalkToSelfCount < 3 then
    FMessages.WriteMessage(FSettings.TalkToSelfMessage(1))
  else if FTalkToSelfCount < 6 then
    FMessages.WriteMessage(FSettings.TalkToSelfMessage(2))
  else if FTalkToSelfCount < 9 then
    FMessages.WriteMessage(FSettings.TalkToSelfMessage(3))
  else if FTalkToSelfCount < 32 then
    FMessages.WriteMessage(FSettings.TalkToSelfMessage(4))
  else
    FMessages.WriteMessage(FSettings.TalkToSelfMessage(5));
end;

function THudChat.OutsideChat(const AKey, APlayerCount: Integer): Boolean;
var
  LIndex: Integer;
  LKeyCode: Integer;
begin
  Result := False;
  if AKey = FRules.MessageRefreshKey then
  begin
    FTarget.Refresh;
    Result := True;
  end
  else if FPlayers.IsNetGame and (AKey = FRules.InputToggleKey) then
  begin
    Result := True;
    FFlags.ChatOn := True;
    FInput.Reset;
    QueueChar(Chr(FRules.Broadcast));
  end
  else if FPlayers.IsNetGame and (APlayerCount > 2) then
  begin
    for LIndex := 0 to FRules.MaxPlayers - 1 do
    begin
      LKeyCode := FSettings.DestinationKeyCode(LIndex);
      if (LKeyCode >= 0) and (AKey = LKeyCode) then
      begin
        if FPlayers.IsInGame(LIndex) and (LIndex <> FPlayers.ConsolePlayerIndex) then
        begin
          Result := True;
          FFlags.ChatOn := True;
          FInput.Reset;
          QueueChar(Chr(LIndex + 1));
          Break;
        end
        else if LIndex = FPlayers.ConsolePlayerIndex then
          TalkToSelf;
      end;
    end;
  end;
end;

function THudChat.SendMacro(const ACode: Integer): Boolean;
var
  LMacro: string;
  LIndex: Integer;
begin
  Result := False;
  // the number of the macro is the key minus '0': a key before the zero wraps and does not fit
  if ACode > 9 then
    Exit;
  LMacro := FSettings.ChatMacro(ACode);

  // kill last message with a '\n'
  QueueChar(Chr(FRules.Keys.Enter));

  // send the macro message
  for LIndex := 1 to Length(LMacro) do
    QueueChar(LMacro[LIndex]);
  QueueChar(Chr(FRules.Keys.Enter));

  // leave chat mode and notify that it was sent
  FFlags.ChatOn := False;
  FLastMessage := LMacro;
  FMessages.WriteMessage(FLastMessage);
  Result := True;
end;

function THudChat.InsideChat(const AKey: Integer): Boolean;
var
  LCode: Integer;
begin
  // the character is the key as a Char (16 bit)
  LCode := AKey and $FFFF;
  if FAltDown then
    // send a macro
    Exit(SendMacro((LCode - Ord('0')) and $FFFF));

  if FSettings.IsFrench then
    LCode := Ord(THudKeyTables.ForeignTranslation(Chr(LCode)));
  if FShiftDown or ((LCode >= Ord('a')) and (LCode <= Ord('z'))) then
    // a key above the table has no shifted character: it stays as it is (the old code read what
    // came after the table)
    if LCode < HUD_SHIFT_TABLE_SIZE then
      LCode := Ord(FShiftTable[LCode]);
  // the key of the input line is a byte
  Result := FInput.KeyIn(LCode and $FF);
  if Result then
    QueueChar(Chr(LCode));
  if LCode = FRules.Keys.Enter then
  begin
    FFlags.ChatOn := False;
    if FInput.Line.Length <> 0 then
    begin
      FLastMessage := string(FInput.Line.Text);
      FMessages.WriteMessage(FLastMessage);
    end;
  end
  else if LCode = FRules.Keys.Escape then
    FFlags.ChatOn := False;
end;

function THudChat.Responder(const AKey: Integer; const AIsKeyDown: Boolean): Boolean;
var
  LPlayerCount: Integer;
begin
  Result := False;

  if AKey = FRules.Keys.RightShift then
  begin
    FShiftDown := AIsKeyDown;
    Exit;
  end
  else if (AKey = FRules.Keys.RightAlt) or (AKey = FRules.Keys.LeftAlt) then
  begin
    FAltDown := AIsKeyDown;
    Exit;
  end;

  if not AIsKeyDown then
    Exit;

  LPlayerCount := CountPlayers;
  if not FFlags.ChatOn then
    Result := OutsideChat(AKey, LPlayerCount)
  else
    Result := InsideChat(AKey);
end;

procedure THudChat.ReceiveCharacter(const APlayer: Integer; const ACode: Integer);
var
  LCode: Integer;
  LBuffer: THudInputText;
begin
  LCode := ACode;
  if (LCode >= Ord('a')) and (LCode <= Ord('z')) then
    LCode := Ord(FShiftTable[LCode]);
  LBuffer := FBuffers[APlayer];
  if LBuffer.KeyIn(LCode) and (LCode = FRules.Keys.Enter) then
  begin
    if (LBuffer.Line.Length <> 0) and
      ((FDestination[APlayer] = FPlayers.ConsolePlayerIndex + 1) or
       (FDestination[APlayer] = FRules.Broadcast)) then
    begin
      FTarget.PostChat(FSettings.PlayerName(APlayer), string(LBuffer.Line.Text));
      FSound.PlayChatSound;
    end;
    LBuffer.Reset;
  end;
end;

procedure THudChat.Tick;
var
  LIndex: Integer;
  LCode: Integer;
begin
  // check for incoming chat characters
  if not FPlayers.IsNetGame then
    Exit;
  for LIndex := 0 to FRules.MaxPlayers - 1 do
  begin
    if not FPlayers.IsInGame(LIndex) then
      Continue;
    LCode := FPlayers.ChatChar(LIndex);
    if (LIndex <> FPlayers.ConsolePlayerIndex) and (LCode <> 0) then
    begin
      if LCode <= FRules.LastDestination then
        FDestination[LIndex] := LCode
      else
        ReceiveCharacter(LIndex, LCode);
      FPlayers.ClearChatChar(LIndex);
    end;
  end;
end;

end.
