{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the handles of the file system calls   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): files.c         }
{  (fsh[], FS_FOpenFileByMode, FS_Read, FS_Write, FS_Seek). Copyright (C)      }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.GameFiles;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   IQ3HostFileSystem on the file system of Framework\Wad: 63 handles (MAX_FILE_HANDLES 64, the 0 is "none",
  ///   none free is the Com_Error of FS_HandleForFile), a file opened for reading is read whole and served from
  ///   memory, a file opened for writing goes to the writer (nil writer: -1). Defects of the C kept: a seek in a
  ///   file of a pak starts again from the beginning of the file and reads the offset (as the unzip based
  ///   FS_Seek does: the origin is ignored unless the offset is 0 and the origin FS_SEEK_SET) and an offset of
  ///   65536 or more is a fatal error. Differences: the names of the files listed from a pak are in lower case
  ///   (the file system of Framework\Wad lists them so)
  /// </summary>
  TQ3GameHostFiles = class(TInterfacedObject, IQ3HostFileSystem)
  strict private
    type
      TSlot = record
        InUse: Boolean;
        Writing: Boolean;
        FromPack: Boolean;
        Data: TBytes;
        Position: Integer;
        Writer: IGameWriteFile;
      end;
    var
      FFiles: IGameFileSystem;
      FWriter: IGameFileWriter;
      FSlots: array[1..63] of TSlot;
    function Allocate: Integer;
  public
    /// <param name="AWriter">May be nil: nothing can be opened for writing</param>
    constructor Create(const AFiles: IGameFileSystem; const AWriter: IGameFileWriter);
    function Open(const AName: AnsiString; AMode: Integer; out AHandle: Integer): Integer;
    function Read(AHandle: Integer; ABuffer: PByte; ALength: Integer): Integer;
    function Write(AHandle: Integer; ABuffer: PByte; ALength: Integer): Integer;
    procedure Close(AHandle: Integer);
    function Seek(AHandle, AOffset, AOrigin: Integer): Integer;
    function ListFiles(const APath, AExtension: AnsiString): TArray<AnsiString>;
  end;

implementation

uses
  DelphiDoom.Q3Host.Types;

resourcestring
  SNoFreeHandle = 'FS_HandleForFile: none free';
  SBadMode = 'FSH_FOpenFile: bad mode';
  SBadOrigin = 'Bad origin in FS_Seek';
  SZipSeek = 'ZIP FILE FSEEK NOT YET IMPLEMENTED';
  SBadHandle = 'File handle %d is not open';

constructor TQ3GameHostFiles.Create(const AFiles: IGameFileSystem; const AWriter: IGameFileWriter);
begin
  inherited Create;
  FFiles := AFiles;
  FWriter := AWriter;
end;

function TQ3GameHostFiles.Allocate: Integer;
var
  LIndex: Integer;
begin
  for LIndex := Low(FSlots) to High(FSlots) do
    if not FSlots[LIndex].InUse then
    begin
      FSlots[LIndex] := Default(TSlot);
      FSlots[LIndex].InUse := True;
      Exit(LIndex);
    end;
  raise EQ3HostException.Create(SNoFreeHandle);
end;

function TQ3GameHostFiles.Open(const AName: AnsiString; AMode: Integer; out AHandle: Integer): Integer;
var
  LFile: IGameFile;
  LWriter: IGameWriteFile;
begin
  AHandle := 0;
  case AMode of
    0:
      begin
        LFile := FFiles.OpenFileRead(string(AName));
        if not Assigned(LFile) then
          Exit(-1);
        AHandle := Allocate;
        FSlots[AHandle].Data := LFile.ReadAll;
        FSlots[AHandle].FromPack := Assigned(LFile.Pack);
        Result := Length(FSlots[AHandle].Data);
      end;
    1, 2, 3:
      begin
        LWriter := nil;
        if Assigned(FWriter) then
        begin
          if AMode = 1 then
            LWriter := FWriter.OpenFileWrite(string(AName))
          else
            LWriter := FWriter.OpenFileAppend(string(AName), AMode = 3);
        end;
        if not Assigned(LWriter) then
          Exit(-1);
        AHandle := Allocate;
        FSlots[AHandle].Writing := True;
        FSlots[AHandle].Writer := LWriter;
        Result := 0;
      end;
  else
    raise EQ3HostException.Create(SBadMode);
  end;
end;

function TQ3GameHostFiles.Read(AHandle: Integer; ABuffer: PByte; ALength: Integer): Integer;
begin
  Result := 0;
  if AHandle = 0 then
    Exit;
  if (AHandle < Low(FSlots)) or (AHandle > High(FSlots)) or not FSlots[AHandle].InUse then
    raise EQ3HostException.CreateFmt(SBadHandle, [AHandle]);
  if FSlots[AHandle].Writing or (ALength <= 0) then
    Exit;
  Result := Length(FSlots[AHandle].Data) - FSlots[AHandle].Position;
  if Result > ALength then
    Result := ALength;
  if Result <= 0 then
    Exit(0);
  Move(FSlots[AHandle].Data[FSlots[AHandle].Position], ABuffer^, Result);
  Inc(FSlots[AHandle].Position, Result);
end;

function TQ3GameHostFiles.Write(AHandle: Integer; ABuffer: PByte; ALength: Integer): Integer;
var
  LBytes: TBytes;
begin
  Result := 0;
  if AHandle = 0 then
    Exit;
  if (AHandle < Low(FSlots)) or (AHandle > High(FSlots)) or not FSlots[AHandle].InUse then
    raise EQ3HostException.CreateFmt(SBadHandle, [AHandle]);
  if not FSlots[AHandle].Writing or (ALength <= 0) then
    Exit;
  SetLength(LBytes, ALength);
  Move(ABuffer^, LBytes[0], ALength);
  Result := FSlots[AHandle].Writer.Write(LBytes);
end;

procedure TQ3GameHostFiles.Close(AHandle: Integer);
begin
  if (AHandle < Low(FSlots)) or (AHandle > High(FSlots)) then
    Exit;
  if FSlots[AHandle].InUse and FSlots[AHandle].Writing then
    FSlots[AHandle].Writer.Flush;
  FSlots[AHandle] := Default(TSlot);
end;

function TQ3GameHostFiles.Seek(AHandle, AOffset, AOrigin: Integer): Integer;
var
  LNewPosition: Int64;
begin
  if (AHandle < Low(FSlots)) or (AHandle > High(FSlots)) or not FSlots[AHandle].InUse then
    raise EQ3HostException.CreateFmt(SBadHandle, [AHandle]);
  if FSlots[AHandle].Writing then
    Exit(-1);
  if FSlots[AHandle].FromPack then
  begin
    // unzSetCurrentFileInfoPosition and unzOpenCurrentFile, then FS_Read of the offset
    if (AOffset = 0) and (AOrigin = 2) then
    begin
      FSlots[AHandle].Position := 0;
      Exit(0);
    end;
    if (AOffset < 0) or (AOffset >= 65536) then
      raise EQ3HostException.Create(SZipSeek);
    FSlots[AHandle].Position := 0;
    Result := Length(FSlots[AHandle].Data);
    if Result > AOffset then
      Result := AOffset;
    FSlots[AHandle].Position := Result;
    Exit;
  end;
  case AOrigin of
    0: LNewPosition := Int64(FSlots[AHandle].Position) + AOffset;
    1: LNewPosition := Int64(Length(FSlots[AHandle].Data)) + AOffset;
    2: LNewPosition := AOffset;
  else
    raise EQ3HostException.Create(SBadOrigin);
  end;
  // fseek: a position before the start is refused, one past the end is allowed
  if (LNewPosition < 0) or (LNewPosition > High(Integer)) then
    Exit(-1);
  FSlots[AHandle].Position := Integer(LNewPosition);
  Result := 0;
end;

function TQ3GameHostFiles.ListFiles(const APath, AExtension: AnsiString): TArray<AnsiString>;
var
  LNames: TArray<string>;
  LIndex: Integer;
begin
  LNames := FFiles.ListFiles(string(APath), string(AExtension), True);
  SetLength(Result, Length(LNames));
  for LIndex := 0 to Length(LNames) - 1 do
    Result[LIndex] := AnsiString(LNames[LIndex]);
end;

end.
