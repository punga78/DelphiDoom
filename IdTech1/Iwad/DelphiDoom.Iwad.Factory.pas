{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the factory: the composition root                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Factory;

interface

uses
  DelphiDoom.Iwad.Intf, DelphiDoom.Iwad.Games;

type
  /// <summary>The only place that knows the classes behind the IWAD contracts</summary>
  TIwadFactory = class
  public
    /// <summary>
    ///   The locator of a game: the folders of the variables, the lists of folders, the
    ///   additional paths and Steam, in this order
    /// </summary>
    class function CreateLocator(const AProfile: IIwadProfile;
      const AEnvironment: IIwadEnvironment; const AFileSystem: IIwadFileSystem;
      const ASteam: IIwadSteam; const AOptions: IIwadOptions): IIwadLocator; static;
    class function CreateIdentifier(const AProfile: IIwadProfile; const ALocator: IIwadLocator;
      const AFileSystem: IIwadFileSystem; const AEnvironment: IIwadEnvironment;
      const AOptions: IIwadOptions): IIwadIdentifier; static;
    /// <summary>Locator and identifier of a game on the disk, the environment and the registry of Windows</summary>
    class function CreateWindowsServices(AGame: TIwadGame;
      const AOptions: IIwadOptions): TIwadServices; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Iwad.EnvironmentDirectories, DelphiDoom.Iwad.EnvironmentPathLists,
  DelphiDoom.Iwad.AdditionalPaths, DelphiDoom.Iwad.SteamPaths, DelphiDoom.Iwad.Locator,
  DelphiDoom.Iwad.Identifier, DelphiDoom.Iwad.WindowsEnvironment,
  DelphiDoom.Iwad.DiskFileSystem, DelphiDoom.Iwad.SteamRegistry;

{ TIwadFactory }

class function TIwadFactory.CreateLocator(const AProfile: IIwadProfile;
  const AEnvironment: IIwadEnvironment; const AFileSystem: IIwadFileSystem;
  const ASteam: IIwadSteam; const AOptions: IIwadOptions): IIwadLocator;
begin
  if not Assigned(AProfile) then
    raise EArgumentNilException.Create('AProfile');
  Result := TIwadLocator.Create(AFileSystem,
    TArray<IIwadSearchPath>.Create(
      TIwadEnvironmentDirectories.Create(AEnvironment, AOptions, AProfile.DirectoryVariables),
      TIwadEnvironmentPathLists.Create(AEnvironment, AOptions, AProfile.PathVariables),
      TIwadAdditionalPaths.Create(AOptions),
      TIwadSteamPaths.Create(ASteam, AOptions, AProfile.SteamApplications)));
end;

class function TIwadFactory.CreateIdentifier(const AProfile: IIwadProfile;
  const ALocator: IIwadLocator; const AFileSystem: IIwadFileSystem;
  const AEnvironment: IIwadEnvironment; const AOptions: IIwadOptions): IIwadIdentifier;
begin
  Result := TIwadIdentifier.Create(AProfile, ALocator, AFileSystem, AEnvironment, AOptions);
end;

class function TIwadFactory.CreateWindowsServices(AGame: TIwadGame;
  const AOptions: IIwadOptions): TIwadServices;
var
  LProfile: IIwadProfile;
  LEnvironment: IIwadEnvironment;
  LFileSystem: IIwadFileSystem;
begin
  LProfile := TIwadGames.CreateProfile(AGame);
  LEnvironment := TIwadWindowsEnvironment.Create;
  LFileSystem := TIwadDiskFileSystem.Create;
  Result.Locator := CreateLocator(LProfile, LEnvironment, LFileSystem,
    TIwadSteamRegistry.Create, AOptions);
  Result.Identifier := CreateIdentifier(LProfile, Result.Locator, LFileSystem, LEnvironment,
    AOptions);
end;

end.
