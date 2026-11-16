{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the choice of the fonts of the system in   }
{  the advanced options (issue 184)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontChoices;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.ExtraOptions.Intf, DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf,
  DelphiDoom.XcomEngine.SystemFonts.Intf, DelphiDoom.XcomEngine.FontSettingsSource.Intf,
  DelphiDoom.XcomSurface.Glyph.Types;

type
  /// <summary>
  ///   The rows of the advanced options that choose the font of Windows for each of the four fonts of the game
  ///   (FONT_BIG, FONT_SMALL, FONT_GEO_BIG, FONT_GEO_SMALL): the font (Original, or one of the usual families the
  ///   system has), its size, bold, smooth edges and shrink to fit. The choice is kept in fonts.cfg of the user
  ///   folder when the options are confirmed (Commit) and forgotten when they are cancelled (Discard); the entries
  ///   of the file that the rows do not show (file, outline, spacing, tolerance, offsetY) are kept. With a file
  ///   given on the command line (-fonts) the fonts are that file's and the rows are one line that says so
  /// </summary>
  TXcomFontChoices = class(TInterfacedObject, IXcomExtraOptions, IXcomExtraChoiceOptions, IXcomFontSettingsSource)
  strict private
    const
      FIELD_FACE = 0;
      FIELD_SIZE = 1;
      FIELD_BOLD = 2;
      FIELD_SMOOTH = 3;
      FIELD_SHRINK = 4;
      FIELD_COUNT = 5;
      FONT_COUNT = 4;
      LARGEST_SIZE = 32;
  strict private
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    FPath: string;
    FLocked: Boolean;
    FInstalled: TArray<string>;
    FKnowsInstalled: Boolean;
    FStored: TArray<TXcomFontOverlaySettings>;
    FPending: TArray<TXcomFontOverlaySettings>;
    FStoredText: string;
    class function FontIdOf(AFont: Integer): string; static;
    class function FontTitleOf(AFont: Integer): string; static;
    function IndexOfFont(const AFontId: string): Integer;
    function IsInstalled(const AFamily: string): Boolean;
    function Choices(const ACurrent: string): TArray<string>;
    class function CurrentFace(const ASettings: TXcomFontOverlaySettings): string; static;
    function NewEntry(AFont: Integer; const AFace: string): TXcomFontOverlaySettings;
    procedure StepFace(AFont, ADirection: Integer);
    procedure StepSize(AFont, ADirection: Integer);
    procedure RemoveFont(const AFontId: string);
  public
    const
      /// <summary>The families offered besides Original, when the system has them (the usual UI, monospace and CJK ones)</summary>
      USUAL_FAMILIES: array[0..19] of string = ('Tahoma', 'Verdana', 'Segoe UI', 'Arial', 'Calibri',
        'Trebuchet MS', 'Lucida Sans Unicode', 'Microsoft Sans Serif', 'Georgia', 'Consolas', 'Courier New',
        'Lucida Console', 'MS Gothic', 'Malgun Gothic', 'Microsoft YaHei', 'MingLiU', 'Batang', 'Small Fonts',
        'MS Sans Serif', 'Times New Roman');
    /// <param name="AFiles">Reads and writes fonts.cfg</param>
    /// <param name="APath">fonts.cfg of the user folder; empty: nothing is read or written</param>
    /// <param name="ALockedPath">
    ///   The file of -fonts: when it is not empty the fonts are the ones of that file and cannot be changed here
    /// </param>
    /// <param name="AFonts">The installed families; nil: all the usual ones are offered</param>
    /// <param name="ALog">Where the warnings of the file go; nil for nowhere</param>
    constructor Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser; const APath, ALockedPath: string;
      const AFonts: IXcomSystemFonts; const ALog: IXcomLog);
    function Heading: string;
    function Count: Integer;
    function Title(AIndex: Integer): string;
    function Description(AIndex: Integer): string;
    function IsOn(AIndex: Integer): Boolean;
    procedure SetOn(AIndex: Integer; AValue: Boolean);
    function Kind(AIndex: Integer): TXcomExtraKind;
    procedure Step(AIndex, ADirection: Integer);
    procedure Discard;
    function Settings: TArray<TXcomFontOverlaySettings>;
    procedure Commit;
  end;

