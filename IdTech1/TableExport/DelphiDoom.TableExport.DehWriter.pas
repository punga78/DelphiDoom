{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the tables as a patch                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.DehWriter;

interface

uses
  System.Generics.Collections, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.Profile;

type
  /// <summary>
  ///   Writes the current things, states, weapons, ammo and the rest as the text of a
  ///   patch (the old DEH_CurrentSettings). The fields and their order come from the profile
  /// </summary>
  TExportDehWriter = class(TInterfacedObject, IExportDehWriter)
  strict private
    FProfile: TExportProfile;
    FThings: IExportThingSource;
    FStates: IExportStateSource;
    FWeapons: IExportWeaponSource;
    FSettings: IExportSettingsSource;
    FFlags: IExportFlagNames;
    FLookups: IExportLookups;
    function FormatLine(const ALine: TExportLine; ANumber: Integer; const AText: string;
      const AThing: TExportThing): string; overload;
    function FormatLine(const ALine: TExportLine; ANumber: Integer; const AText: string): string; overload;
    procedure AddHeader(const ALines: TList<string>);
    procedure AddThings(const ALines: TList<string>);
    procedure AddStates(const ALines: TList<string>);
    procedure AddWeapons(const ALines: TList<string>);
    procedure AddAmmo(const ALines: TList<string>);
    procedure AddMisc(const ALines: TList<string>);
    procedure AddPars(const ALines: TList<string>);
    procedure AddStrings(const ALines: TList<string>);
    procedure AddMusic(const ALines: TList<string>);
    procedure AddSounds(const ALines: TList<string>);
  public
    /// <exception cref="EArgumentNilException">A source is nil</exception>
    constructor Create(const AProfile: TExportProfile; const AThings: IExportThingSource;
      const AStates: IExportStateSource; const AWeapons: IExportWeaponSource;
      const ASettings: IExportSettingsSource; const AFlags: IExportFlagNames;
      const ALookups: IExportLookups);
    function Write: TArray<string>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Text;

{ TExportDehWriter }

constructor TExportDehWriter.Create(const AProfile: TExportProfile; const AThings: IExportThingSource;
  const AStates: IExportStateSource; const AWeapons: IExportWeaponSource;
  const ASettings: IExportSettingsSource; const AFlags: IExportFlagNames;
  const ALookups: IExportLookups);
begin
  inherited Create;
  if not Assigned(AThings) then
    raise EArgumentNilException.Create('AThings');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AWeapons) then
    raise EArgumentNilException.Create('AWeapons');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(AFlags) then
    raise EArgumentNilException.Create('AFlags');
  if not Assigned(ALookups) then
    raise EArgumentNilException.Create('ALookups');
  FProfile := AProfile;
  FThings := AThings;
  FStates := AStates;
  FWeapons := AWeapons;
  FSettings := ASettings;
  FFlags := AFlags;
  FLookups := ALookups;
end;

function TExportDehWriter.FormatLine(const ALine: TExportLine; ANumber: Integer;
  const AText: string): string;
var
  LLabel: string;
  LFlagText: string;
begin
  LLabel := TExportText.Capitalize(ALine.Token);
  case ALine.Kind of
    lkNumber, lkLevel:
      Result := Format('%s = %d', [LLabel, ANumber]);
    lkFlags:
      begin
        LFlagText := TExportText.FlagList(ANumber, FFlags.Names(ALine.FlagSet), ', ');
        if LFlagText = '' then
          Result := Format('%s = 0', [LLabel])
        else
          Result := Format('%s = %s', [LLabel, LFlagText]);
      end;
    lkName:
      Result := Format('%s = %s', [LLabel, AText]);
    lkQuoted:
      Result := Format('%s = "%s"', [LLabel, AText]);
    lkRenderStyle:
      Result := Format('%s = %s', [LLabel, FLookups.RenderStyleToken(ANumber)]);
    lkGender:
      Result := Format('%s = %s', [LLabel, FLookups.GenderToken(ANumber)]);
    lkGroup:
      Result := Format('%s = %s', [LLabel, FLookups.GroupName(ALine.Group, ANumber)]);
    lkAmmo:
      Result := Format('%s = %s', [LLabel, FLookups.AmmoToken(ANumber)]);
  else
    Result := '';
  end;
end;

