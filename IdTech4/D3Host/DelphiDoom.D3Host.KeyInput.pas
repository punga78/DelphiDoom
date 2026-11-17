{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - key input and bindings                    }
{                                                                              }
{  Port of Doom 3 (id Software): framework\KeyInput.cpp (idKeyInput).          }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
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
unit DelphiDoom.D3Host.KeyInput;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Input.Types,
  DelphiDoom.D3Host.Input.Intf, DelphiDoom.D3Host.KeyNames, DelphiDoom.D3Host.Lifecycle.Intf;

type
  /// <summary>
  ///   The key states and the bindings of the keys (idKeyInput, whose members are all static in the original: here
  ///   an object). The key table exists between Init and Shutdown; the overstrike mode and the ring of the last
  ///   keys (the cheat codes of Doom, still in the code) live as long as the object. The usercmd generator is
  ///   given after construction (SetUsercmd) because the two know each other: this object keeps it weakly.
  /// </summary>
  TD3KeyInput = class(TInterfacedObject, ID3KeyStates, ID3KeyBindingExecutor, ID3UsercmdActions, ID3KeyTracker, ID3Subsystem)
  strict private
    type
      TKey = record
        Down: Boolean;
        Binding: AnsiString;
        UsercmdAction: Integer;
      end;
    var
      FCommands: ICmdCommands;
      FBuffer: ICmdBuffer;
      FPrinter: ID3Printer;
      FText: ID3KeyText;
      FCVars: ID3CVarServices;
      [weak] FUsercmd: ID3UsercmdControl;
      FKeys: TArray<TKey>;
      FOverstrike: Boolean;
      FLastKeys: array[0..31] of Byte;
      FLastKeyIndex: Integer;
    procedure CheckKeys;
    procedure ListBinds(const AArgs: TIdCmdArgs);
    procedure BindCommand(const AArgs: TIdCmdArgs);
    procedure UnbindCommand(const AArgs: TIdCmdArgs);
    procedure UnbindAllCommand(const AArgs: TIdCmdArgs);
    procedure BindUnbindTwoCommand(const AArgs: TIdCmdArgs);
    procedure ArgCompletionKeyName(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
    procedure CheckCheatCodes;
  public
    constructor Create(const ACommands: ICmdCommands; const ABuffer: ICmdBuffer; const APrinter: ID3Printer;
      const AText: ID3KeyText; const ACVars: ID3CVarServices);
    /// <summary>The usercmd generator that Clear and CommandStringUsercmdData go to (not owned)</summary>
    procedure SetUsercmd(const AUsercmd: ID3UsercmdControl);
    /// <summary>idKeyInput::Init: a new key table and the commands bind, bindunbindtwo, unbind, unbindall, listBinds</summary>
    procedure Init;
    /// <summary>idKeyInput::Shutdown: frees the key table</summary>
    procedure Shutdown;
    function IsDown(const AKey: Integer): Boolean;
    function GetOverstrikeMode: Boolean;
    procedure SetOverstrikeMode(const AState: Boolean);
    function GetUsercmdAction(const AKey: Integer): Integer;
    /// <summary>idKeyInput::PreliminaryKeyEvent: tracks the state; a key that goes down feeds the cheat code ring</summary>
    procedure PreliminaryKeyEvent(const AKey: Integer; const ADown: Boolean);
    function ExecKeyBinding(const AKey: Integer): Boolean;
    /// <summary>idKeyInput::ClearStates: every key up (through PreliminaryKeyEvent), the usercmd states cleared</summary>
    procedure ClearStates;
    /// <summary>idKeyInput::SetBinding: -1 is ignored; clears the usercmd states, sets the action and the modified flag</summary>
    procedure SetBinding(const AKey: Integer; const ABinding: AnsiString);
    function GetBinding(const AKey: Integer): AnsiString;
    /// <summary>idKeyInput::UnbindBinding: true if some key had it (compared without regard to case)</summary>
    function UnbindBinding(const ABinding: AnsiString): Boolean;
    function NumBinds(const ABinding: AnsiString): Integer;
    function KeyIsBoundTo(const AKey: Integer; const ABinding: AnsiString): Boolean;
    /// <summary>idKeyInput::KeysFromBinding: the localized names of the keys, lowercased, joined by the language text</summary>
    function KeysFromBinding(const ABinding: AnsiString): AnsiString;
    /// <summary>idKeyInput::BindingFromKey: AFound is false where the original returns NULL (no such key)</summary>
    function BindingFromKey(const AKey: AnsiString; out AFound: Boolean): AnsiString;
    /// <summary>idKeyInput::WriteBindings: "unbindall" and a bind line for every bound key</summary>
    procedure WriteBindings(const AFile: ID3CommonFile);
  end;

implementation

const
  D3_CVAR_ARCHIVE_FLAG = 64;
  CMD_FL_SYSTEM_FLAG = 2;
  SBindUsage = 'bind <key> [command] : attach a command to a key' + #10;
  SUnbindUsage = 'unbind <key> : remove commands from a key' + #10;
  SBindUnbindTwoUsage = 'bindunbindtwo <keynum> [command]' + #10;
  SCheatMessage = 'your memory serves you well!' + #10;
  SSeparatorId = '#str_07183';
  SNoKeyId = '#str_07133';
  CheatCodes: array[0..5] of AnsiString = ('iddqd', 'idkfa', 'idfa', 'idspispopd', 'idclip', 'idchoppers');

function LowerAscii(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if Result[LIndex] in ['A'..'Z'] then
      Inc(Byte(Result[LIndex]), 32);
end;

constructor TD3KeyInput.Create(const ACommands: ICmdCommands; const ABuffer: ICmdBuffer; const APrinter: ID3Printer;
  const AText: ID3KeyText; const ACVars: ID3CVarServices);
begin
  inherited Create;
  FCommands := ACommands;
  FBuffer := ABuffer;
  FPrinter := APrinter;
  FText := AText;
  FCVars := ACVars;
end;

procedure TD3KeyInput.SetUsercmd(const AUsercmd: ID3UsercmdControl);
begin
  FUsercmd := AUsercmd;
end;

procedure TD3KeyInput.CheckKeys;
begin
  if FKeys = nil then
    raise ED3HostException.Create('idKeyInput is not initialized');
end;

procedure TD3KeyInput.Init;
begin
  SetLength(FKeys, D3_MAX_KEYS);
  FCommands.AddCommand('bind', BindCommand, CMD_FL_SYSTEM_FLAG, 'binds a command to a key', ArgCompletionKeyName);
  FCommands.AddCommand('bindunbindtwo', BindUnbindTwoCommand, CMD_FL_SYSTEM_FLAG,
    'binds a key but unbinds it first if there are more than two binds');
  FCommands.AddCommand('unbind', UnbindCommand, CMD_FL_SYSTEM_FLAG, 'unbinds any command from a key',
    ArgCompletionKeyName);
  FCommands.AddCommand('unbindall', UnbindAllCommand, CMD_FL_SYSTEM_FLAG, 'unbinds any commands from all keys');
  FCommands.AddCommand('listBinds', ListBinds, CMD_FL_SYSTEM_FLAG, 'lists key bindings');
end;

procedure TD3KeyInput.Shutdown;
begin
  FKeys := nil;
end;

procedure TD3KeyInput.ArgCompletionKeyName(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
begin
  TD3KeyNames.ArgCompletionKeyName(AArgs.Argv(0), ACallback);
end;

function TD3KeyInput.IsDown(const AKey: Integer): Boolean;
begin
  if AKey = -1 then
    Exit(False);
  CheckKeys;
  Result := FKeys[AKey].Down;
end;

function TD3KeyInput.GetOverstrikeMode: Boolean;
begin
  Result := FOverstrike;
end;

procedure TD3KeyInput.SetOverstrikeMode(const AState: Boolean);
begin
  FOverstrike := AState;
end;

function TD3KeyInput.GetUsercmdAction(const AKey: Integer): Integer;
begin
  CheckKeys;
  Result := FKeys[AKey].UsercmdAction;
end;

procedure TD3KeyInput.CheckCheatCodes;
var
  LCode: Integer;
  LLength: Integer;
  LStart: Integer;
  LChar: Integer;
  LMatch: Boolean;
  LLeft: Byte;
  LRight: Byte;
begin
  for LCode := Low(CheatCodes) to High(CheatCodes) do
  begin
    LLength := Length(CheatCodes[LCode]);
    LStart := 16 + (FLastKeyIndex and 15) - LLength;
    LMatch := True;
    for LChar := 0 to LLength - 1 do
    begin
      LLeft := FLastKeys[LStart + LChar];
      LRight := Byte(CheatCodes[LCode][LChar + 1]);
      if LLeft in [Ord('a')..Ord('z')] then
        Dec(LLeft, 32);
      if LRight in [Ord('a')..Ord('z')] then
        Dec(LRight, 32);
      if LLeft <> LRight then
      begin
        LMatch := False;
        Break;
      end;
    end;
    if LMatch then
    begin
      FPrinter.Printf(SCheatMessage);
      Break;
    end;
  end;
end;

procedure TD3KeyInput.PreliminaryKeyEvent(const AKey: Integer; const ADown: Boolean);
begin
  CheckKeys;
  FKeys[AKey].Down := ADown;
  if ADown then
  begin
    FLastKeys[0 + (FLastKeyIndex and 15)] := Byte(AKey);
    FLastKeys[16 + (FLastKeyIndex and 15)] := Byte(AKey);
    FLastKeyIndex := (FLastKeyIndex + 1) and 15;
    CheckCheatCodes;
  end;
end;

function TD3KeyInput.ExecKeyBinding(const AKey: Integer): Boolean;
begin
  CheckKeys;
  // commands that are used by the async thread don't add text
  if FKeys[AKey].UsercmdAction <> 0 then
    Exit(False);
  if Length(FKeys[AKey].Binding) > 0 then
  begin
    FBuffer.BufferCommandText(ceAppend, FKeys[AKey].Binding);
    FBuffer.BufferCommandText(ceAppend, #10);
  end;
  Result := True;
end;

procedure TD3KeyInput.ClearStates;
var
  LIndex: Integer;
begin
  CheckKeys;
  for LIndex := 0 to D3_MAX_KEYS - 1 do
  begin
    if FKeys[LIndex].Down then
      PreliminaryKeyEvent(LIndex, False);
    FKeys[LIndex].Down := False;
  end;
  if Assigned(FUsercmd) then
    FUsercmd.Clear;
end;

procedure TD3KeyInput.SetBinding(const AKey: Integer; const ABinding: AnsiString);
begin
  if AKey = -1 then
    Exit;
  CheckKeys;
  // clear out all button states so we aren't stuck forever thinking this key is held down
  if Assigned(FUsercmd) then
    FUsercmd.Clear;
  FKeys[AKey].Binding := ABinding;
  // the action for the async command generation
  if Assigned(FUsercmd) then
    FKeys[AKey].UsercmdAction := FUsercmd.CommandStringUsercmdData(ABinding)
  else
    FKeys[AKey].UsercmdAction := 0;
  // like modifying an archived cvar: the file write is triggered at the next opportunity
  FCVars.SetModifiedFlags(D3_CVAR_ARCHIVE_FLAG);
end;

function TD3KeyInput.GetBinding(const AKey: Integer): AnsiString;
begin
  if AKey = -1 then
    Exit('');
  CheckKeys;
  Result := FKeys[AKey].Binding;
end;

function TD3KeyInput.UnbindBinding(const ABinding: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  if ABinding = '' then
    Exit;
  CheckKeys;
  for LIndex := 0 to D3_MAX_KEYS - 1 do
    if SameText(string(FKeys[LIndex].Binding), string(ABinding)) then
    begin
      SetBinding(LIndex, '');
      Result := True;
    end;
end;

function TD3KeyInput.NumBinds(const ABinding: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  if ABinding = '' then
    Exit;
  CheckKeys;
  for LIndex := 0 to D3_MAX_KEYS - 1 do
    if SameText(string(FKeys[LIndex].Binding), string(ABinding)) then
      Inc(Result);
end;

function TD3KeyInput.KeyIsBoundTo(const AKey: Integer; const ABinding: AnsiString): Boolean;
begin
  Result := False;
  if (AKey >= 0) and (AKey < D3_MAX_KEYS) then
  begin
    CheckKeys;
    Result := SameText(string(FKeys[AKey].Binding), string(ABinding));
  end;
end;

function TD3KeyInput.KeysFromBinding(const ABinding: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  if ABinding <> '' then
  begin
    CheckKeys;
    for LIndex := 0 to D3_MAX_KEYS - 1 do
      if SameText(string(FKeys[LIndex].Binding), string(ABinding)) then
      begin
        if Result <> '' then
          Result := Result + FText.LanguageString(SSeparatorId);
        Result := Result + TD3KeyNames.KeyNumToString(LIndex, True, FText);
      end;
  end;
  if Result = '' then
    Result := FText.LanguageString(SNoKeyId);
  Result := LowerAscii(Result);
end;

function TD3KeyInput.BindingFromKey(const AKey: AnsiString; out AFound: Boolean): AnsiString;
var
  LKey: Integer;
begin
  LKey := TD3KeyNames.StringToKeyNum(AKey);
  AFound := (LKey >= 0) and (LKey < D3_MAX_KEYS);
  if not AFound then
    Exit('');
  CheckKeys;
  Result := FKeys[LKey].Binding;
end;

procedure TD3KeyInput.WriteBindings(const AFile: ID3CommonFile);
var
  LIndex: Integer;
  LName: AnsiString;
  procedure WriteText(const AText: AnsiString);
  begin
    AFile.Write(AText[1], Length(AText));
  end;
begin
  CheckKeys;
  WriteText('unbindall' + #10);
  for LIndex := 0 to D3_MAX_KEYS - 1 do
    if Length(FKeys[LIndex].Binding) > 0 then
    begin
      LName := TD3KeyNames.KeyNumToString(LIndex, False, FText);
      // handle the escape character nicely
      if LName = '\' then
        WriteText('bind "\" "' + FKeys[LIndex].Binding + '"' + #10)
      else
        WriteText('bind "' + LName + '" "' + FKeys[LIndex].Binding + '"' + #10);
    end;
end;

procedure TD3KeyInput.BindCommand(const AArgs: TIdCmdArgs);
var
  LCount: Integer;
  LKey: Integer;
  LIndex: Integer;
  LCommand: AnsiString;
begin
  LCount := AArgs.Argc;
  if LCount < 2 then
  begin
    FPrinter.Printf(SBindUsage);
    Exit;
  end;
  LKey := TD3KeyNames.StringToKeyNum(AArgs.Argv(1));
  if LKey = -1 then
  begin
    FPrinter.Printf('"' + AArgs.Argv(1) + '" isn''t a valid key' + #10);
    Exit;
  end;
  CheckKeys;
  if LCount = 2 then
  begin
    if Length(FKeys[LKey].Binding) > 0 then
      FPrinter.Printf('"' + AArgs.Argv(1) + '" = "' + FKeys[LKey].Binding + '"' + #10)
    else
      FPrinter.Printf('"' + AArgs.Argv(1) + '" is not bound' + #10);
    Exit;
  end;
  // copy the rest of the command line
  LCommand := '';
  for LIndex := 2 to LCount - 1 do
  begin
    LCommand := LCommand + AArgs.Argv(LIndex);
    if LIndex <> LCount - 1 then
      LCommand := LCommand + ' ';
  end;
  SetBinding(LKey, LCommand);
end;

procedure TD3KeyInput.UnbindCommand(const AArgs: TIdCmdArgs);
var
  LKey: Integer;
begin
  if AArgs.Argc <> 2 then
  begin
    FPrinter.Printf(SUnbindUsage);
    Exit;
  end;
  LKey := TD3KeyNames.StringToKeyNum(AArgs.Argv(1));
  if LKey = -1 then
  begin
    // if it wasn't a key, it could be a command
    if not UnbindBinding(AArgs.Argv(1)) then
      FPrinter.Printf('"' + AArgs.Argv(1) + '" isn''t a valid key' + #10);
  end
  else
    SetBinding(LKey, '');
end;

procedure TD3KeyInput.UnbindAllCommand(const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
begin
  for LIndex := 0 to D3_MAX_KEYS - 1 do
    SetBinding(LIndex, '');
end;

procedure TD3KeyInput.BindUnbindTwoCommand(const AArgs: TIdCmdArgs);
var
  LKey: Integer;
  LBinding: AnsiString;
begin
  if AArgs.Argc < 3 then
  begin
    FPrinter.Printf(SBindUnbindTwoUsage);
    Exit;
  end;
  LKey := TD3CNumbers.Atoi(AArgs.Argv(1));
  LBinding := AArgs.Argv(2);
  if (NumBinds(LBinding) >= 2) and (not KeyIsBoundTo(LKey, LBinding)) then
    UnbindBinding(LBinding);
  SetBinding(LKey, LBinding);
end;

procedure TD3KeyInput.ListBinds(const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
begin
  CheckKeys;
  for LIndex := 0 to D3_MAX_KEYS - 1 do
    if Length(FKeys[LIndex].Binding) > 0 then
      FPrinter.Printf(TD3KeyNames.KeyNumToString(LIndex, False, FText) + ' "' + FKeys[LIndex].Binding + '"' +
        #10);
end;

end.