implementation

uses
  DelphiDoom.XcomEngine.FontSettingsReader, DelphiDoom.XcomEngine.FontSettingsWriter,
  DelphiDoom.XcomEngine.AtomicFileWriter;

const
  SHeading = 'DELPHIDOOM';
  SOriginal = 'Original';
  SLocked = 'Fonts: set by -fonts on the command line';
  SLockedDescription = 'The fonts of the game come from the file given with -fonts: it is not changed here.';
  SFaceTitle = '%s: %s';
  SSizeTitle = '%s size: %s';
  SBoldTitle = '%s bold';
  SSmoothTitle = '%s smooth edges';
  SShrinkTitle = '%s shrink to fit';
  SNoValue = '-';
  SFaceDescription = 'Font of Windows for the %s. Click: the next one, right click: the previous one. Original ' +
    'is the font of the game. It is applied when the options are confirmed.';
  SSizeDescription = 'Size in pixels of the %s (of the 320 x 200 screen). Click: larger, right click: smaller. ' +
    'Choose a font first.';
  SBoldDescription = 'Bold letters for the %s. It counts once a font of Windows is chosen.';
  SSmoothDescription = 'Gray edges for the %s. Without them the pixels are the ones of the system: right for ' +
    'bitmap fonts and sizes the font is hinted for. It counts once a font of Windows is chosen.';
  SShrinkDescription = 'A font that is too large for the %s is tried one pixel smaller until it fits. ' +
    'Choose a font first.';
  FONT_IDS: array[0..3] of string = ('FONT_BIG', 'FONT_SMALL', 'FONT_GEO_BIG', 'FONT_GEO_SMALL');
  FONT_TITLES: array[0..3] of string = ('Big font', 'Small font', 'Geoscape big font', 'Geoscape small font');
  // the first font of the system that is chosen for a font of the game: sizes that fit its cells
  FONT_SIZES: array[0..3] of Integer = (13, 8, 8, 6);
  FONT_BOLD: array[0..3] of Boolean = (True, False, False, False);

constructor TXcomFontChoices.Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser;
  const APath, ALockedPath: string; const AFonts: IXcomSystemFonts; const ALog: IXcomLog);
var
  LSource: string;
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  FFiles := AFiles;
  FParser := AParser;
  FPath := APath;
  FLocked := ALockedPath <> '';
  FKnowsInstalled := Assigned(AFonts);
  if FKnowsInstalled then
    FInstalled := AFonts.Families;
  if FLocked then
    LSource := ALockedPath
  else
    LSource := APath;
  if (LSource <> '') and FFiles.FileExists(LSource) then
    FStored := TXcomFontSettingsReader.Read(FParser.Load(FFiles.ReadAll(LSource)), ALog);
  FPending := Copy(FStored);
  FStoredText := TXcomFontSettingsWriter.Write(FStored);
end;

class function TXcomFontChoices.FontIdOf(AFont: Integer): string;
begin
  Result := FONT_IDS[AFont];
end;

class function TXcomFontChoices.FontTitleOf(AFont: Integer): string;
begin
  Result := FONT_TITLES[AFont];
end;

function TXcomFontChoices.IndexOfFont(const AFontId: string): Integer;
var
  LIndex: Integer;
begin
  // the last entry of a font wins, as the overlay reads the file
  Result := -1;
  for LIndex := 0 to High(FPending) do
    if SameText(FPending[LIndex].FontId, AFontId) then
      Result := LIndex;
end;

function TXcomFontChoices.IsInstalled(const AFamily: string): Boolean;
var
  LName: string;
begin
  if not FKnowsInstalled then
    Exit(True);
  Result := False;
  for LName in FInstalled do
    if SameText(LName, AFamily) then
      Exit(True);
end;

class function TXcomFontChoices.CurrentFace(const ASettings: TXcomFontOverlaySettings): string;
begin
  Result := ASettings.Face.Name;
  if Result = '' then
    Result := ASettings.Face.FileName;
end;

function TXcomFontChoices.Choices(const ACurrent: string): TArray<string>;
var
  LList: TList<string>;
  LFamily: string;
  LFound: Boolean;
  LName: string;
