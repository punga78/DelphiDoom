{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - R_LoadImage      }
{                                                                              }
{  Port of R_LoadImage of renderer\tr_image.c. Based on the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Image.Loader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf,
  DelphiDoom.Q3Render.Image.TgaReader, DelphiDoom.Q3Render.Image.JpegReader;

type
  /// <summary>
  ///   R_LoadImage: ".tga" tries the TGA and, when there is none, the JPEG with the same name; ".jpg" the JPEG;
  ///   a name shorter than 5 characters or any other extension is nothing. ".pcx" and ".bmp" are not ported:
  ///   no file of OpenArena or of Quake III uses them (a request for one is False)
  /// </summary>
  /// <remarks>
  ///   With AExtensionSearch the loader behaves as the one of ioquake3, which is what OpenArena 0.8.8 runs (its
  ///   scripts write "clampmap menu/art/skill1" with no extension): a name with a known extension is tried as it is;
  ///   if that fails, or the name has no extension, the name without extension is tried with ".png", ".tga", ".jpg",
  ///   ".pcx", ".bmp" in this order. PNG, PCX and BMP are not decoded (a file that exists only in one of those is
  ///   not found: Load is False, and PngSkipped counts it)
  /// </remarks>
  TQ3ImageLoader = class(TInterfacedObject, IQ3ImageLoader)
  strict private
    FFiles: IQ3RenderFiles;
    FLog: ILog;
    FTga: TQ3TgaReader;
    FJpeg: TQ3JpegReader;
    FExtensionSearch: Boolean;
    FUnsupported: Integer;
    function LoadTga(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
    function LoadJpg(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
    function LoadSearching(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
  public
    constructor Create(const AFiles: IQ3RenderFiles; const ALog: ILog = nil; AExtensionSearch: Boolean = False);
    /// <summary>The files found in a format that is not decoded (png, pcx, bmp) while searching</summary>
    property UnsupportedFound: Integer read FUnsupported;
    destructor Destroy; override;
    function Load(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
  end;

implementation

constructor TQ3ImageLoader.Create(const AFiles: IQ3RenderFiles; const ALog: ILog; AExtensionSearch: Boolean);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
  FLog := ALog;
  FExtensionSearch := AExtensionSearch;
  FTga := TQ3TgaReader.Create(ALog);
  FJpeg := TQ3JpegReader.Create(ALog);
end;

destructor TQ3ImageLoader.Destroy;
begin
  FTga.Free;
  FJpeg.Free;
  inherited Destroy;
end;

function TQ3ImageLoader.LoadTga(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
var
  LData: TBytes;
begin
  AImage := Default(TQ3RenderImage);
  Result := FFiles.ReadFile(AName, LData);
  if Result then
    AImage := FTga.Read(AName, LData);
end;

function TQ3ImageLoader.LoadJpg(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
var
  LData: TBytes;
begin
  AImage := Default(TQ3RenderImage);
  Result := FFiles.ReadFile(AName, LData) and FJpeg.Read(AName, LData, AImage);
end;

function TQ3ImageLoader.LoadSearching(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
var
  LExtension, LBase: AnsiString;
  LDot: Integer;
  LData: TBytes;
  LIndex: Integer;
  LCandidate: AnsiString;
const
  FORMATS: array[0..4] of AnsiString = ('png', 'tga', 'jpg', 'pcx', 'bmp');
begin
  AImage := Default(TQ3RenderImage);
  LBase := AName;
  LDot := LastDelimiter('.', string(AName));
  if (LDot > 0) and (LastDelimiter('/\', string(AName)) < LDot) then
  begin
    LExtension := AnsiString(LowerCase(string(Copy(AName, LDot + 1, MaxInt))));
    // a loader for the extension: tried first, as it is
    if LExtension = 'tga' then
    begin
      if LoadTga(AName, AImage) then
        Exit(True);
    end
    else if LExtension = 'jpg' then
    begin
      if LoadJpg(AName, AImage) then
        Exit(True);
    end;
    if (LExtension = 'tga') or (LExtension = 'jpg') or (LExtension = 'png') or (LExtension = 'pcx') or
      (LExtension = 'bmp') then
      LBase := Copy(AName, 1, LDot - 1);
  end;
  // every format in the order of the loaders of ioquake3
  Result := False;
  for LIndex := 0 to High(FORMATS) do
  begin
    LCandidate := FORMATS[LIndex];
    if LCandidate = 'tga' then
      Result := LoadTga(LBase + '.tga', AImage)
    else if LCandidate = 'jpg' then
      Result := LoadJpg(LBase + '.jpg', AImage)
    else if FFiles.ReadFile(LBase + '.' + LCandidate, LData) then
      Inc(FUnsupported);
    if Result then
      Exit;
  end;
end;

function TQ3ImageLoader.Load(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
var
  LLength: Integer;
  LExtension, LAlternative: AnsiString;
begin
  AImage := Default(TQ3RenderImage);
  if FExtensionSearch then
    Exit(LoadSearching(AName, AImage));
  LLength := Length(AName);
  if LLength < 5 then
    Exit(False);
  LExtension := AnsiString(LowerCase(string(Copy(AName, LLength - 3, 4))));
  if LExtension = '.tga' then
  begin
    // try tga first, then jpg in place of tga
    Result := LoadTga(AName, AImage);
    if not Result then
    begin
      LAlternative := Copy(AName, 1, LLength - 3) + 'jpg';
      Result := LoadJpg(LAlternative, AImage);
    end;
  end
  else if LExtension = '.jpg' then
    Result := LoadJpg(AName, AImage)
  else
    Result := False;
end;

end.
