{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the identification of the IWAD                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Identifier;

interface

uses
  DelphiDoom.Iwad.Types, DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   Port of the choice that IdentifyVersion made in the four games: the file that the
  ///   player named, or the first IWAD of the profile that is there. It only decides; the
  ///   engine turns the answer into its globals and adds the files
  /// </summary>
  TIwadIdentifier = class(TInterfacedObject, IIwadIdentifier)
  strict private
    FProfile: IIwadProfile;
    FLocator: IIwadLocator;
    FFileSystem: IIwadFileSystem;
    FEnvironment: IIwadEnvironment;
    FOptions: IIwadOptions;
    function DirectPrefix: string;
    function Describe(const AEntry: TIwadEntry; const APath: string): TIwadIdentification;
    class function NotFound: TIwadIdentification; static;
  public
    constructor Create(const AProfile: IIwadProfile; const ALocator: IIwadLocator;
      const AFileSystem: IIwadFileSystem; const AEnvironment: IIwadEnvironment;
      const AOptions: IIwadOptions);
    function TryIdentifyCustom(const AName: string;
      out AIdentification: TIwadIdentification): Boolean;
    function IdentifyKnown: TIwadIdentification;
  end;

implementation

uses
  System.SysUtils;

{ TIwadIdentifier }

constructor TIwadIdentifier.Create(const AProfile: IIwadProfile; const ALocator: IIwadLocator;
  const AFileSystem: IIwadFileSystem; const AEnvironment: IIwadEnvironment;
  const AOptions: IIwadOptions);
begin
  inherited Create;
  if not Assigned(AProfile) then
    raise EArgumentNilException.Create('AProfile');
  if not Assigned(ALocator) then
    raise EArgumentNilException.Create('ALocator');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(AEnvironment) then
    raise EArgumentNilException.Create('AEnvironment');
  if not Assigned(AOptions) then
    raise EArgumentNilException.Create('AOptions');
  FProfile := AProfile;
  FLocator := ALocator;
  FFileSystem := AFileSystem;
  FEnvironment := AEnvironment;
  FOptions := AOptions;
end;

class function TIwadIdentifier.NotFound: TIwadIdentification;
begin
  Result := Default(TIwadIdentification);
  Result.Mode := igmIndetermined;
  Result.Mission := imsUnchanged;
end;

function TIwadIdentifier.DirectPrefix: string;
begin
  Result := '';
  if FOptions.SearchWadDirectory then
    Result := FEnvironment.GetValue(FProfile.DirectPhaseVariable);
  if Result = '' then
    Result := '.';
end;

function TIwadIdentifier.Describe(const AEntry: TIwadEntry;
  const APath: string): TIwadIdentification;
var
  LVoices: string;
begin
  Result := Default(TIwadIdentification);
  Result.Found := True;
  Result.Files := TArray<string>.Create(APath);
  Result.Mode := AEntry.Mode;
  Result.Mission := AEntry.Mission;
  Result.IsFrench := AEntry.IsFrench;
  Result.IsBfg2 := AEntry.IsBfg2;
  if AEntry.CompanionFileName <> '' then
  begin
    LVoices := FLocator.Locate(AEntry.CompanionFileName);
    if FFileSystem.FileExists(LVoices) then
      Result.VoicesPath := LVoices;
  end;
end;

function TIwadIdentifier.IdentifyKnown: TIwadIdentification;
var
  LEntries: TArray<TIwadEntry>;
  LEntry: TIwadEntry;
  LPrefix: string;
  LPath: string;
begin
  LEntries := FProfile.Entries;
  if FProfile.DirectPhaseVariable <> '' then
  begin
    // first the names as they are written in the folder of the variable...
    LPrefix := DirectPrefix;
    for LEntry in LEntries do
    begin
      LPath := LPrefix + '\' + LEntry.FileName;
      if FFileSystem.FileExists(LPath) then
        Exit(Describe(LEntry, LPath));
    end;
    // ...then the search paths
    for LEntry in LEntries do
    begin
      if LEntry.Searchable then
      begin
        LPath := FLocator.Locate(LPrefix + '\' + LEntry.FileName);
        if FFileSystem.FileExists(LPath) then
          Exit(Describe(LEntry, LPath));
      end;
    end;
  end
  else
  begin
    for LEntry in LEntries do
    begin
      if LEntry.Searchable then
        LPath := FLocator.Locate(LEntry.FileName)
      else
        LPath := LEntry.FileName;
      if FFileSystem.FileExists(LPath) then
        Exit(Describe(LEntry, LPath));
    end;
  end;
  Result := NotFound;
end;

function TIwadIdentifier.TryIdentifyCustom(const AName: string;
  out AIdentification: TIwadIdentification): Boolean;
var
  LPath: string;
  LShortName: string;
  LRule: TIwadCustomRule;
  LVoices: string;
begin
  AIdentification := NotFound;
  if AName = '' then
    Exit(False);
  LPath := FLocator.Locate(AName);
  LShortName := UpperCase(ExtractFileName(LPath));

  // an add-on needs its main IWAD, and it is accepted even if its own file is not there
  for LRule in FProfile.CustomRules do
  begin
    if (LRule.Kind = icrPrerequisite) and (LRule.Trigger = LShortName) then
    begin
      AIdentification.Found := True;
      AIdentification.Custom := True;
      AIdentification.CustomPath := LPath;
      AIdentification.Files := TArray<string>.Create(FLocator.Locate(LRule.FileName), LPath);
      AIdentification.Mode := igmUnchanged;
      Exit(True);
    end;
  end;

  if not FFileSystem.FileExists(LPath) then
    Exit(False);

  AIdentification.Found := True;
  AIdentification.Custom := True;
  AIdentification.CustomPath := LPath;
  AIdentification.Files := TArray<string>.Create(LPath);
  AIdentification.Mode := igmIndetermined;
  for LRule in FProfile.CustomRules do
  begin
    if (LRule.Kind = icrCompanion) and (LRule.Trigger = LShortName) then
    begin
      LVoices := FLocator.Locate(ExtractFilePath(FFileSystem.ExpandPath(LPath)) + LRule.FileName);
      if FFileSystem.FileExists(LVoices) then
        AIdentification.VoicesPath := LVoices;
    end;
  end;
  Result := True;
end;

end.
