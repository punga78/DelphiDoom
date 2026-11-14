{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - support for the tests of the   }
{  Quake III player models (fakes, data files, MD3 builder)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3PlayerSupport;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Logging.Types,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>A log that keeps the warnings</summary>
  TFakeQ3Log = class(TInterfacedObject, ILog)
  strict private
    FWarnings: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: TStringList read FWarnings;
  end;

  /// <summary>Texts of files kept in memory</summary>
  TFakeQ3TextSource = class(TInterfacedObject, IQ3TextSource)
  strict private
    FFiles: TDictionary<string, AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFileName: string; const AText: AnsiString);
    function ReadText(const AFileName: string): AnsiString;
  end;

  /// <summary>The files of Tests\Data\Models\q3player\files</summary>
  TFileQ3TextSource = class(TInterfacedObject, IQ3TextSource)
  public
    function ReadText(const AFileName: string): AnsiString;
  end;

  /// <summary>One tag of a model built in memory: name, origin and the nine numbers of the axes</summary>
  TQ3TestTag = record
    Name: AnsiString;
    Origin: array[0..2] of Single;
    Axis: array[0..8] of Single;
  end;

/// <summary>True if the action raises an exception of the class (or of a descendant)</summary>
function Raises(const AAction: TProc; const AClass: TClass): Boolean;

/// <summary>A file of Tests\Data\Models\q3player</summary>
function Q3DataFile(const AName: string): TBytes;

/// <summary>An MD3 without surfaces: AFrames frames, each with the tags of ATags (ATags[frame * count + tag])</summary>
function BuildTagsMd3(const AFrames, ATagCount: Integer; const ATags: array of TQ3TestTag): TBytes;

/// <summary>The identity axes of a tag</summary>
function IdentityAxis: TQ3TestTag;

/// <summary>A tag with the identity axes at an origin</summary>
function TagAt(const AName: AnsiString; const AX, AY, AZ: Single): TQ3TestTag;

/// <summary>Reads a model of bytes</summary>
function ReadMd3(const ABytes: TBytes): IMd3Model;

implementation

uses
  System.IOUtils,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Static.Md3.Types;

constructor TFakeQ3Log.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TFakeQ3Log.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TFakeQ3Log.Info(const AText: string);
begin
end;

procedure TFakeQ3Log.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TFakeQ3Log.DevWarning(const AText: string);
begin
end;

procedure TFakeQ3Log.Error(const AText: string);
begin
end;

constructor TFakeQ3TextSource.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, AnsiString>.Create;
end;

destructor TFakeQ3TextSource.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeQ3TextSource.Add(const AFileName: string; const AText: AnsiString);
begin
  FFiles.AddOrSetValue(AFileName, AText);
end;

function TFakeQ3TextSource.ReadText(const AFileName: string): AnsiString;
begin
  if not FFiles.TryGetValue(AFileName, Result) then
    Result := '';
end;

function Raises(const AAction: TProc; const AClass: TClass): Boolean;
begin
  Result := False;
  try
    AAction;
  except
    on E: Exception do
      Result := E is AClass;
  end;
end;

function Q3DataPath(const AName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Models\q3player\' + AName));
end;

function Q3DataFile(const AName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(Q3DataPath(AName));
end;

function TFileQ3TextSource.ReadText(const AFileName: string): AnsiString;
var
  LPath: string;
  LBytes: TBytes;
begin
  LPath := Q3DataPath('files\' + AFileName);
  if not TFile.Exists(LPath) then
    Exit('');
  LBytes := TFile.ReadAllBytes(LPath);
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

procedure PutName(const AStream: TBytesStream; const AName: AnsiString; const ASize: Integer);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, ASize);
  if Length(AName) > 0 then
    Move(AName[1], LBytes[0], Length(AName));
  AStream.WriteBuffer(LBytes[0], ASize);
end;

function BuildTagsMd3(const AFrames, ATagCount: Integer; const ATags: array of TQ3TestTag): TBytes;
var
  LStream: TBytesStream;
  LFrame, LTag, LIndex, LOfsTags, LEnd: Integer;
begin
  LOfsTags := MD3_HEADER_SIZE + AFrames * MD3_FRAME_SIZE;
  LEnd := LOfsTags + AFrames * ATagCount * MD3_TAG_SIZE;
  LStream := TBytesStream.Create;
  try
    PutInt(LStream, $33504449);
    PutInt(LStream, MD3_VERSION);
    PutName(LStream, 'models/test/tags.md3', MD3_MAX_PATH);
    PutInt(LStream, 0);
    PutInt(LStream, AFrames);
    PutInt(LStream, ATagCount);
    PutInt(LStream, 0);
    PutInt(LStream, 0);
    PutInt(LStream, MD3_HEADER_SIZE);
    PutInt(LStream, LOfsTags);
    PutInt(LStream, LEnd);
    PutInt(LStream, LEnd);
    for LFrame := 0 to AFrames - 1 do
    begin
      for LIndex := 0 to 8 do
        PutFloat(LStream, 0);
      PutFloat(LStream, 1);
      PutName(LStream, AnsiString('frame' + IntToStr(LFrame)), 16);
    end;
    for LFrame := 0 to AFrames - 1 do
      for LTag := 0 to ATagCount - 1 do
      begin
        PutName(LStream, ATags[LFrame * ATagCount + LTag].Name, MD3_MAX_PATH);
        for LIndex := 0 to 2 do
          PutFloat(LStream, ATags[LFrame * ATagCount + LTag].Origin[LIndex]);
        for LIndex := 0 to 8 do
          PutFloat(LStream, ATags[LFrame * ATagCount + LTag].Axis[LIndex]);
      end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function IdentityAxis: TQ3TestTag;
var
  LIndex: Integer;
begin
  Result.Name := '';
  for LIndex := 0 to 2 do
    Result.Origin[LIndex] := 0;
  for LIndex := 0 to 8 do
    Result.Axis[LIndex] := Ord(LIndex mod 4 = 0);
end;

function TagAt(const AName: AnsiString; const AX, AY, AZ: Single): TQ3TestTag;
begin
  Result := IdentityAxis;
  Result.Name := AName;
  Result.Origin[0] := AX;
  Result.Origin[1] := AY;
  Result.Origin[2] := AZ;
end;

function ReadMd3(const ABytes: TBytes): IMd3Model;
begin
  Result := TStaticModelFactory.CreateMd3Reader.Read(ABytes, 'test.md3');
end;

end.
