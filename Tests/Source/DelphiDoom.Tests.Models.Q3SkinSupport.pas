{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - support for the tests of the   }
{  skins and of the loading of the Quake III player models (fakes, data)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3SkinSupport;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>Files kept in memory: they are a text source and, with their length, a file probe</summary>
  TFakeQ3Files = class(TInterfacedObject, IQ3TextSource, IQ3FileProbe)
  strict private
    FFiles: TDictionary<string, AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFileName: string; const AContent: AnsiString);
    function ReadText(const AFileName: string): AnsiString;
    function FileLength(const AFileName: string): Integer;
  end;

  /// <summary>The files of a folder as a text source</summary>
  TFolderQ3TextSource = class(TInterfacedObject, IQ3TextSource)
  strict private
    FFolder: string;
  public
    constructor Create(const AFolder: string);
    function ReadText(const AFileName: string): AnsiString;
  end;

  /// <summary>Names with a length (the fs.txt of the parity driver)</summary>
  TListQ3FileProbe = class(TInterfacedObject, IQ3FileProbe)
  strict private
    FLengths: TDictionary<string, Integer>;
  public
    constructor Create(const AListFile: string);
    destructor Destroy; override;
    function FileLength(const AFileName: string): Integer;
  end;

/// <summary>Tests\Data\Models\q3player\skins (or a file in it)</summary>
function Q3SkinDataPath(const AName: string = ''): string;

/// <summary>The bytes of a file as an 8-bit string</summary>
function ReadAnsiFile(const AFileName: string): AnsiString;

/// <summary>
///   An MD3 with AFrames frames, one tag of each name in every frame (at x = the frame, y = tag number)
///   and one surface of each name, a triangle each; an empty shader means a surface with no shader
/// </summary>
function BuildSkinnedMd3(const AFrames: Integer; const ATagNames, ASurfaceNames, AShaders: array of AnsiString): AnsiString;

implementation

uses
  System.Classes,
  System.IOUtils;

function Q3SkinDataPath(const AName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Models\q3player\skins'));
  if AName <> '' then
    Result := TPath.Combine(Result, AName);
end;

function ReadAnsiFile(const AFileName: string): AnsiString;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(AFileName);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

procedure PutInt(const AStream: TBytesStream; const AValue: Integer);
begin
  AStream.WriteBuffer(AValue, 4);
end;

procedure PutFloat(const AStream: TBytesStream; const AValue: Single);
begin
  AStream.WriteBuffer(AValue, 4);
end;

procedure PutShort(const AStream: TBytesStream; const AValue: SmallInt);
begin
  AStream.WriteBuffer(AValue, 2);
end;

procedure PutName(const AStream: TBytesStream; const AName: AnsiString; const ASize: Integer);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, ASize);
  if Length(AName) > 0 then
    Move(AName[1], LBytes[0], Length(AName));
  AStream.WriteBuffer(LBytes[0], ASize);
end;

function BuildSkinnedMd3(const AFrames: Integer; const ATagNames, ASurfaceNames, AShaders: array of AnsiString): AnsiString;
const
  VERTS = 3;
  FRAME_SIZE = 56;
  TAG_SIZE = 112;
  SURFACE_HEADER = 108;
  SHADER_SIZE = 68;
var
  LStream: TBytesStream;
  LFrame, LTag, LSurface, LVert, LIndex, LOfsTags, LOfsSurfaces, LShaders, LSurfaceSize, LEnd: Integer;
