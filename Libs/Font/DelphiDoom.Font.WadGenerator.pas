{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the WAD of a font                                 }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.WadGenerator;

interface

uses
  System.SysUtils,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf;

type
  /// <summary>
  ///   DoGenerateWAD of DD_FONT: the lump DDFONT with the settings, then a patch for each text. The WAD is the
  ///   one of the WAD library (data aligned to 4 bytes, the directory at the end); the old tool put the
  ///   directory right after the header and did not align: the lumps are the same, their places are not
  /// </summary>
  TFontWadGenerator = class(TInterfacedObject, IFontWadGenerator)
  strict private
    FExporter: IFontExporter;
    FBuilder: IWadBuilder;
    procedure AddPatch(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
      const AName, AText: string; const ARequest: TFontGenerationRequest);
  public
    /// <param name="ABuilder">The builder that the WAD is made with; it is emptied by every call to Generate</param>
    constructor Create(const AExporter: IFontExporter; const ABuilder: IWadBuilder);
    function Generate(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
      const ARequest: TFontGenerationRequest): TBytes;
  end;

implementation

uses
  DelphiDoom.Font.SettingsFormat, DelphiDoom.Font.LumpNames;

{ TFontWadGenerator }

constructor TFontWadGenerator.Create(const AExporter: IFontExporter; const ABuilder: IWadBuilder);
begin
  inherited Create;
  if not Assigned(AExporter) then
    raise EArgumentNilException.Create('AExporter');
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  FExporter := AExporter;
  FBuilder := ABuilder;
end;

procedure TFontWadGenerator.AddPatch(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
  const AName, AText: string; const ARequest: TFontGenerationRequest);
begin
  FBuilder.AddLump(AName, FExporter.ExportText(ASettings, APalette, AText,
    TFontExportOptions.Create(ARequest.FixedPitch, ARequest.PerlinNoise, False, FONT_WAD_OFFSET_X,
      FONT_WAD_OFFSET_Y)));
end;

function TFontWadGenerator.Generate(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
  const ARequest: TFontGenerationRequest): TBytes;
var
  LCode: Integer;
  LDigit: Char;
  LName: string;
begin
  if not APalette.IsValid then
    raise EFontException.Create(SFontBadPalette);
  if ARequest.Kind = fskText then
  begin
    LName := TFontLumpNames.ForText(ARequest.Text);
    if LName = '' then
      raise EFontException.Create(SFontNothingToExport);
  end;

  FBuilder.Clear;
  FBuilder.AddLump(FONT_SETTINGS_LUMP_NAME, TFontSettingsFormat.Save(ASettings));
  case ARequest.Kind of
    fskText:
      AddPatch(ASettings, APalette, LName, ARequest.Text, ARequest);
    fskCharacters:
      for LCode := FONT_SEQUENCE_FIRST to FONT_SEQUENCE_LAST do
        AddPatch(ASettings, APalette, TFontLumpNames.ForCharacter(ARequest.Prefix, LCode), Char(LCode), ARequest);
    fskDigits:
      for LDigit := '0' to '9' do
        AddPatch(ASettings, APalette, TFontLumpNames.ForDigit(ARequest.Prefix, LDigit), LDigit, ARequest);
  end;
  Result := FBuilder.ToBytes;
end;

end.