begin
  LList := TList<string>.Create;
  try
    LList.Add('');
    for LFamily in USUAL_FAMILIES do
      if IsInstalled(LFamily) then
        LList.Add(LFamily);
    // a font written by hand in the file stays in the list, next to Original
    if ACurrent <> '' then
    begin
      LFound := False;
      for LName in LList do
        if SameText(LName, ACurrent) then
          LFound := True;
      if not LFound then
        LList.Insert(1, ACurrent);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomFontChoices.NewEntry(AFont: Integer; const AFace: string): TXcomFontOverlaySettings;
begin
  Result := TXcomFontOverlaySettings.Make(FontIdOf(AFont), AFace, FONT_SIZES[AFont]);
  Result.Face.Bold := FONT_BOLD[AFont];
  // a font chosen here should not fail for a pixel: it is tried smaller
  Result.Shrink := True;
end;

procedure TXcomFontChoices.RemoveFont(const AFontId: string);
var
  LList: TList<TXcomFontOverlaySettings>;
  LEntry: TXcomFontOverlaySettings;
begin
  LList := TList<TXcomFontOverlaySettings>.Create;
  try
    for LEntry in FPending do
      if not SameText(LEntry.FontId, AFontId) then
        LList.Add(LEntry);
    FPending := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure TXcomFontChoices.StepFace(AFont, ADirection: Integer);
var
  LIndex: Integer;
  LCurrent: string;
  LList: TArray<string>;
  LPosition: Integer;
  LNext: string;
  LEntry: TXcomFontOverlaySettings;
begin
  LIndex := IndexOfFont(FontIdOf(AFont));
  LCurrent := '';
  if LIndex >= 0 then
    LCurrent := CurrentFace(FPending[LIndex]);
  LList := Choices(LCurrent);
  LPosition := 0;
  for LIndex := 0 to High(LList) do
    if SameText(LList[LIndex], LCurrent) then
      LPosition := LIndex;
  LNext := LList[(LPosition + ADirection + Length(LList)) mod Length(LList)];
  LIndex := IndexOfFont(FontIdOf(AFont));
  if LNext = '' then
  begin
    RemoveFont(FontIdOf(AFont));
    Exit;
  end;
  if LIndex >= 0 then
  begin
    // the other keys of the entry stay; a file is replaced by the family
    LEntry := FPending[LIndex];
    LEntry.Face.Name := LNext;
    LEntry.Face.FileName := '';
    RemoveFont(FontIdOf(AFont));
  end
  else
    LEntry := NewEntry(AFont, LNext);
  FPending := FPending + [LEntry];
end;

procedure TXcomFontChoices.StepSize(AFont, ADirection: Integer);
var
  LIndex: Integer;
begin
  LIndex := IndexOfFont(FontIdOf(AFont));
  if LIndex < 0 then
    Exit;
  Inc(FPending[LIndex].Face.Size, ADirection);
  if FPending[LIndex].Face.Size > LARGEST_SIZE then
    FPending[LIndex].Face.Size := XCOM_FONT_SMALLEST_SIZE
  else if FPending[LIndex].Face.Size < XCOM_FONT_SMALLEST_SIZE then
    FPending[LIndex].Face.Size := LARGEST_SIZE;
end;

function TXcomFontChoices.Heading: string;
begin
  Result := SHeading;
end;

function TXcomFontChoices.Count: Integer;
begin
  if FLocked then
    Result := 1
  else
    Result := FONT_COUNT * FIELD_COUNT;
end;

function TXcomFontChoices.Title(AIndex: Integer): string;
var
  LFont: Integer;
  LIndex: Integer;
  LName: string;
  LFace: string;
begin
  if FLocked then
    Exit(SLocked);
  LFont := AIndex div FIELD_COUNT;
  LName := FontTitleOf(LFont);
  LIndex := IndexOfFont(FontIdOf(LFont));
  case AIndex mod FIELD_COUNT of
    FIELD_FACE:
      begin
        LFace := SOriginal;
        if LIndex >= 0 then
        begin
          LFace := CurrentFace(FPending[LIndex]);
          if FPending[LIndex].Face.Name = '' then
            LFace := ExtractFileName(LFace);
        end;
        Result := Format(SFaceTitle, [LName, LFace]);
      end;
    FIELD_SIZE:
      if LIndex >= 0 then
        Result := Format(SSizeTitle, [LName, IntToStr(FPending[LIndex].Face.Size)])
      else
        Result := Format(SSizeTitle, [LName, SNoValue]);
    FIELD_BOLD:
      Result := Format(SBoldTitle, [LName]);
    FIELD_SMOOTH:
      Result := Format(SSmoothTitle, [LName]);
  else
    Result := Format(SShrinkTitle, [LName]);
  end;