begin
  LOfsTags := 108 + AFrames * FRAME_SIZE;
  LOfsSurfaces := LOfsTags + AFrames * Length(ATagNames) * TAG_SIZE;
  LEnd := LOfsSurfaces;
  for LSurface := 0 to High(ASurfaceNames) do
    Inc(LEnd, SURFACE_HEADER + Ord(AShaders[LSurface] <> '') * SHADER_SIZE + 12 + VERTS * 8 + VERTS * AFrames * 8);
  LStream := TBytesStream.Create;
  try
    PutInt(LStream, $33504449);
    PutInt(LStream, 15);
    PutName(LStream, 'models/test/part.md3', 64);
    PutInt(LStream, 0);
    PutInt(LStream, AFrames);
    PutInt(LStream, Length(ATagNames));
    PutInt(LStream, Length(ASurfaceNames));
    PutInt(LStream, 0);
    PutInt(LStream, 108);
    PutInt(LStream, LOfsTags);
    PutInt(LStream, LOfsSurfaces);
    PutInt(LStream, LEnd);
    for LFrame := 0 to AFrames - 1 do
    begin
      for LIndex := 0 to 8 do
        PutFloat(LStream, 0);
      PutFloat(LStream, 1);
      PutName(LStream, AnsiString('frame' + IntToStr(LFrame)), 16);
    end;
    for LFrame := 0 to AFrames - 1 do
      for LTag := 0 to High(ATagNames) do
      begin
        PutName(LStream, ATagNames[LTag], 64);
        PutFloat(LStream, LFrame);
        PutFloat(LStream, LTag);
        PutFloat(LStream, 0);
        for LIndex := 0 to 8 do
          PutFloat(LStream, Ord(LIndex mod 4 = 0));
      end;
    for LSurface := 0 to High(ASurfaceNames) do
    begin
      LShaders := Ord(AShaders[LSurface] <> '');
      LSurfaceSize := SURFACE_HEADER + LShaders * SHADER_SIZE + 12 + VERTS * 8 + VERTS * AFrames * 8;
      PutInt(LStream, $33504449);
      PutName(LStream, ASurfaceNames[LSurface], 64);
      PutInt(LStream, 0);
      PutInt(LStream, AFrames);
      PutInt(LStream, LShaders);
      PutInt(LStream, VERTS);
      PutInt(LStream, 1);
      PutInt(LStream, SURFACE_HEADER + LShaders * SHADER_SIZE);
      PutInt(LStream, SURFACE_HEADER);
      PutInt(LStream, SURFACE_HEADER + LShaders * SHADER_SIZE + 12);
      PutInt(LStream, SURFACE_HEADER + LShaders * SHADER_SIZE + 12 + VERTS * 8);
      PutInt(LStream, LSurfaceSize);
      if LShaders = 1 then
      begin
        PutName(LStream, AShaders[LSurface], 64);
        PutInt(LStream, 0);
      end;
      PutInt(LStream, 0);
      PutInt(LStream, 1);
      PutInt(LStream, 2);
      for LVert := 0 to VERTS - 1 do
      begin
        PutFloat(LStream, LVert * 0.25);
        PutFloat(LStream, 1 - LVert * 0.25);
      end;
      for LFrame := 0 to AFrames - 1 do
        for LVert := 0 to VERTS - 1 do
        begin
          PutShort(LStream, 64 * LVert);
          PutShort(LStream, 0);
          PutShort(LStream, 0);
          PutShort(LStream, 0);
        end;
    end;
    SetLength(Result, LStream.Size);
    if LStream.Size > 0 then
      Move(LStream.Bytes[0], Result[1], LStream.Size);
  finally
    LStream.Free;
  end;
end;

{ TFakeQ3Files }

constructor TFakeQ3Files.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, AnsiString>.Create;
end;

destructor TFakeQ3Files.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeQ3Files.Add(const AFileName: string; const AContent: AnsiString);
begin
  FFiles.AddOrSetValue(AFileName, AContent);
end;

function TFakeQ3Files.ReadText(const AFileName: string): AnsiString;
begin
  if not FFiles.TryGetValue(AFileName, Result) then
    Result := '';
end;

function TFakeQ3Files.FileLength(const AFileName: string): Integer;
var
  LContent: AnsiString;
begin
  if FFiles.TryGetValue(AFileName, LContent) then
    Result := Length(LContent)
  else
    Result := -1;
end;

{ TFolderQ3TextSource }

constructor TFolderQ3TextSource.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := AFolder;
end;

function TFolderQ3TextSource.ReadText(const AFileName: string): AnsiString;
var
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, StringReplace(AFileName, '/', '\', [rfReplaceAll]));
  if not TFile.Exists(LPath) then
    Exit('');
  Result := ReadAnsiFile(LPath);
end;

{ TListQ3FileProbe }

constructor TListQ3FileProbe.Create(const AListFile: string);
var
  LLines: TStringList;
  LLine: string;
  LSpace: Integer;
begin
  inherited Create;
  FLengths := TDictionary<string, Integer>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(AListFile);
    for LLine in LLines do
    begin
      LSpace := Pos(' ', LLine);
      if LSpace > 1 then
        FLengths.AddOrSetValue(Copy(LLine, 1, LSpace - 1), StrToInt(Trim(Copy(LLine, LSpace + 1, MaxInt))));
    end;
  finally
    LLines.Free;
  end;
end;

destructor TListQ3FileProbe.Destroy;
begin
  FLengths.Free;
  inherited Destroy;
end;

function TListQ3FileProbe.FileLength(const AFileName: string): Integer;
begin
  if not FLengths.TryGetValue(AFileName, Result) then
    Result := -1;
end;

end.
