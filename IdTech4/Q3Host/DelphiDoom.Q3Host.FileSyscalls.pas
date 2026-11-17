{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the file system calls                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  cl_cgame.c, cl_ui.c, files.c. Copyright (C) 1999-2005 Id Software, Inc.     }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.FileSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   FS_FOpenFileByMode, FS_Read2, FS_Write, FS_FCloseFile, FS_Seek and FS_GetFileList for the modules that have
  ///   them (qagame and ui the list of files, cgame not). The files are IQ3HostFileSystem; the list is packed in
  ///   the buffer of the program as FS_GetFileList does (names with their zero, the count that fits)
  /// </summary>
  TQ3FileSyscalls = class
  public
    /// <remarks>
    ///   "$modlist" (FS_GetModList) answers no mod: the mods are folders of the game directory and the engine
    ///   decides which ones to show
    /// </remarks>
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const AFiles: IQ3HostFileSystem); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

const
  NONE = -1;
  FS_READ = 0;

type
  TFileNumbers = record
    Open, Read, Write, Close, Seek, List: Integer;
  end;

const
  FILE_NUMBERS: array[TQ3Module] of TFileNumbers = (
    (Open: G_FS_FOPEN_FILE; Read: G_FS_READ; Write: G_FS_WRITE; Close: G_FS_FCLOSE_FILE; Seek: G_FS_SEEK;
     List: G_FS_GETFILELIST),
    (Open: CG_FS_FOPENFILE; Read: CG_FS_READ; Write: CG_FS_WRITE; Close: CG_FS_FCLOSEFILE; Seek: CG_FS_SEEK;
     List: NONE),
    (Open: UI_FS_FOPENFILE; Read: UI_FS_READ; Write: UI_FS_WRITE; Close: UI_FS_FCLOSEFILE; Seek: UI_FS_SEEK;
     List: UI_FS_GETFILELIST));
  CALL_NAMES: array[TQ3Module] of string = ('qagame', 'cgame', 'ui');

class procedure TQ3FileSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const AFiles: IQ3HostFileSystem);
var
  LNumbers: TFileNumbers;
  LName: string;
begin
  LNumbers := FILE_NUMBERS[AModule];
  LName := CALL_NAMES[AModule];

  ARegistry.Register(LNumbers.Open,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LHandle: Integer;
    begin
      Result := AFiles.Open(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName), AArgs[3], LHandle);
      if AArgs[2] <> 0 then
        AMachine.Memory.WriteInt32(AArgs[2], LHandle)
      else
      begin
        // FS_FOpenFileRead( name, NULL ) only asks if the file is there
        if LHandle <> 0 then
          AFiles.Close(LHandle);
        if AArgs[3] = FS_READ then
          Result := Ord(Result >= 0);
      end;
    end);

  ARegistry.Register(LNumbers.Read,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if (AArgs[3] <> 0) and (AArgs[2] > 0) then
        AFiles.Read(AArgs[3], TQ3SyscallArguments.Buffer(AMachine, AArgs[1], AArgs[2]), AArgs[2]);
      Result := 0;
    end);

  ARegistry.Register(LNumbers.Write,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      if (AArgs[3] <> 0) and (AArgs[2] > 0) then
        AFiles.Write(AArgs[3], TQ3SyscallArguments.Buffer(AMachine, AArgs[1], AArgs[2]), AArgs[2]);
      Result := 0;
    end);

  ARegistry.Register(LNumbers.Close,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      AFiles.Close(AArgs[1]);
      Result := 0;
    end);

  ARegistry.Register(LNumbers.Seek,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := AFiles.Seek(AArgs[1], AArgs[2], AArgs[3]);
    end);

  if LNumbers.List <> NONE then
    ARegistry.Register(LNumbers.List,
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LNames: TArray<AnsiString>;
        LIndex, LTotal, LLength, LPosition: Integer;
        LBytes: TBytes;
      begin
        // FS_GetFileList: *listbuf = 0 first
        AMachine.Memory.WriteByte(AArgs[3], 0);
        if SameText(string(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName)), '$modlist') then
          Exit(0);
        LNames := AFiles.ListFiles(TQ3SyscallArguments.Text(AMachine, AArgs[1], LName),
          TQ3SyscallArguments.Text(AMachine, AArgs[2], LName));
        Result := Length(LNames);
        LTotal := 0;
        LPosition := AArgs[3];
        for LIndex := 0 to Length(LNames) - 1 do
        begin
          LLength := Length(LNames[LIndex]) + 1;
          if LTotal + LLength + 1 < AArgs[4] then
          begin
            SetLength(LBytes, LLength);
            Move(LNames[LIndex][1], LBytes[0], LLength - 1);
            LBytes[LLength - 1] := 0;
            AMachine.Memory.WriteBytes(LPosition, LBytes);
            Inc(LPosition, LLength);
            Inc(LTotal, LLength);
          end
          else
          begin
            Result := LIndex;
            Break;
          end;
        end;
      end);
end;

end.
