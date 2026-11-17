{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the CD key of the menus                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_ui.c          }
{  (CLUI_GetCDKey, CLUI_SetCDKey) and cl_main.c (CL_CDKeyValidate).             }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the      }
{  Quake III Arena source code and is therefore available under the GNU         }
{  General Public License, version 2 or (at your option) any later version.     }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientCdKey;

// The sum of the key is a byte that wraps, as in the C.

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   cl_cdkey[34]: the key of the game and, when the module says it uses a unique key and fs_game is set, the one
  ///   of the mod after it. The key is never checked against a server here
  /// </summary>
  TQ3ClientCdKey = class
  strict private
    FKey: array[0..33] of Byte;
  public
    const
      CDKEY_LEN = 16;
      CDCHKSUM_LEN = 2;
    /// <summary>CL_InitCDKey without a q3key file: sixteen blanks</summary>
    constructor Create;
    /// <summary>
    ///   CLUI_GetCDKey: the 17 bytes the C copies (sixteen characters and a zero) from the first or the second key
    /// </summary>
    function Get(AUniqueKey: Boolean): TBytes;
    /// <summary>CLUI_SetCDKey: sixteen bytes into the first or the second key; True: the archive flag must be set</summary>
    function Put(AUniqueKey: Boolean; const AKey: TBytes): Boolean;
    /// <summary>CL_CDKeyValidate: AHasChecksum false is the NULL checksum, which accepts any valid key</summary>
    class function Validate(const AKey: AnsiString; AHasChecksum: Boolean; const AChecksum: AnsiString): Boolean; static;
  end;

implementation

constructor TQ3ClientCdKey.Create;
begin
  inherited Create;
  FillChar(FKey, SizeOf(FKey), 0);
  FillChar(FKey, CDKEY_LEN, Ord(' '));
end;

function TQ3ClientCdKey.Get(AUniqueKey: Boolean): TBytes;
var
  LStart: Integer;
begin
  SetLength(Result, CDKEY_LEN + 1);
  if AUniqueKey then
    LStart := 16
  else
    LStart := 0;
  Move(FKey[LStart], Result[0], CDKEY_LEN);
  Result[CDKEY_LEN] := 0;
end;

function TQ3ClientCdKey.Put(AUniqueKey: Boolean; const AKey: TBytes): Boolean;
begin
  Result := Length(AKey) >= CDKEY_LEN;
  if not Result then
    Exit;
  if AUniqueKey then
  begin
    Move(AKey[0], FKey[16], CDKEY_LEN);
    FKey[32] := 0;
  end
  else
    Move(AKey[0], FKey[0], CDKEY_LEN);
end;

class function TQ3ClientCdKey.Validate(const AKey: AnsiString; AHasChecksum: Boolean;
  const AChecksum: AnsiString): Boolean;
var
  LIndex: Integer;
  LChar: AnsiChar;
  LSum: Byte;
  LText: AnsiString;
begin
  if Length(AKey) <> CDKEY_LEN then
    Exit(False);
  if AHasChecksum and (Length(AChecksum) <> CDCHKSUM_LEN) then
    Exit(False);

  LSum := 0;
  for LIndex := 1 to Length(AKey) do
  begin
    LChar := AKey[LIndex];
    if LChar in ['a'..'z'] then
      LChar := AnsiChar(Ord(LChar) - 32);
    if LChar in ['2', '3', '7', 'A', 'B', 'C', 'D', 'G', 'H', 'J', 'L', 'P', 'R', 'S', 'T', 'W'] then
      LSum := LSum + Ord(LChar)
    else
      Exit(False);
  end;

  if not AHasChecksum then
    Exit(True);
  LText := AnsiString(LowerCase(Format('%.2x', [LSum])));
  Result := LText = AnsiString(LowerCase(string(AChecksum)));
end;

end.
