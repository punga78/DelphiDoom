{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the registered fonts                              }
{                                                                              }
{  Port of RE_RegisterFont (the .dat file branch) and the table                }
{  registeredFont of tr_font.c (Quake III Arena, id Software, GPL v2 or        }
{  later). Based on the Quake III Arena GPL Source Code (id Software).         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.FontRegistry;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Font,
  DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>The fonts read so far: at most six, looked up by the name of their file</summary>
  TGuiFontRegistry = class
  strict private
    FFileSystem: IIdLibFileSystem;
    FAssets: IGuiAssetRegistry;
    FLog: IGuiLog;
    FFonts: TObjectList<TGuiFont>;
    function Find(const AName: AnsiString): TGuiFont;
  public
    /// <summary>The file system reads "fonts/fontImage_N.dat"; the log (nil: silence) gets the refusals</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem; const AAssets: IGuiAssetRegistry; const ALog: IGuiLog);
    destructor Destroy; override;
    /// <summary>
    ///   RE_RegisterFont: the file is "fonts/fontImage_N.dat" with N the point size (12 if it is not positive);
    ///   the font name is not used (no FreeType). False, and AFont untouched, if the table is full or the file is
    ///   not a 20548 byte font. The shaders of glyphs 0 to 254 are registered; glyph 255 keeps the handle of the
    ///   file (the loop of the original stops before GLYPH_END).
    /// </summary>
    function Register(const AFontName: AnsiString; const APointSize: Integer; const AFont: TGuiFont): Boolean;
    /// <summary>R_InitFreeType / R_DoneFreeType: forgets the fonts</summary>
    procedure Clear;
    function Count: Integer;
  end;

implementation

uses
  DelphiDoom.Gui.Font.Types, DelphiDoom.Gui.FontReader, DelphiDoom.IdLib.Text.Strings;

constructor TGuiFontRegistry.Create(const AFileSystem: IIdLibFileSystem; const AAssets: IGuiAssetRegistry;
  const ALog: IGuiLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FAssets := AAssets;
  FLog := ALog;
  FFonts := TObjectList<TGuiFont>.Create(True);
end;

destructor TGuiFontRegistry.Destroy;
begin
  FFonts.Free;
  inherited Destroy;
end;

function TGuiFontRegistry.Find(const AName: AnsiString): TGuiFont;
var
  LFont: TGuiFont;
begin
  for LFont in FFonts do
    if TIdStrings.Icmp(AName, LFont.Name) = 0 then
      Exit(LFont);
  Result := nil;
end;

function TGuiFontRegistry.Register(const AFontName: AnsiString; const APointSize: Integer;
  const AFont: TGuiFont): Boolean;
var
  LPointSize: Integer;
  LName: AnsiString;
  LCached: TGuiFont;
  LFile: TIdLibFileData;
  LIndex: Integer;
  LGlyph: TGuiGlyph;
  LStored: TGuiFont;
begin
  LPointSize := APointSize;
  if LPointSize <= 0 then
    LPointSize := 12;
  if FFonts.Count >= GUI_MAX_FONTS then
  begin
    if Assigned(FLog) then
      FLog.Info('RE_RegisterFont: Too many fonts registered already.');
    Exit(False);
  end;
  LName := AnsiString(Format('fonts/fontImage_%d.dat', [LPointSize]));
  LCached := Find(LName);
  if Assigned(LCached) then
  begin
    AFont.Assign(LCached);
    Exit(True);
  end;
  if (not Assigned(FFileSystem)) or (not FFileSystem.TryReadFile(LName, False, LFile)) or
    (Length(LFile.Data) <> GUI_FONT_FILE_SIZE) then
  begin
    if Assigned(FLog) then
      FLog.Info('RE_RegisterFont: FreeType code not available');
    Exit(False);
  end;
  TGuiFontReader.Read(LFile.Data, AFont);
  AFont.Name := LName;
  for LIndex := 0 to GUI_GLYPHS_PER_FONT - 2 do
  begin
    LGlyph := AFont.Glyphs[LIndex];
    LGlyph.Glyph := FAssets.RegisterShader(AFont.ShaderName(LIndex));
    AFont.Glyphs[LIndex] := LGlyph;
  end;
  LStored := TGuiFont.Create;
  LStored.Assign(AFont);
  FFonts.Add(LStored);
  Result := True;
end;

procedure TGuiFontRegistry.Clear;
begin
  FFonts.Clear;
end;

function TGuiFontRegistry.Count: Integer;
begin
  Result := FFonts.Count;
end;

end.
