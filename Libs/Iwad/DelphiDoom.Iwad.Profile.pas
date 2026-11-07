{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the profile of a game                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Profile;

interface

uses
  DelphiDoom.Iwad.Types, DelphiDoom.Iwad.Intf;

type
  /// <summary>The data of a game: a plain holder, what differs between the games is only data</summary>
  TIwadProfile = class(TInterfacedObject, IIwadProfile)
  strict private
    FGameName: string;
    FEntries: TArray<TIwadEntry>;
    FCustomRules: TArray<TIwadCustomRule>;
    FDirectoryVariables: TArray<string>;
    FPathVariables: TArray<string>;
    FSteamApplications: TArray<Integer>;
    FDirectPhaseVariable: string;
  public
    /// <exception cref="EIwadException">The game has no IWAD at all</exception>
    constructor Create(const AGameName: string; const AEntries: TArray<TIwadEntry>;
      const ACustomRules: TArray<TIwadCustomRule>; const ADirectoryVariables,
      APathVariables: TArray<string>; const ASteamApplications: TArray<Integer>;
      const ADirectPhaseVariable: string);
    function GetGameName: string;
    function GetEntries: TArray<TIwadEntry>;
    function GetCustomRules: TArray<TIwadCustomRule>;
    function GetDirectoryVariables: TArray<string>;
    function GetPathVariables: TArray<string>;
    function GetSteamApplications: TArray<Integer>;
    function GetDirectPhaseVariable: string;
  end;

implementation

uses
  System.SysUtils;

const
  SNoEntries = 'The profile of the game %s has no IWAD';

{ TIwadProfile }

constructor TIwadProfile.Create(const AGameName: string; const AEntries: TArray<TIwadEntry>;
  const ACustomRules: TArray<TIwadCustomRule>; const ADirectoryVariables,
  APathVariables: TArray<string>; const ASteamApplications: TArray<Integer>;
  const ADirectPhaseVariable: string);
begin
  inherited Create;
  if Length(AEntries) = 0 then
    raise EIwadException.CreateFmt(SNoEntries, [AGameName]);
  FGameName := AGameName;
  FEntries := AEntries;
  FCustomRules := ACustomRules;
  FDirectoryVariables := ADirectoryVariables;
  FPathVariables := APathVariables;
  FSteamApplications := ASteamApplications;
  FDirectPhaseVariable := ADirectPhaseVariable;
end;

function TIwadProfile.GetGameName: string;
begin
  Result := FGameName;
end;

function TIwadProfile.GetEntries: TArray<TIwadEntry>;
begin
  Result := FEntries;
end;

function TIwadProfile.GetCustomRules: TArray<TIwadCustomRule>;
begin
  Result := FCustomRules;
end;

function TIwadProfile.GetDirectoryVariables: TArray<string>;
begin
  Result := FDirectoryVariables;
end;

function TIwadProfile.GetPathVariables: TArray<string>;
begin
  Result := FPathVariables;
end;

function TIwadProfile.GetSteamApplications: TArray<Integer>;
begin
  Result := FSteamApplications;
end;

function TIwadProfile.GetDirectPhaseVariable: string;
begin
  Result := FDirectPhaseVariable;
end;

end.
