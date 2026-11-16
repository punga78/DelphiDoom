{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - which format a file of a saved game has           }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SaveFormat;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

type
  /// <summary>The formats of SAVEGMn.KDR that this port knows</summary>
  TKeenSaveVersion = (
    /// <summary>Not a saved game of Keen Dreams, or one that is cut</summary>
    ksvUnknown,
    /// <summary>The format of this port: the header of 40 bytes with the version in the high byte of "present"</summary>
    ksvCurrent,
    /// <summary>The first format of Keen32: the header of 39 bytes (no byte of padding) and no version</summary>
    ksvShortHeader,
    /// <summary>A file of the DOS program: the actors have addresses, not state numbers (TKeenDosSaveConverter)</summary>
    ksvDos);

  /// <summary>
  ///   The version of the format is the high byte of the word that the C calls "present" (its value is ignored when
  ///   the DOS program reads a saved game: USL_CheckSavedGames puts it right): 0 or 1 is a file of the DOS program or
  ///   of the first format of this port, the version of this format is KEEN_SAVE_FORMAT_VERSION. A file with no
  ///   version is told apart by its shape: the planes must follow each other, the actors must be a whole number of
  ///   records ending in one with no next, and their states are numbers up to 213 (this port) or addresses (DOS)
  /// </summary>
  TKeenSaveFormat = class
  public
    class function Detect(const ABytes: TBytes): TKeenSaveVersion; static;
    /// <summary>How long the header is in a format: 40 bytes, 39 for the first format of this port</summary>
    class function HeaderSize(AVersion: TKeenSaveVersion): Integer; static;
  end;

implementation

uses
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.StateTable;

const
  GAMESTATE_SIZE = 60;

{ TKeenSaveFormat }

class function TKeenSaveFormat.HeaderSize(AVersion: TKeenSaveVersion): Integer;
begin
  if AVersion = ksvShortHeader then
    Result := 39
  else
    Result := 40;
end;

class function TKeenSaveFormat.Detect(const ABytes: TBytes): TKeenSaveVersion;
type
  TShape = (shNone, shSmallStates, shLargeStates);

  function ReadWord(APosition: Integer): Integer;
  begin
    Result := ABytes[APosition] or (ABytes[APosition + 1] shl 8);
  end;

  // the planes follow each other and the actors are a whole number of records that end with one with no next
  function ShapeAt(AHeader: Integer): TShape;
  var
    LPosition: Integer;
    LPlane: Integer;
    LCount: Integer;
    LActor: Integer;
    LLarge: Boolean;
    LState: Integer;
  begin
    Result := shNone;
    LPosition := AHeader + GAMESTATE_SIZE;
    for LPlane := 0 to 2 do
    begin
      if LPosition + 2 > Length(ABytes) then
        Exit;
      Inc(LPosition, 2 + ReadWord(LPosition));
      if LPosition > Length(ABytes) then
        Exit;
    end;
    if ((Length(ABytes) - LPosition) mod SizeOf(TKeenSaveObject) <> 0) or
      (Length(ABytes) - LPosition < 2 * SizeOf(TKeenSaveObject)) then
      Exit;
    LCount := (Length(ABytes) - LPosition) div SizeOf(TKeenSaveObject);
    if ReadWord(LPosition + (LCount - 1) * SizeOf(TKeenSaveObject) + 72) <> 0 then
      Exit;
    LLarge := False;
    for LActor := 0 to LCount - 1 do
    begin
      LState := ReadWord(LPosition + LActor * SizeOf(TKeenSaveObject) + 30);
      if LState > KEEN_STATE_COUNT then
        LLarge := True;
    end;
    if LLarge then
      Result := shLargeStates
    else
      Result := shSmallStates;
  end;

begin
  Result := ksvUnknown;
  if (Length(ABytes) < 39 + GAMESTATE_SIZE) or (ABytes[0] <> Ord('K')) or (ABytes[1] <> Ord('D')) or
    (ABytes[2] <> Ord('R')) or (ABytes[3] <> 0) then
    Exit;
  if (Length(ABytes) >= 40 + GAMESTATE_SIZE) and (ABytes[5] = KEEN_SAVE_FORMAT_VERSION) then
    Exit(ksvCurrent);
  // a file with no version: its shape says which one it is
  if (Length(ABytes) >= 40 + GAMESTATE_SIZE) and (ShapeAt(40) = shLargeStates) then
    Exit(ksvDos);
  if ShapeAt(39) = shSmallStates then
    Exit(ksvShortHeader);
end;

end.
