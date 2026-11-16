{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the configuration file                            }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  USL_ReadConfig and USL_WriteConfig of id_us.c (KDREAMS.CFG)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ConfigStore;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.UserIntf;

const
  /// <summary>The score of the ten lines of a table that was never saved</summary>
  KEEN_DEFAULT_HIGH_SCORE = 10000;
  // SDMode of id_sd.h, as the file has it
  KEEN_SDM_OFF = 0;
  KEEN_SDM_PC = 1;
  KEEN_SDM_ADLIB = 2;
  KEEN_SDM_SOUNDBLASTER = 3;
  KEEN_SDM_SOUNDSOURCE = 4;

type
  /// <summary>What KDREAMS.CFG keeps</summary>
  TKeenConfig = record
    /// <summary>The file was there (gotit of USL_ReadConfig): its modes are asked for, otherwise the defaults</summary>
    Found: Boolean;
    Scores: array[0..KEEN_MAX_SCORES - 1] of TKeenHighScore;
    /// <summary>SDMode as a number: 3 and 4 are the digitized sounds, that this port does not have</summary>
    SoundMode: Word;
    MusicMode: Word;
    Control: TKeenControlType;
    Keyboard: TKeenKeyboardDef;
  end;

  /// <summary>
  ///   Reads and writes the configuration in the format of the original (656 bytes: ten scores of 64 bytes, three
  ///   16 bit numbers and the ten scan codes of the keyboard of the first player), so the file of the original
  ///   game can be used and the other way round
  /// </summary>
  TKeenConfigStore = class
  strict private
    FFiles: IKeenUserFiles;
  public
    constructor Create(const AFiles: IKeenUserFiles);
    /// <summary>The configuration of a game that never saved one: ten scores of 10000 with no name, no sound, the keyboard</summary>
    class function Defaults(const AKeyboard: TKeenKeyboardDef): TKeenConfig; static;
    /// <summary>The bytes of the file</summary>
    class function Encode(const AConfig: TKeenConfig): TBytes; static;
    /// <summary>A file shorter than the record is an EKeenDataException</summary>
    class function Decode(const ABytes: TBytes): TKeenConfig; static;
    /// <summary>The sound mode of the file as the mode of the manager; false for a device that this port does not have</summary>
    class function TrySoundMode(AValue: Word; out AMode: TKeenSoundMode): Boolean; static;
    /// <summary>
    ///   USL_ReadConfig: the file, or the defaults (with AKeyboard) if it is not there. A file that is too short
    ///   counts as not there (the C reads what there is over the defaults)
    /// </summary>
    function Read(const AKeyboard: TKeenKeyboardDef): TKeenConfig;
    /// <summary>USL_WriteConfig; false if the file cannot be written</summary>
    function Write(const AConfig: TKeenConfig): Boolean;
  end;

implementation

{ TKeenConfigStore }

