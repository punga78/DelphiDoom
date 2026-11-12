{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom engine library - the fakes of the tests of     }
{  the fonts (a log that keeps its lines, pictures of fonts made in memory)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FontFakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Png.Client, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Intf;

type
  /// <summary>IXcomLog that keeps every line as "LEVEL message"</summary>
  TFontTestLog = class(TInterfacedObject, IXcomLog)
  public
    Lines: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Write(const ALevel, AMessage: string);
    /// <summary>How many lines have the level and the text</summary>
    function Count(const ALevel, AText: string): Integer;
  end;

  /// <summary>The original font of the tests: cells of 6 x 8, four in a row, each with a body of 2 x 4 pixels</summary>
  TFontFixtures = class
  public
    const
      CELL_WIDTH = 6;
      CELL_HEIGHT = 8;
      COLUMNS = 4;
    /// <summary>The picture of ACount cells; the caller owns it</summary>
    class function Picture(ACount: Integer): TXcomSurface; static;
    /// <summary>A font with one picture and these characters; the caller owns it</summary>
    class function Font(const AChars: string): TXcomFont; static;
  end;

  /// <summary>
  ///   IXcomSurfaceLoader of the tests: a file that the file system has (a PNG that was written there) is decoded,
  ///   any other name is the picture of the fixtures with ACells cells
  /// </summary>
  TFontTestLoader = class(TInterfacedObject, IXcomSurfaceLoader)
  strict private
    FFiles: IXcomFileSystem;
    FFolder: string;
    FPng: TPngClient;
    FCells: Integer;
  public
    /// <param name="AFiles">nil: every picture is the one of the fixtures</param>
    constructor Create(const AFiles: IXcomFileSystem; const AFolder: string; APng: TPngClient; ACells: Integer);
    function LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
  end;

implementation

uses
  System.IOUtils;

{ TFontTestLog }

constructor TFontTestLog.Create;
begin
  inherited Create;
  Lines := TStringList.Create;
end;

destructor TFontTestLog.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

procedure TFontTestLog.Write(const ALevel, AMessage: string);
begin
  Lines.Add(ALevel + ' ' + AMessage);
end;

function TFontTestLog.Count(const ALevel, AText: string): Integer;
var
  LLine: string;
begin
  Result := 0;
  for LLine in Lines do
    if LLine.StartsWith(ALevel + ' ') and LLine.Contains(AText) then
      Inc(Result);
end;

{ TFontFixtures }

class function TFontFixtures.Picture(ACount: Integer): TXcomSurface;
var
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
begin
  Result := TXcomSurface.Create(COLUMNS * CELL_WIDTH, ((ACount + COLUMNS - 1) div COLUMNS) * CELL_HEIGHT);
  for LIndex := 0 to ACount - 1 do
    for LY := 1 to 4 do
      for LX := 1 to 2 do
        Result.SetPixel(LIndex mod COLUMNS * CELL_WIDTH + LX, LIndex div COLUMNS * CELL_HEIGHT + LY, 1);
end;

class function TFontFixtures.Font(const AChars: string): TXcomFont;
var
  LCodes: TArray<Cardinal>;
begin
  LCodes := TXcomFont.CodePoints(AChars);
  Result := TXcomFont.Create;
  Result.Init(Result.AddImage(CELL_WIDTH, CELL_HEIGHT, 1, Picture(Length(LCodes))), LCodes);
end;

{ TFontTestLoader }

constructor TFontTestLoader.Create(const AFiles: IXcomFileSystem; const AFolder: string; APng: TPngClient;
  ACells: Integer);
begin
  inherited Create;
  FFiles := AFiles;
  FFolder := AFolder;
  FPng := APng;
  FCells := ACells;
end;

function TFontTestLoader.LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
var
  LImage: TPngIndexedImage;
begin
  if not Assigned(FFiles) or not FFiles.FileExists(TPath.Combine(FFolder, AName)) then
    Exit(TFontFixtures.Picture(FCells));
  LImage := FPng.DecodeIndexed(FFiles.ReadAll(TPath.Combine(FFolder, AName)));
  Result := TXcomSurface.Create(LImage.Info.Width, LImage.Info.Height);
  Move(LImage.Pixels[0], Result.PixelPointer(0, 0)^, LImage.Info.Width * LImage.Info.Height);
end;

end.
