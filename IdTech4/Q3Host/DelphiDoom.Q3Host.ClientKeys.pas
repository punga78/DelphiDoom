{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the keys of the client (state, names    }
{  and bindings)                                                                }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_keys.c        }
{  (Key_StringToKeynum, Key_KeynumToString, Key_SetBinding, Key_GetBinding,     }
{  Key_GetKey, Key_IsDown, Key_ClearStates) and cl_ui.c (Key_GetCatcher).       }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the      }
{  Quake III Arena source code and is therefore available under the GNU         }
{  General Public License, version 2 or (at your option) any later version.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientKeys;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   keys[], cls.keyCatchers and key_overstrikeMode, and the names of the keys. The input of the window calls
  ///   SetDown; the bindings are what the "bind" command and the menus set. Differences from the C: a key number out
  ///   of 0..255 is never down and a binding to it is ignored (the C indexes keys[] with it)
  /// </summary>
  TQ3ClientKeys = class(TInterfacedObject, IQ3HostKeys)
  strict private
    FDown: array[0..255] of Boolean;
    FBound: array[0..255] of Boolean;
    FBindings: array[0..255] of AnsiString;
    FCatcher: Integer;
    FOverstrike: Boolean;
    FCVars: IQ3CVarSystem;
    FOnKeyReleased: TProc<Integer>;
  public
    /// <param name="ACVars">Where cvar_modifiedFlags |= CVAR_ARCHIVE goes when a binding changes; may be nil</param>
    constructor Create(const ACVars: IQ3CVarSystem = nil);
    /// <summary>Key_StringToKeynum: a character, a name of the table (ignoring case) or 0xnn; -1 when it is none</summary>
    class function StringToKeynum(const AText: AnsiString): Integer; static;
    function IsDown(AKey: Integer): Boolean;
    function GetCatcher: Integer;
    procedure SetCatcher(AValue: Integer);
    function GetKey(const ABinding: AnsiString): Integer;
    function KeynumToString(AKey: Integer): AnsiString;
    function GetBinding(AKey: Integer): AnsiString;
    procedure SetBinding(AKey: Integer; const ABinding: AnsiString);
    function GetOverstrikeMode: Boolean;
    procedure SetOverstrikeMode(AValue: Boolean);
    procedure ClearStates;
    /// <summary>The state of a key as the window reports it</summary>
    procedure SetDown(AKey: Integer; ADown: Boolean);
    /// <summary>The key up event that Key_ClearStates sends (CL_KeyEvent( i, qfalse, 0 )) for every key that was down</summary>
    property OnKeyReleased: TProc<Integer> read FOnKeyReleased write FOnKeyReleased;
  end;

implementation

uses
  DelphiDoom.Q3Host.Client.KeyNames;

const
  HEX_DIGITS: AnsiString = '0123456789abcdef';

function LowerAscii(AChar: AnsiChar): AnsiChar; inline;
begin
  if AChar in ['A'..'Z'] then
    Result := AnsiChar(Ord(AChar) + 32)
  else
    Result := AChar;
end;

function SameTextAscii(const AText, AOther: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  if Length(AText) <> Length(AOther) then
    Exit(False);
  for LIndex := 1 to Length(AText) do
    if LowerAscii(AText[LIndex]) <> LowerAscii(AOther[LIndex]) then
      Exit(False);
  Result := True;
end;

function HexValue(AChar: AnsiChar): Integer;
begin
  // only lowercase letters are digits, as in the C
  if AChar in ['0'..'9'] then
    Result := Ord(AChar) - Ord('0')
  else if AChar in ['a'..'f'] then
    Result := Ord(AChar) - Ord('a') + 10
  else
    Result := 0;
end;

constructor TQ3ClientKeys.Create(const ACVars: IQ3CVarSystem);
begin
  inherited Create;
  FCVars := ACVars;
end;

class function TQ3ClientKeys.StringToKeynum(const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  if AText = '' then
    Exit(-1);
  if Length(AText) = 1 then
    Exit(ShortInt(Byte(AText[1]))); // char has a sign: a byte from 128 up is negative, as in the C
  // check for hex code
  if (AText[1] = '0') and (AText[2] = 'x') and (Length(AText) = 4) then
    Exit(HexValue(AText[3]) * 16 + HexValue(AText[4]));
  // scan for a text match
  for LIndex := 0 to Q3_KEY_NAME_COUNT - 1 do
    if SameTextAscii(AText, Q3_KEY_NAMES[LIndex].Name) then
      Exit(Q3_KEY_NAMES[LIndex].Number);
  Result := -1;
end;

function TQ3ClientKeys.KeynumToString(AKey: Integer): AnsiString;
var
  LIndex: Integer;
begin
  if AKey = -1 then
    Exit('<KEY NOT FOUND>');
  if (AKey < 0) or (AKey > 255) then
    Exit('<OUT OF RANGE>');
  // check for printable ascii (don't use quote)
  if (AKey > 32) and (AKey < 127) and (AKey <> Ord('"')) and (AKey <> Ord(';')) then
  begin
    SetLength(Result, 1);
    Result[1] := AnsiChar(AKey);
    Exit;
  end;
  // check for a key string
  for LIndex := 0 to Q3_KEY_NAME_COUNT - 1 do
    if Q3_KEY_NAMES[LIndex].Number = AKey then
      Exit(Q3_KEY_NAMES[LIndex].Name);
  // make a hex string
  SetLength(Result, 4);
  Result[1] := '0';
  Result[2] := 'x';
  Result[3] := HEX_DIGITS[(AKey shr 4) + 1];
  Result[4] := HEX_DIGITS[(AKey and 15) + 1];
end;

function TQ3ClientKeys.IsDown(AKey: Integer): Boolean;
begin
  Result := (AKey >= 0) and (AKey <= 255) and FDown[AKey];
end;

procedure TQ3ClientKeys.SetDown(AKey: Integer; ADown: Boolean);
begin
  if (AKey >= 0) and (AKey <= 255) then
    FDown[AKey] := ADown;
end;

function TQ3ClientKeys.GetCatcher: Integer;
begin
  Result := FCatcher;
end;

procedure TQ3ClientKeys.SetCatcher(AValue: Integer);
begin
  FCatcher := AValue;
end;

function TQ3ClientKeys.GetKey(const ABinding: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    if FBound[LIndex] and SameTextAscii(ABinding, FBindings[LIndex]) then
      Exit(LIndex);
  Result := -1;
end;

function TQ3ClientKeys.GetBinding(AKey: Integer): AnsiString;
begin
  if (AKey < 0) or (AKey > 255) or not FBound[AKey] then
    Exit('');
  Result := FBindings[AKey];
end;

procedure TQ3ClientKeys.SetBinding(AKey: Integer; const ABinding: AnsiString);
begin
  if (AKey < 0) or (AKey > 255) then
    Exit;
  FBound[AKey] := True;
  FBindings[AKey] := ABinding;
  // consider this like modifying an archived cvar, so the file write will be triggered at the next opportunity
  if Assigned(FCVars) then
    FCVars.ModifiedFlags := FCVars.ModifiedFlags or 1;
end;

function TQ3ClientKeys.GetOverstrikeMode: Boolean;
begin
  Result := FOverstrike;
end;

procedure TQ3ClientKeys.SetOverstrikeMode(AValue: Boolean);
begin
  FOverstrike := AValue;
end;

procedure TQ3ClientKeys.ClearStates;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    if FDown[LIndex] and Assigned(FOnKeyReleased) then
      FOnKeyReleased(LIndex);
    FDown[LIndex] := False;
  end;
end;

end.