constructor TKeenConfigStore.Create(const AFiles: IKeenUserFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

class function TKeenConfigStore.Defaults(const AKeyboard: TKeenKeyboardDef): TKeenConfig;
var
  LIndex: Integer;
begin
  Result.Found := False;
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
  begin
    Result.Scores[LIndex].Name := '';
    Result.Scores[LIndex].Score := KEEN_DEFAULT_HIGH_SCORE;
    Result.Scores[LIndex].Completed := 0;
  end;
  Result.SoundMode := KEEN_SDM_OFF;
  Result.MusicMode := 0;
  Result.Control := kctKeyboard1;
  Result.Keyboard := AKeyboard;
end;

class function TKeenConfigStore.TrySoundMode(AValue: Word; out AMode: TKeenSoundMode): Boolean;
begin
  Result := True;
  case AValue of
    KEEN_SDM_OFF:
      AMode := ksmOff;
    KEEN_SDM_PC:
      AMode := ksmPC;
    KEEN_SDM_ADLIB:
      AMode := ksmAdLib;
  else
    AMode := ksmOff;
    Result := False;
  end;
end;

class function TKeenConfigStore.Encode(const AConfig: TKeenConfig): TBytes;
var
  LRecord: TKeenConfigRecord;
  LIndex: Integer;
  LName: AnsiString;
begin
  FillChar(LRecord, SizeOf(LRecord), 0);
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
  begin
    LName := Copy(AConfig.Scores[LIndex].Name, 1, KEEN_MAX_HIGH_NAME);
    if Length(LName) > 0 then
      Move(LName[1], LRecord.Scores[LIndex].Name[0], Length(LName));
    LRecord.Scores[LIndex].Score := AConfig.Scores[LIndex].Score;
    LRecord.Scores[LIndex].Completed := AConfig.Scores[LIndex].Completed;
  end;
  LRecord.SoundMode := AConfig.SoundMode;
  LRecord.MusicMode := AConfig.MusicMode;
  LRecord.Control := Ord(AConfig.Control);
  LRecord.Keyboard.Button0 := AConfig.Keyboard.Button0;
  LRecord.Keyboard.Button1 := AConfig.Keyboard.Button1;
  LRecord.Keyboard.UpLeft := AConfig.Keyboard.UpLeft;
  LRecord.Keyboard.Up := AConfig.Keyboard.Up;
  LRecord.Keyboard.UpRight := AConfig.Keyboard.UpRight;
  LRecord.Keyboard.Left := AConfig.Keyboard.Left;
  LRecord.Keyboard.Right := AConfig.Keyboard.Right;
  LRecord.Keyboard.DownLeft := AConfig.Keyboard.DownLeft;
  LRecord.Keyboard.Down := AConfig.Keyboard.Down;
  LRecord.Keyboard.DownRight := AConfig.Keyboard.DownRight;
  SetLength(Result, SizeOf(LRecord));
  Move(LRecord, Result[0], SizeOf(LRecord));
end;

class function TKeenConfigStore.Decode(const ABytes: TBytes): TKeenConfig;
var
  LRecord: TKeenConfigRecord;
  LIndex: Integer;
  LLength: Integer;
begin
  if Length(ABytes) < SizeOf(LRecord) then
    raise EKeenDataException.CreateFmt(SKeenConfigTooShort, [Length(ABytes), SizeOf(LRecord)]);
  Move(ABytes[0], LRecord, SizeOf(LRecord));
  Result.Found := True;
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
  begin
    // a C string: up to the first 0, and never more than the field
    LLength := 0;
    while (LLength <= KEEN_MAX_HIGH_NAME) and (LRecord.Scores[LIndex].Name[LLength] <> #0) do
      Inc(LLength);
    if LLength > KEEN_MAX_HIGH_NAME then
      LLength := KEEN_MAX_HIGH_NAME;
    SetString(Result.Scores[LIndex].Name, PAnsiChar(@LRecord.Scores[LIndex].Name[0]), LLength);
    Result.Scores[LIndex].Score := LRecord.Scores[LIndex].Score;
    Result.Scores[LIndex].Completed := LRecord.Scores[LIndex].Completed;
  end;
  Result.SoundMode := LRecord.SoundMode;
  Result.MusicMode := LRecord.MusicMode;
  // a control that the enumeration does not have is the keyboard (IN_Default checks the device anyway)
  if Integer(LRecord.Control) <= Ord(High(TKeenControlType)) then
    Result.Control := TKeenControlType(LRecord.Control)
  else
    Result.Control := kctKeyboard1;
  Result.Keyboard.Button0 := LRecord.Keyboard.Button0;
  Result.Keyboard.Button1 := LRecord.Keyboard.Button1;
  Result.Keyboard.UpLeft := LRecord.Keyboard.UpLeft;
  Result.Keyboard.Up := LRecord.Keyboard.Up;
  Result.Keyboard.UpRight := LRecord.Keyboard.UpRight;
  Result.Keyboard.Left := LRecord.Keyboard.Left;
  Result.Keyboard.Right := LRecord.Keyboard.Right;
  Result.Keyboard.DownLeft := LRecord.Keyboard.DownLeft;
  Result.Keyboard.Down := LRecord.Keyboard.Down;
  Result.Keyboard.DownRight := LRecord.Keyboard.DownRight;
end;

function TKeenConfigStore.Read(const AKeyboard: TKeenKeyboardDef): TKeenConfig;
var
  LBytes: TBytes;
begin
  if FFiles.TryRead(KEEN_CONFIG_NAME, LBytes) and (Length(LBytes) >= SizeOf(TKeenConfigRecord)) then
    Result := Decode(LBytes)
  else
    Result := Defaults(AKeyboard);
end;

function TKeenConfigStore.Write(const AConfig: TKeenConfig): Boolean;
begin
  Result := FFiles.TryWrite(KEEN_CONFIG_NAME, Encode(AConfig));
end;

end.