function TExportDehWriter.FormatLine(const ALine: TExportLine; ANumber: Integer;
  const AText: string; const AThing: TExportThing): string;
begin
  if ALine.Kind in [lkName, lkQuoted] then
    Result := FormatLine(ALine, 0, AThing.Texts[TExportThingText(ALine.Index)])
  else
    Result := FormatLine(ALine, AThing.Numbers[TExportThingField(ALine.Index)], AText);
end;

procedure TExportDehWriter.AddHeader(const ALines: TList<string>);
begin
  ALines.Add('Patch File for DeHackEd');
  ALines.Add('# Created with ' + FSettings.CreatedWith);
  ALines.Add('# Command line options:');
  ALines.Add('# ' + FSettings.CommandLine + #13#10);
  ALines.Add('');
  ALines.Add('# Note: Use the ''#'' or ''//'' (DelphiDoom specific) sign to start comment lines.');
  ALines.Add('');
  ALines.Add('# General version information');
  ALines.Add('Doom version = 21');
  ALines.Add('Patch format = 6');
  ALines.Add('');
end;

procedure TExportDehWriter.AddThings(const ALines: TList<string>);
var
  LIndex: Integer;
  LLine: TExportLine;
  LThing: TExportThing;
begin
  ALines.Add('');
  ALines.Add('# Things');
  ALines.Add('');
  for LIndex := 0 to FThings.Count - 1 do
  begin
    LThing := FThings.Get(LIndex);
    ALines.Add(Format('Thing %d', [LIndex + 1]));
    for LLine in FProfile.ThingLines do
      if LLine.Kind = lkComment then
      begin
        if LIndex = 0 then
        begin
          ALines.Add('');
          ALines.Add(LLine.Token);
        end;
      end
      else
        ALines.Add(FormatLine(LLine, 0, '', LThing));
    ALines.Add('');
  end;
end;

procedure TExportDehWriter.AddStates(const ALines: TList<string>);
var
  LIndex: Integer;
  LLine: TExportLine;
  LState: TExportState;
  LAction: string;
begin
  ALines.Add('');
  ALines.Add('# States');
  ALines.Add('');
  // The state 0 is S_NULL
  for LIndex := 1 to FStates.Count - 1 do
  begin
    LState := FStates.Get(LIndex);
    if LIndex < FStates.NameCount then
      ALines.Add('# ' + FStates.StateName(LIndex));
    ALines.Add(Format('Frame %d', [LIndex]));
    for LLine in FProfile.StateLines do
      case LLine.Kind of
        lkComment:
          if LIndex = 1 then
            ALines.Add(LLine.Token);
        lkAction:
          if LState.ActionName <> '' then
          begin
            LAction := LState.ActionName;
            if LState.HasParams then
              LAction := LAction + ' ' + LState.Params;
            ALines.Add(Format('%s = %s', [TExportText.Capitalize(LLine.Token), LAction]));
          end;
      else
        ALines.Add(FormatLine(LLine, LState.Numbers[TExportStateField(LLine.Index)], ''));
      end;
    ALines.Add('');
  end;
end;

procedure TExportDehWriter.AddWeapons(const ALines: TList<string>);
var
  LIndex: Integer;
  LLine: TExportLine;
  LWeapon: TExportWeapon;
  LHeader: string;
begin
  ALines.Add('');
  ALines.Add('# Weapons');
  ALines.Add('');
  for LIndex := 0 to FWeapons.Count - 1 do
  begin
    LWeapon := FWeapons.Get(LIndex);
    LHeader := 'Weapon ' + FLookups.WeaponToken(LWeapon.WeaponNo);
    if FProfile.WeaponHeaderHasClass then
      LHeader := LHeader + ' ' + FLookups.PlayerClassToken(LWeapon.PlayerClass);
    ALines.Add(LHeader);
    for LLine in FProfile.WeaponLines do
      if LLine.Kind = lkLevel then
        ALines.Add(FormatLine(LLine, LWeapon.Level, ''))
      else
        ALines.Add(FormatLine(LLine, LWeapon.Numbers[TExportWeaponField(LLine.Index)], ''));
    ALines.Add('');
  end;
end;

procedure TExportDehWriter.AddAmmo(const ALines: TList<string>);
var
  LIndex: Integer;
  LLine: TExportLine;
begin
  if Length(FProfile.AmmoLines) = 0 then
    Exit;
  ALines.Add('');
  ALines.Add('# Ammo');
  ALines.Add('');
  for LIndex := 0 to FSettings.AmmoCount - 1 do
  begin
    ALines.Add(Format('Ammo %d', [LIndex]));
    for LLine in FProfile.AmmoLines do
      ALines.Add(FormatLine(LLine, FSettings.Ammo(LIndex, LLine.Index), ''));
    ALines.Add('');
  end;
end;

procedure TExportDehWriter.AddMisc(const ALines: TList<string>);
var
  LLine: TExportLine;
begin
  ALines.Add('');
  ALines.Add('# Misc, health and armor bonus');
  ALines.Add('');
  ALines.Add('Misc');
  ALines.Add('');
  for LLine in FProfile.MiscLines do
    ALines.Add(FormatLine(LLine, FSettings.Misc(LLine.Index), ''));
  ALines.Add('');
end;

procedure TExportDehWriter.AddPars(const ALines: TList<string>);
var
  LEpisode: Integer;
  LMap: Integer;
begin
  if FProfile.ParEpisodes = 0 then
    Exit;
  ALines.Add('');
  ALines.Add('# Par times');
  ALines.Add('');
  ALines.Add('[PARS]');
  ALines.Add(FProfile.ParEpisodeHeader);
  for LEpisode := 1 to FProfile.ParEpisodes do
    for LMap := 1 to FProfile.ParMaps do
      ALines.Add(Format('PAR %d %d %d', [LEpisode, LMap, FSettings.Par(LEpisode, LMap)]));
  if FProfile.ParCommercialMaps > 0 then
  begin
    ALines.Add('# Doom 2 (commercial)');
    for LMap := 0 to FProfile.ParCommercialMaps - 1 do
      ALines.Add(Format('PAR %d %d', [LMap + 1, FSettings.CommercialPar(LMap)]));
  end;
  ALines.Add('');
end;

procedure TExportDehWriter.AddStrings(const ALines: TList<string>);
var
  LIndex: Integer;
begin
  ALines.Add('');
  ALines.Add('# Strings');
  ALines.Add('');
  ALines.Add('[Strings]');
  for LIndex := 0 to FSettings.StringCount - 1 do
    ALines.Add(Format('%s = %s', [FSettings.StringName(LIndex),
      TExportText.ToCString(FSettings.StringValue(LIndex))]));
  ALines.Add('');
end;

procedure TExportDehWriter.AddMusic(const ALines: TList<string>);
var
  LIndex: Integer;
  LName: string;
begin
  ALines.Add('');
  ALines.Add('# Music');
  ALines.Add('');
  ALines.Add('[MUSIC]');
  for LIndex := 1 to FSettings.MusicCount - 1 do
  begin
    LName := FSettings.MusicName(LIndex);
    if FSettings.MusicMapName(LIndex) <> '' then
      ALines.Add(Format('%d = %s %s(Map: %s)', [LIndex, LName, StringOfChar(' ', 6 - Length(LName)),
        FSettings.MusicMapName(LIndex)]))
    else
      ALines.Add(Format('%d = %s', [LIndex, LName]));
  end;
  ALines.Add('');
end;

procedure TExportDehWriter.AddSounds(const ALines: TList<string>);
var
  LIndex: Integer;
begin
  ALines.Add('');
  ALines.Add('# Sounds');
  ALines.Add('');
  ALines.Add('[SOUND]');
  for LIndex := 1 to FSettings.SoundCount - 1 do
    ALines.Add(Format('%d = %s', [LIndex, FSettings.SoundName(LIndex)]));
  ALines.Add('');
end;

function TExportDehWriter.Write: TArray<string>;
var
  LLines: TList<string>;
begin
  LLines := TList<string>.Create;
  try
    AddHeader(LLines);
    AddThings(LLines);
    AddStates(LLines);
    AddWeapons(LLines);
    AddAmmo(LLines);
    AddMisc(LLines);
    AddPars(LLines);
    AddStrings(LLines);
    AddMusic(LLines);
    AddSounds(LLines);
    LLines.Add(StringOfChar('#', 80));
    LLines.Add('# End of file');
    LLines.Add(StringOfChar('#', 80));
    Result := LLines.ToArray;
  finally
    LLines.Free;
  end;
end;

end.