end;

function TXcomFontChoices.Description(AIndex: Integer): string;
var
  LName: string;
begin
  if FLocked then
    Exit(SLockedDescription);
  LName := FontTitleOf(AIndex div FIELD_COUNT).ToLower;
  case AIndex mod FIELD_COUNT of
    FIELD_FACE:
      Result := Format(SFaceDescription, [LName]);
    FIELD_SIZE:
      Result := Format(SSizeDescription, [LName]);
    FIELD_BOLD:
      Result := Format(SBoldDescription, [LName]);
    FIELD_SMOOTH:
      Result := Format(SSmoothDescription, [LName]);
  else
    Result := Format(SShrinkDescription, [LName]);
  end;
end;

function TXcomFontChoices.Kind(AIndex: Integer): TXcomExtraKind;
begin
  if FLocked then
    Exit(ekInfo);
  case AIndex mod FIELD_COUNT of
    FIELD_FACE:
      Result := ekChoice;
    FIELD_SIZE:
      if IndexOfFont(FontIdOf(AIndex div FIELD_COUNT)) >= 0 then
        Result := ekChoice
      else
        Result := ekInfo;
  else
    // bold, smooth edges and shrink mean something only for a font of the system
    if IndexOfFont(FontIdOf(AIndex div FIELD_COUNT)) >= 0 then
      Result := ekToggle
    else
      Result := ekInfo;
  end;
end;

function TXcomFontChoices.IsOn(AIndex: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  if FLocked then
    Exit;
  LIndex := IndexOfFont(FontIdOf(AIndex div FIELD_COUNT));
  if LIndex < 0 then
    Exit;
  case AIndex mod FIELD_COUNT of
    FIELD_BOLD:
      Result := FPending[LIndex].Face.Bold;
    FIELD_SMOOTH:
      Result := FPending[LIndex].Face.Antialias;
    FIELD_SHRINK:
      Result := FPending[LIndex].Shrink;
  end;
end;

procedure TXcomFontChoices.SetOn(AIndex: Integer; AValue: Boolean);
var
  LIndex: Integer;
begin
  if FLocked then
    Exit;
  LIndex := IndexOfFont(FontIdOf(AIndex div FIELD_COUNT));
  if LIndex < 0 then
    Exit;
  case AIndex mod FIELD_COUNT of
    FIELD_BOLD:
      FPending[LIndex].Face.Bold := AValue;
    FIELD_SMOOTH:
      FPending[LIndex].Face.Antialias := AValue;
    FIELD_SHRINK:
      FPending[LIndex].Shrink := AValue;
  end;
end;

procedure TXcomFontChoices.Step(AIndex, ADirection: Integer);
begin
  if FLocked then
    Exit;
  case AIndex mod FIELD_COUNT of
    FIELD_FACE:
      StepFace(AIndex div FIELD_COUNT, ADirection);
    FIELD_SIZE:
      StepSize(AIndex div FIELD_COUNT, ADirection);
  end;
end;

procedure TXcomFontChoices.Discard;
begin
  FPending := Copy(FStored);
end;

function TXcomFontChoices.Settings: TArray<TXcomFontOverlaySettings>;
begin
  if FLocked then
    Result := FStored
  else
    Result := FPending;
end;

procedure TXcomFontChoices.Commit;
var
  LText: string;
begin
  if FLocked then
    Exit;
  FStored := Copy(FPending);
  LText := TXcomFontSettingsWriter.Write(FStored);
  if LText = FStoredText then
    Exit;
  FStoredText := LText;
  if FPath <> '' then
    TXcomAtomicFileWriter.Write(FFiles, FPath, TEncoding.UTF8.GetBytes(LText));
end;

end.
