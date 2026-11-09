{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the keyboard functions of PS_GAME                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  gamekeydown, mousebuttons, joybuttons and the 56 functions that give the    }
{  key chosen for an action (key_right, mousebfire...). The last ones are a    }
{  table (DelphiDoom.ScriptHost.Keys.Table) and one small object for each      }
{  line, so the interpreter calls the same method with a different Self.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Keys;

interface

uses
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   One function of the keyboard of a script: it gives the key chosen for an action. Support
  ///   type of TScriptKeys: the interpreter calls Value with an object of this class as Self
  /// </summary>
  TScriptKeyBinding = class(TObject)
  strict private
    FSource: IScriptKeyboardSource;
    FKey: TScriptKey;
    FGuarded: Boolean;
  public
    constructor Create(const ASource: IScriptKeyboardSource; const AKey: TScriptKey;
      const AGuarded: Boolean);
    /// <summary>The key of the action; 0 while the input is not the one of the player (demo, network game)</summary>
    function Value: Integer;
  end;

  /// <summary>The functions of the keyboard of the unit PS_GAME</summary>
  TScriptKeys = class(TInterfacedObject, IScriptFunctionSection)
  strict private
    FSource: IScriptKeyboardSource;
    FGame: TScriptGame;
    FBindings: TObjectList<TScriptKeyBinding>;
  public
    /// <exception cref="EArgumentNilException">If the source is nil</exception>
    constructor Create(const ASource: IScriptKeyboardSource; const AGame: TScriptGame);
    destructor Destroy; override;
    procedure Describe(const ATable: IScriptFunctionTable);
    function GameKeyDown(const AKey: Integer): Boolean;
    function MouseButtons(const AButton: Integer): Boolean;
    function JoyButtons(const AButton: Integer): Boolean;
  end;

const
  /// <summary>The mouse has three buttons: the valid indexes of mousebuttons are 0 to 2</summary>
  SCRIPT_MOUSE_BUTTONS = 3;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Keys.Table;

{ TScriptKeyBinding }

constructor TScriptKeyBinding.Create(const ASource: IScriptKeyboardSource; const AKey: TScriptKey;
  const AGuarded: Boolean);
begin
  inherited Create;
  FSource := ASource;
  FKey := AKey;
  FGuarded := AGuarded;
end;

function TScriptKeyBinding.Value: Integer;
begin
  if FGuarded and FSource.IsInputBlocked then
    Result := 0
  else
    Result := FSource.KeyValue(FKey);
end;

{ TScriptKeys }

constructor TScriptKeys.Create(const ASource: IScriptKeyboardSource; const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FGame := AGame;
  FBindings := TObjectList<TScriptKeyBinding>.Create(True);
end;

destructor TScriptKeys.Destroy;
begin
  FBindings.Free;
  inherited Destroy;
end;

procedure TScriptKeys.Describe(const ATable: IScriptFunctionTable);
var
  LIndex: Integer;
  LBinding: TScriptKeyBinding;
begin
  // the group is described again when the script host starts again: the objects of the last
  // description go with the interpreters that used them
  FBindings.Clear;
  ATable.AddMethod('function gamekeydown(const kkey: integer): boolean;', Self,
    @TScriptKeys.GameKeyDown);
  ATable.AddMethod('function mousebuttons(const mkey: integer): boolean;', Self,
    @TScriptKeys.MouseButtons);
  ATable.AddMethod('function joybuttons(const jkey: integer): boolean;', Self,
    @TScriptKeys.JoyButtons);
  for LIndex := Low(SCRIPT_KEY_ENTRIES) to High(SCRIPT_KEY_ENTRIES) do
    if FGame in SCRIPT_KEY_ENTRIES[LIndex].Games then
    begin
      LBinding := TScriptKeyBinding.Create(FSource, SCRIPT_KEY_ENTRIES[LIndex].Key,
        SCRIPT_KEY_ENTRIES[LIndex].Guarded);
      FBindings.Add(LBinding);
      ATable.AddMethod('function ' + SCRIPT_KEY_ENTRIES[LIndex].Name + ': integer;', LBinding,
        @TScriptKeyBinding.Value);
    end;
end;

function TScriptKeys.GameKeyDown(const AKey: Integer): Boolean;
begin
  Result := (not FSource.IsInputBlocked) and (AKey >= 0) and (AKey < FSource.KeyCount)
    and FSource.IsKeyDown(AKey);
end;

function TScriptKeys.MouseButtons(const AButton: Integer): Boolean;
begin
  Result := (not FSource.IsInputBlocked) and (AButton >= 0) and (AButton < SCRIPT_MOUSE_BUTTONS)
    and FSource.IsMouseButtonDown(AButton);
end;

function TScriptKeys.JoyButtons(const AButton: Integer): Boolean;
begin
  Result := (not FSource.IsInputBlocked) and (AButton >= 0) and (AButton < FSource.JoyButtonCount)
    and FSource.IsJoyButtonDown(AButton);
end;

end.
