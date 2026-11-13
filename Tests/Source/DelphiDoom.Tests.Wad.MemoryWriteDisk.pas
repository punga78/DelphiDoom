{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - a disk in memory that can also be    }
{  written, and the fakes of paks and of the file system used by the tests     }
{  of the pure server                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.MemoryWriteDisk;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf,
  DelphiDoom.Tests.Wad.MemoryDisk;

type
  /// <summary>A stream that gives its bytes to the disk when it is freed (the file is closed)</summary>
  TMemoryWriteStream = class(TBytesStream)
  strict private
    FDisk: TMemoryGameDisk;
    FPath: string;
  public
    constructor Create(ADisk: TMemoryGameDisk; const APath: string; const AInitial: TBytes);
    destructor Destroy; override;
  end;

  /// <summary>The memory disk with the writing side: folders are only remembered, files are committed on close</summary>
  TMemoryWriteDisk = class(TMemoryGameDisk, IGameDiskWriter)
  strict private
    FDirectories: TStringList;
    FRefuse: Boolean;
    FRemoved: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateDirectory(const ADirectory: string): Boolean;
    function OpenWrite(const AFileName: string; AAppend: Boolean): TStream;
    function RemoveFile(const AFileName: string): Boolean;
    /// <summary>The text of a file ('<missing>' if it is not there)</summary>
    function ReadText(const APath: string): string;
    /// <summary>The folders that were created, in order</summary>
    property Directories: TStringList read FDirectories;
    /// <summary>The files RemoveFile was called for, with the result</summary>
    property Removed: TStringList read FRemoved;
    /// <summary>OpenWrite gives nil (a disk that cannot be written)</summary>
    property Refuse: Boolean read FRefuse write FRefuse;
  end;

  /// <summary>A pak with the values given by the test</summary>
  TFakeGamePack = class(TInterfacedObject, IGamePack)
  strict private
    FFileName: string;
    FChecksum: Cardinal;
    FNames: TArray<string>;
    FIsAddon: Boolean;
    FReferenced: Boolean;
  public
    constructor Create(const AFileName: string; AChecksum: Cardinal; const ANames: TArray<string>;
      AIsAddon: Boolean = False; AReferenced: Boolean = False);
    function GetFileName: string;
    function GetEntryCount: Integer;
    function GetChecksum: Cardinal;
    function GetLength: Int64;
    function GetIsAddon: Boolean;
    function GetReferenced: Boolean;
    procedure SetReferenced(AValue: Boolean);
    function GetHasAddonInfo: Boolean;
    function GetAddonInfo: TGameAddonInfo;
    function EntryName(AIndex: Integer): string;
    function FindEntry(const ARelativePath: string): Integer;
    function EntrySize(AIndex: Integer): Int64;
    function ReadEntry(AIndex: Integer): TBytes;
  end;

  /// <summary>A file system that is only a list of packs and a game folder</summary>
  TFakeFileSystemState = class(TInterfacedObject, IGameFileSystemInspector)
  strict private
    FInitialized: Boolean;
    FGameFolder: string;
    FPacks: TArray<IGamePack>;
    FAddons: TArray<IGamePack>;
  public
    constructor Create(const APacks, AAddons: TArray<IGamePack>; const AGameFolder: string = 'base';
      AInitialized: Boolean = True);
    function IsInitialized: Boolean;
    function GameFolder: string;
    function Packs: TArray<IGamePack>;
    function AddonPacks: TArray<IGamePack>;
  end;

implementation

{ TMemoryWriteStream }

constructor TMemoryWriteStream.Create(ADisk: TMemoryGameDisk; const APath: string; const AInitial: TBytes);
begin
  inherited Create(AInitial);
  FDisk := ADisk;
  FPath := APath;
end;

destructor TMemoryWriteStream.Destroy;
begin
  FDisk.AddFile(FPath, Copy(Bytes, 0, Size));
  inherited Destroy;
end;

{ TMemoryWriteDisk }

constructor TMemoryWriteDisk.Create;
begin
  inherited Create;
  FDirectories := TStringList.Create;
  FRemoved := TStringList.Create;
end;

destructor TMemoryWriteDisk.Destroy;
begin
  FRemoved.Free;
  FDirectories.Free;
  inherited Destroy;
end;

function TMemoryWriteDisk.CreateDirectory(const ADirectory: string): Boolean;
begin
  if FDirectories.IndexOf(ADirectory) < 0 then
    FDirectories.Add(ADirectory);
  Result := True;
end;

function TMemoryWriteDisk.OpenWrite(const AFileName: string; AAppend: Boolean): TStream;
var
  LExisting: TStream;
  LInitial: TBytes;
begin
  if FRefuse then
    Exit(nil);
  LInitial := nil;
  if AAppend then
  begin
    LExisting := OpenRead(AFileName);
    if Assigned(LExisting) then
      try
        SetLength(LInitial, LExisting.Size);
        if LExisting.Size > 0 then
          LExisting.ReadBuffer(LInitial[0], LExisting.Size);
      finally
        LExisting.Free;
      end;
  end;
  Result := TMemoryWriteStream.Create(Self, AFileName, LInitial);
  if AAppend then
    Result.Seek(0, soEnd);
  // the file is there as soon as it is opened, as on a real disk
  AddFile(AFileName, LInitial);
end;

function TMemoryWriteDisk.RemoveFile(const AFileName: string): Boolean;
begin
  Result := Remove(AFileName);
  FRemoved.Add(AFileName + '=' + BoolToStr(Result, True));
end;

function TMemoryWriteDisk.ReadText(const APath: string): string;
var
  LStream: TStream;
  LBytes: TBytes;
begin
  LStream := OpenRead(APath);
  if not Assigned(LStream) then
    Exit('<missing>');
  try
    SetLength(LBytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(LBytes[0], LStream.Size);
    Result := TEncoding.UTF8.GetString(LBytes);
  finally
    LStream.Free;
  end;
end;

{ TFakeGamePack }

constructor TFakeGamePack.Create(const AFileName: string; AChecksum: Cardinal; const ANames: TArray<string>;
  AIsAddon, AReferenced: Boolean);
begin
  inherited Create;
  FFileName := AFileName;
  FChecksum := AChecksum;
  FNames := ANames;
  FIsAddon := AIsAddon;
  FReferenced := AReferenced;
end;

function TFakeGamePack.GetFileName: string;
begin
  Result := FFileName;
end;

function TFakeGamePack.GetEntryCount: Integer;
begin
  Result := Length(FNames);
end;

function TFakeGamePack.GetChecksum: Cardinal;
begin
  Result := FChecksum;
end;

function TFakeGamePack.GetLength: Int64;
begin
  Result := 0;
end;

function TFakeGamePack.GetIsAddon: Boolean;
begin
  Result := FIsAddon;
end;

function TFakeGamePack.GetReferenced: Boolean;
begin
  Result := FReferenced;
end;

procedure TFakeGamePack.SetReferenced(AValue: Boolean);
begin
  FReferenced := AValue;
end;

function TFakeGamePack.GetHasAddonInfo: Boolean;
begin
  Result := False;
end;

function TFakeGamePack.GetAddonInfo: TGameAddonInfo;
begin
  Result := Default(TGameAddonInfo);
end;

function TFakeGamePack.EntryName(AIndex: Integer): string;
begin
  Result := FNames[AIndex];
end;

function TFakeGamePack.FindEntry(const ARelativePath: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FNames) do
    if SameText(FNames[LIndex], ARelativePath) then
      Exit(LIndex);
  Result := -1;
end;

function TFakeGamePack.EntrySize(AIndex: Integer): Int64;
begin
  Result := 0;
end;

function TFakeGamePack.ReadEntry(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

{ TFakeFileSystemState }

constructor TFakeFileSystemState.Create(const APacks, AAddons: TArray<IGamePack>; const AGameFolder: string;
  AInitialized: Boolean);
begin
  inherited Create;
  FPacks := APacks;
  FAddons := AAddons;
  FGameFolder := AGameFolder;
  FInitialized := AInitialized;
end;

function TFakeFileSystemState.IsInitialized: Boolean;
begin
  Result := FInitialized;
end;

function TFakeFileSystemState.GameFolder: string;
begin
  Result := FGameFolder;
end;

function TFakeFileSystemState.Packs: TArray<IGamePack>;
begin
  Result := FPacks;
end;

function TFakeFileSystemState.AddonPacks: TArray<IGamePack>;
begin
  Result := FAddons;
end;

end.
