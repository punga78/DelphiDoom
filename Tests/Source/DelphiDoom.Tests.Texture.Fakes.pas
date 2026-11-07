{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Texture library - fakes for the dependencies       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.Texture.Types, DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf,
  DelphiDoom.Texture.Factory, DelphiDoom.Tests.Texture.Samples;

type
  /// <summary>A log that remembers the warnings</summary>
  TFakeLog = class(TInterfacedObject, ILog)
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

  /// <summary>The palette of TTextureSamples.GamePalette</summary>
  TFakePaletteSource = class(TInterfacedObject, ITexturePaletteSource)
  public
    function GetColors: TTexturePixels;
  end;

  /// <summary>The PNG files are the cases of TTextureSamples.PngCases, found by the first byte</summary>
  TFakePngReader = class(TInterfacedObject, ITexturePngReader)
  strict private
    FCases: TTextureSamplePngs;
    FFail: Boolean;
  public
    constructor Create(AFail: Boolean = False);
    function Read(const ASource: TBytes; out AData: TTexturePngData; out AMessage: string): Boolean;
  end;

  TFakePngSettings = class(TInterfacedObject, ITexturePngSettings)
  public
    Color: Cardinal;
    Color2: Cardinal;
    AssumeCommon: Boolean;
    constructor Create;
    function GetTransparentColor: Cardinal;
    function GetTransparentColor2: Cardinal;
    function GetAssumeCommonColors: Boolean;
  end;

  /// <summary>Gives back the bytes that it was given, or raises when it is told to</summary>
  TFakeJpegConverter = class(TInterfacedObject, ITextureJpegConverter)
  public
    Bitmap: TBytes;
    Fails: Boolean;
    Calls: Integer;
    function ToBitmap(const ASource: TBytes): TBytes;
  end;

  /// <summary>The external textures by name; the images are given back as new copies</summary>
  TFakeResolver = class(TInterfacedObject, ITextureResolver)
  strict private
    FImages: TObjectDictionary<string, TTextureImage>;
  public
    Requests: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AImage: TTextureImage);
    function Load(const AName: string): TTextureImage;
  end;

  TFakes = class sealed
  public
    class function Services(const ALog: ILog): TTextureServices; static;
  end;

implementation

{ TFakeLog }

constructor TFakeLog.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TFakeLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

{ TFakePaletteSource }

function TFakePaletteSource.GetColors: TTexturePixels;
begin
  Result := TTextureSamples.GamePalette;
end;

{ TFakePngReader }

constructor TFakePngReader.Create(AFail: Boolean);
begin
  inherited Create;
  FCases := TTextureSamples.PngCases;
  FFail := AFail;
end;

function TFakePngReader.Read(const ASource: TBytes; out AData: TTexturePngData;
  out AMessage: string): Boolean;
begin
  AData := Default(TTexturePngData);
  AMessage := '';
  if FFail or (Length(ASource) < 4) or (ASource[0] >= Length(FCases)) then
  begin
    AMessage := 'the file is not a PNG';
    Exit(False);
  end;
  AData := FCases[ASource[0]].Data;
  Result := True;
end;

{ TFakePngSettings }

constructor TFakePngSettings.Create;
begin
  inherited Create;
  Color := $FF00FF;
  Color2 := $FFFF;
  AssumeCommon := True;
end;

function TFakePngSettings.GetTransparentColor: Cardinal;
begin
  Result := Color;
end;

function TFakePngSettings.GetTransparentColor2: Cardinal;
begin
  Result := Color2;
end;

function TFakePngSettings.GetAssumeCommonColors: Boolean;
begin
  Result := AssumeCommon;
end;

{ TFakeJpegConverter }

function TFakeJpegConverter.ToBitmap(const ASource: TBytes): TBytes;
begin
  Inc(Calls);
  if Fails then
    raise ETextureException.Create('the JPEG is damaged');
  Result := Bitmap;
end;

{ TFakeResolver }

constructor TFakeResolver.Create;
begin
  inherited Create;
  FImages := TObjectDictionary<string, TTextureImage>.Create([doOwnsValues]);
  Requests := TStringList.Create;
end;

destructor TFakeResolver.Destroy;
begin
  Requests.Free;
  FImages.Free;
  inherited Destroy;
end;

procedure TFakeResolver.Add(const AName: string; const AImage: TTextureImage);
begin
  FImages.AddOrSetValue(AName, AImage);
end;

function TFakeResolver.Load(const AName: string): TTextureImage;
var
  LImage: TTextureImage;
begin
  Requests.Add(AName);
  if not FImages.TryGetValue(AName, LImage) then
    Exit(nil);
  Result := LImage.Clone;
end;

{ TFakes }

class function TFakes.Services(const ALog: ILog): TTextureServices;
begin
  Result.Palette := TFakePaletteSource.Create;
  Result.Resolver := TFakeResolver.Create;
  Result.PngReader := TFakePngReader.Create;
  Result.PngSettings := TFakePngSettings.Create;
  Result.JpegConverter := TFakeJpegConverter.Create;
  Result.Log := ALog;
end;

end.
