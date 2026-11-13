{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the pk3 files of OpenArena as  }
{  the files of a Quake III player                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3PakSupport;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   The files of some pk3 (ZIP) read with Libs\Wad: a later pak hides the same name of an earlier
  ///   one, the names do not distinguish upper and lower case (as the file system of Quake III).
  /// </summary>
  TQ3PakFiles = class(TInterfacedObject, IQ3TextSource, IQ3FileProbe)
  strict private
    type
      TLocation = record
        Source: Integer;
        Entry: Integer;
        Size: Integer;
      end;
  strict private
    FSources: TList<IWadSource>;
    FFiles: TDictionary<string, TLocation>;
  public
    constructor Create(const APaks: array of string);
    destructor Destroy; override;
    function ReadText(const AFileName: string): AnsiString;
    function FileLength(const AFileName: string): Integer;
    /// <summary>The names of all the files that start with a prefix (lowercase), in no order</summary>
    function Names(const APrefix: string): TArray<string>;
  end;

/// <summary>The baseoa folder of OpenArena in Reference\openarena, empty if it is not there</summary>
function FindOpenArenaFolder: string;

implementation

uses
  System.IOUtils,
  DelphiDoom.Wad.Source.Zip;

function FindOpenArenaFolder: string;
var
  LFolder, LCandidate: string;
  LLevel: Integer;
begin
  LFolder := TPath.GetDirectoryName(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    LCandidate := TPath.Combine(LFolder, 'Reference\openarena\openarena-0.8.8\baseoa');
    if TDirectory.Exists(LCandidate) then
      Exit(LCandidate);
    LFolder := TPath.GetDirectoryName(LFolder);
    if LFolder = '' then
      Break;
  end;
  Result := '';
end;

constructor TQ3PakFiles.Create(const APaks: array of string);
var
  LPak, LIndex: Integer;
  LSource: IWadSource;
  LLocation: TLocation;
begin
  inherited Create;
  FSources := TList<IWadSource>.Create;
  FFiles := TDictionary<string, TLocation>.Create;
  for LPak := 0 to High(APaks) do
  begin
    LSource := TZipFileSource.Create(APaks[LPak]);
    FSources.Add(LSource);
    for LIndex := 0 to LSource.Count - 1 do
    begin
      LLocation.Source := FSources.Count - 1;
      LLocation.Entry := LIndex;
      LLocation.Size := LSource.Entries[LIndex].Size;
      FFiles.AddOrSetValue(LowerCase(LSource.Entries[LIndex].Name), LLocation);
    end;
  end;
end;

destructor TQ3PakFiles.Destroy;
begin
  FFiles.Free;
  FSources.Free;
  inherited Destroy;
end;

function TQ3PakFiles.FileLength(const AFileName: string): Integer;
var
  LLocation: TLocation;
begin
  if FFiles.TryGetValue(LowerCase(AFileName), LLocation) then
    Result := LLocation.Size
  else
    Result := -1;
end;

function TQ3PakFiles.ReadText(const AFileName: string): AnsiString;
var
  LLocation: TLocation;
  LBytes: TBytes;
begin
  if not FFiles.TryGetValue(LowerCase(AFileName), LLocation) then
    Exit('');
  LBytes := FSources[LLocation.Source].ReadEntry(LLocation.Entry);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

function TQ3PakFiles.Names(const APrefix: string): TArray<string>;
var
  LName: string;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  try
    for LName in FFiles.Keys do
      if LName.StartsWith(APrefix) then
        LList.Add(LName);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
