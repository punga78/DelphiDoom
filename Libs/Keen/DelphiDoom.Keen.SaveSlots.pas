{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the saved games of the control panel              }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  Games[], USL_GiveSaveName, USL_CheckSavedGames and the file work of          }
{  USL_CtlDLButtonCustom and USL_CtlDSButtonCustom of id_us.c                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SaveSlots;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.UserIntf;

type
  /// <summary>
  ///   The files SAVEGM0.KDR ... SAVEGM6.KDR. A file starts with the header of the user manager (the signature
  ///   "KDR", a flag and the name the player gave, 39 bytes) and goes on with what the game writes
  /// </summary>
  TKeenSaveSlots = class(TInterfacedObject, IKeenSaveSlots)
  strict private
    FFiles: IKeenUserFiles;
    FSlots: array[0..KEEN_MAX_SAVE_GAMES - 1] of TKeenSaveSlot;
    procedure CheckIndex(AIndex: Integer);
  public
    constructor Create(const AFiles: IKeenUserFiles);
    /// <summary>USL_GiveSaveName: SAVEGM, the number and the extension</summary>
    class function FileName(AIndex: Integer): string; static;
    /// <summary>The 39 bytes of the header of a slot</summary>
    class function EncodeHeader(const ASlot: TKeenSaveSlot): TBytes; static;
    /// <summary>The header of a file; false if it is too short or the signature is not "KDR"</summary>
    class function TryDecodeHeader(const ABytes: TBytes; out ASlot: TKeenSaveSlot): Boolean; static;
    function GetSlot(AIndex: Integer): TKeenSaveSlot;
    procedure SetSlot(AIndex: Integer; const AValue: TKeenSaveSlot);
    procedure Check;
    function Save(AIndex: Integer; const AHooks: IKeenGameHooks): Boolean;
    function Load(AIndex: Integer; const AHooks: IKeenGameHooks; out AError: AnsiString): Boolean;
  end;

implementation

const
  SEmptyName = 'Empty';
  SErrorNoFile = 'No such file or directory';
  SErrorIncomplete = 'File is Incomplete';

{ TKeenSaveSlots }

constructor TKeenSaveSlots.Create(const AFiles: IKeenUserFiles);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
  for LIndex := 0 to KEEN_MAX_SAVE_GAMES - 1 do
    FSlots[LIndex].Name := SEmptyName;
end;

procedure TKeenSaveSlots.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= KEEN_MAX_SAVE_GAMES) then
    raise EKeenException.CreateFmt(SKeenSaveBadSlot, [AIndex, KEEN_MAX_SAVE_GAMES - 1]);
end;

class function TKeenSaveSlots.FileName(AIndex: Integer): string;
begin
  Result := 'SAVEGM' + Chr(Ord('0') + AIndex) + '.' + KEEN_EXTENSION;
end;

class function TKeenSaveSlots.EncodeHeader(const ASlot: TKeenSaveSlot): TBytes;
var
  LHeader: TKeenSaveHeader;
  LName: AnsiString;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Signature[0] := 'K';
  LHeader.Signature[1] := 'D';
  LHeader.Signature[2] := 'R';
  LHeader.Present := Ord(ASlot.Present);
  LName := Copy(ASlot.Name, 1, KEEN_MAX_GAME_NAME);
  if Length(LName) > 0 then
    Move(LName[1], LHeader.Name[0], Length(LName));
  SetLength(Result, SizeOf(LHeader));
  Move(LHeader, Result[0], SizeOf(LHeader));
end;

class function TKeenSaveSlots.TryDecodeHeader(const ABytes: TBytes; out ASlot: TKeenSaveSlot): Boolean;
var
  LHeader: TKeenSaveHeader;
  LLength: Integer;
begin
  ASlot.Present := False;
  ASlot.Name := '';
  if Length(ABytes) < SizeOf(LHeader) then
    Exit(False);
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  // strcmp(signature, "KDR"): the three letters and the 0 after them
  if (LHeader.Signature[0] <> 'K') or (LHeader.Signature[1] <> 'D') or (LHeader.Signature[2] <> 'R') or
    (LHeader.Signature[3] <> #0) then
    Exit(False);
  LLength := 0;
  while (LLength < KEEN_MAX_GAME_NAME) and (LHeader.Name[LLength] <> #0) do
    Inc(LLength);
  SetString(ASlot.Name, PAnsiChar(@LHeader.Name[0]), LLength);
  ASlot.Present := True;
  Result := True;
end;

function TKeenSaveSlots.GetSlot(AIndex: Integer): TKeenSaveSlot;
begin
  CheckIndex(AIndex);
  Result := FSlots[AIndex];
end;

procedure TKeenSaveSlots.SetSlot(AIndex: Integer; const AValue: TKeenSaveSlot);
begin
  CheckIndex(AIndex);
  FSlots[AIndex] := AValue;
end;

procedure TKeenSaveSlots.Check;
var
  LIndex: Integer;
  LBytes: TBytes;
  LSlot: TKeenSaveSlot;
begin
  for LIndex := 0 to KEEN_MAX_SAVE_GAMES - 1 do
    if FFiles.TryRead(FileName(LIndex), LBytes) and TryDecodeHeader(LBytes, LSlot) then
      FSlots[LIndex] := LSlot
    else
    begin
      FSlots[LIndex].Present := False;
      FSlots[LIndex].Name := SEmptyName;
    end;
end;

function TKeenSaveSlots.Save(AIndex: Integer; const AHooks: IKeenGameHooks): Boolean;
var
  LStream: TBytesStream;
  LHeader: TBytes;
  LBytes: TBytes;
begin
  CheckIndex(AIndex);
  LStream := TBytesStream.Create;
  try
    LHeader := EncodeHeader(FSlots[AIndex]);
    LStream.WriteBuffer(LHeader[0], Length(LHeader));
    Result := True;
    if Assigned(AHooks) then
      Result := AHooks.SaveGame(LStream);
    if Result then
    begin
      LBytes := Copy(LStream.Bytes, 0, LStream.Size);
      Result := FFiles.TryWrite(FileName(AIndex), LBytes);
    end;
    // the C removes the file when something went wrong
    if not Result then
      FFiles.Delete(FileName(AIndex));
  finally
    LStream.Free;
  end;
end;

function TKeenSaveSlots.Load(AIndex: Integer; const AHooks: IKeenGameHooks; out AError: AnsiString): Boolean;
var
  LBytes: TBytes;
  LSlot: TKeenSaveSlot;
  LStream: TBytesStream;
begin
  CheckIndex(AIndex);
  AError := '';
  if not FFiles.TryRead(FileName(AIndex), LBytes) then
  begin
    AError := SErrorNoFile;
    Exit(False);
  end;
  // the C only asks that the header can be read: a file with another signature is caught by the check of the
  // saved games before the panel offers it
  if not TryDecodeHeader(LBytes, LSlot) then
  begin
    AError := SErrorIncomplete;
    Exit(False);
  end;
  FSlots[AIndex].Name := LSlot.Name;
  Result := True;
  if Assigned(AHooks) then
  begin
    LStream := TBytesStream.Create(LBytes);
    try
      LStream.Position := SizeOf(TKeenSaveHeader);
      Result := AHooks.LoadGame(LStream);
    finally
      LStream.Free;
    end;
    if not Result then
      AError := SErrorIncomplete;
  end;
end;

end.
