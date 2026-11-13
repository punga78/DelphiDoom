{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - a disk in memory for the file        }
{  system of id Tech 4, and ZIP files built in memory                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.MemoryDisk;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   An IGameDisk with files in memory. Names are compared without case and with '\' as '/', as the
  ///   disk of Windows does; the names listed keep the case they were added with
  /// </summary>
  TMemoryGameDisk = class(TInterfacedObject, IGameDisk)
  strict private
    type
      TMemoryFile = record
        Path: string;
        Data: TBytes;
        Timestamp: Int64;
      end;
  strict private
    FFiles: TDictionary<string, TMemoryFile>;
    class function Key(const APath: string): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds (or replaces) a file</summary>
    procedure AddFile(const APath: string; const AData: TBytes; ATimestamp: Int64 = 0);
    procedure AddText(const APath, AText: string);
    /// <summary>True when the file is there</summary>
    function Exists(const APath: string): Boolean;
    /// <summary>Removes a file; False when it was not there</summary>
    function Remove(const APath: string): Boolean;
    function ListFiles(const ADirectory, AExtension: string): TArray<string>;
    function OpenRead(const AFileName: string): TStream;
    function FileTimestamp(const AFileName: string): Int64;
    /// <summary>How many times OpenRead was called (to see that the paks are opened once)</summary>
    function OpenCount: Integer;
  strict private
    FOpenCount: Integer;
  end;

  TMemoryZip = class
  public
    /// <summary>
    ///   A ZIP: a name that ends with '/' is a folder entry (empty), the others are files. Names and data
    ///   in the same order; the same name may be given twice
    /// </summary>
    class function Make(const ANames: array of string; const AData: array of string): TBytes; static;
    class function Bytes(const AText: string): TBytes; static;
  end;

implementation

uses
  System.Zip;

{ TMemoryGameDisk }

constructor TMemoryGameDisk.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TMemoryFile>.Create;
end;

destructor TMemoryGameDisk.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

class function TMemoryGameDisk.Key(const APath: string): string;
begin
  Result := LowerCase(StringReplace(APath, '\', '/', [rfReplaceAll]));
  while (Result <> '') and (Result[Length(Result)] = '/') do
    SetLength(Result, Length(Result) - 1);
end;

procedure TMemoryGameDisk.AddFile(const APath: string; const AData: TBytes; ATimestamp: Int64);
var
  LFile: TMemoryFile;
begin
  LFile.Path := StringReplace(APath, '\', '/', [rfReplaceAll]);
  LFile.Data := AData;
  LFile.Timestamp := ATimestamp;
  FFiles.AddOrSetValue(Key(APath), LFile);
end;

procedure TMemoryGameDisk.AddText(const APath, AText: string);
begin
  AddFile(APath, TMemoryZip.Bytes(AText));
end;

function TMemoryGameDisk.Exists(const APath: string): Boolean;
begin
  Result := FFiles.ContainsKey(Key(APath));
end;

function TMemoryGameDisk.Remove(const APath: string): Boolean;
begin
  Result := FFiles.ContainsKey(Key(APath));
  if Result then
    FFiles.Remove(Key(APath));
end;

function TMemoryGameDisk.ListFiles(const ADirectory, AExtension: string): TArray<string>;
var
  LDirectory, LRest, LName: string;
  LFile: TMemoryFile;
  LSlash: Integer;
  LList: TList<string>;
begin
  LDirectory := Key(ADirectory) + '/';
  LList := TList<string>.Create;
  try
    for LFile in FFiles.Values do
    begin
      if not LowerCase(LFile.Path).StartsWith(LDirectory) then
        Continue;
      LRest := Copy(LFile.Path, Length(LDirectory) + 1, MaxInt);
      LSlash := Pos('/', LRest);
      if AExtension = '/' then
      begin
        if LSlash > 0 then
        begin
          LName := Copy(LRest, 1, LSlash - 1);
          if not LList.Contains(LName) then
            LList.Add(LName);
        end;
      end
      else if (LSlash = 0) and LRest.EndsWith(AExtension, True) then
        LList.Add(LRest);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TMemoryGameDisk.OpenRead(const AFileName: string): TStream;
var
  LFile: TMemoryFile;
begin
  Inc(FOpenCount);
  if FFiles.TryGetValue(Key(AFileName), LFile) then
    Result := TBytesStream.Create(LFile.Data)
  else
    Result := nil;
end;

function TMemoryGameDisk.FileTimestamp(const AFileName: string): Int64;
var
  LFile: TMemoryFile;
begin
  if FFiles.TryGetValue(Key(AFileName), LFile) then
    Result := LFile.Timestamp
  else
    Result := 0;
end;

function TMemoryGameDisk.OpenCount: Integer;
begin
  Result := FOpenCount;
end;

{ TMemoryZip }

class function TMemoryZip.Bytes(const AText: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(AText);
end;

class function TMemoryZip.Make(const ANames: array of string; const AData: array of string): TBytes;
var
  LStream: TBytesStream;
  LZip: TZipFile;
  LIndex: Integer;
begin
  LStream := TBytesStream.Create;
  try
    LZip := TZipFile.Create;
    try
      LZip.Open(LStream, TZipMode.zmWrite);
      for LIndex := 0 to High(ANames) do
        LZip.Add(Bytes(AData[LIndex]), ANames[LIndex]);
      LZip.Close;
    finally
      LZip.Free;
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

end.
