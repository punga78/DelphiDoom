{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Screenshot library - fakes                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Intf;

type
  /// <summary>An encoder that gives a few bytes and remembers what it was asked</summary>
  TFakeEncoder = class(TInterfacedObject, IScreenshotEncoder)
  private
    FFormat: TScreenshotFormat;
    FFails: Boolean;
    FCalls: Integer;
    FLastBottomUp: Boolean;
  public
    constructor Create(AFormat: TScreenshotFormat; AFails: Boolean = False);
    function GetFormat: TScreenshotFormat;
    function Encode(APixels: Pointer; AWidth, AHeight: Integer; ABottomUp: Boolean): TBytes;
    property Calls: Integer read FCalls;
    property LastBottomUp: Boolean read FLastBottomUp;
  end;

  /// <summary>A sink that keeps the files in memory</summary>
  TFakeSink = class(TInterfacedObject, IScreenshotFileSink)
  private
    FFiles: TDictionary<string, TBytes>;
    FRefused: string;
  public
    constructor Create;
    destructor Destroy; override;
    function Write(const APath: string; const AContent: TBytes): Boolean;
    function Has(const APath: string): Boolean;
    function Content(const APath: string): TBytes;
    function Count: Integer;
    /// <summary>The path that the sink refuses to write ('' for none)</summary>
    property Refused: string read FRefused write FRefused;
  end;

  /// <summary>The folders of a game that lives in C:\Game\</summary>
  TFakeFolders = class(TInterfacedObject, IScreenshotFolders)
  public
    function PathOf(const ARelativeName: string): string;
  end;

implementation

{ TFakeEncoder }

constructor TFakeEncoder.Create(AFormat: TScreenshotFormat; AFails: Boolean);
begin
  inherited Create;
  FFormat := AFormat;
  FFails := AFails;
end;

function TFakeEncoder.GetFormat: TScreenshotFormat;
begin
  Result := FFormat;
end;

function TFakeEncoder.Encode(APixels: Pointer; AWidth, AHeight: Integer;
  ABottomUp: Boolean): TBytes;
begin
  Inc(FCalls);
  FLastBottomUp := ABottomUp;
  if FFails then
    raise EScreenshotException.Create('fails');
  Result := TBytes.Create(Byte(Ord(FFormat) + 1), Byte(AWidth), Byte(AHeight));
end;

{ TFakeSink }

constructor TFakeSink.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TFakeSink.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

function TFakeSink.Write(const APath: string; const AContent: TBytes): Boolean;
begin
  Result := (APath <> FRefused) and (Length(AContent) > 0);
  if Result then
    FFiles.AddOrSetValue(APath, AContent);
end;

function TFakeSink.Has(const APath: string): Boolean;
begin
  Result := FFiles.ContainsKey(APath);
end;

function TFakeSink.Content(const APath: string): TBytes;
begin
  Result := FFiles[APath];
end;

function TFakeSink.Count: Integer;
begin
  Result := FFiles.Count;
end;

{ TFakeFolders }

function TFakeFolders.PathOf(const ARelativeName: string): string;
begin
  Result := 'C:\Game\' + ARelativeName;
end;

end.
