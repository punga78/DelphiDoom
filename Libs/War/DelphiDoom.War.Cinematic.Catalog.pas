{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the list of the animations of the game            }
{                                                                              }
{  The names and the loops are the ones of cinematics.txt of war1 (acoto87/     }
{  war1), (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\        }
{  LICENSE-war1.txt). This is an altered version, not the original.             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Cinematic.Catalog;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Cinematic.Types, DelphiDoom.War.Cinematic.Intf;

type
  /// <summary>
  ///   The 39 animations. The sound is a project decision, not a fact of the original: the remake plays no
  ///   animation, and the files say which voice goes with which scene only by their names. Here a sound is
  ///   given only where the name leaves no doubt (the door of the cave opens: the sound of the door; the endings
  ///   of the humans and of the orcs; victory and defeat; the title: "Welcome to the World of Warcraft"). The
  ///   other four narrations of the introduction (WAR_INTRO_1 to 4) are not assigned until someone has listened
  ///   to the DOS game
  /// </summary>
  TWarCinematicCatalog = class(TInterfacedObject, IWarCinematicCatalog)
  strict private
    FEntries: TArray<TWarCinematicEntry>;
    procedure Add(const AName: string; ALooping: Boolean; ASoundKind: TWarCinematicSoundKind; ASound: Integer);
    procedure AddEvent(const AName: string; ALooping: Boolean; AEvent: Integer; ARace: TWarRace);
    procedure AddMapIntros(const APrefix: string);
  public
    constructor Create;
    function Count: Integer;
    function Item(AIndex: Integer): TWarCinematicEntry;
    function TryFind(const AName: string; out AEntry: TWarCinematicEntry): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Sound.Types, DelphiDoom.War.Sound.Ids;

{ TWarCinematicCatalog }

constructor TWarCinematicCatalog.Create;
begin
  inherited Create;
  Add('CAVE1', False, wcsNone, 0);
  Add('CAVE2', True, wcsNone, 0);
  Add('CAVE3', False, wcsFixed, WAR_SND_INTRO_DOOR);
  Add('HFINALE', False, wcsFixed, WAR_SND_CAMPAIGNS_HUMAN_ENDING_FIRST);
  Add('HINTRO1', False, wcsNone, 0);
  Add('HINTRO2', True, wcsNone, 0);
  AddMapIntros('HMAP');
  AddEvent('LOSE1', False, Ord(wseDefeat), wraNeutral);
  AddEvent('LOSE2', True, Ord(wseDefeat), wraNeutral);
  Add('OFINALE', True, wcsFixed, WAR_SND_CAMPAIGNS_ORC_ENDING_FIRST);
  Add('OINTRO1', False, wcsNone, 0);
  Add('OINTRO2', True, wcsNone, 0);
  Add('OINTRO3', False, wcsNone, 0);
  AddMapIntros('OMAP');
  Add('TITLE', False, wcsFixed, WAR_SND_INTRO_LAST);
  AddEvent('WIN1', False, Ord(wseVictory), wraNeutral);
  AddEvent('WIN2', True, Ord(wseVictory), wraNeutral);
end;

procedure TWarCinematicCatalog.Add(const AName: string; ALooping: Boolean; ASoundKind: TWarCinematicSoundKind;
  ASound: Integer);
var
  LEntry: TWarCinematicEntry;
begin
  LEntry := Default(TWarCinematicEntry);
  LEntry.Name := AName;
  LEntry.Looping := ALooping;
  LEntry.SoundKind := ASoundKind;
  LEntry.Sound := ASound;
  SetLength(FEntries, Length(FEntries) + 1);
  FEntries[High(FEntries)] := LEntry;
end;

procedure TWarCinematicCatalog.AddEvent(const AName: string; ALooping: Boolean; AEvent: Integer; ARace: TWarRace);
begin
  Add(AName, ALooping, wcsEvent, 0);
  FEntries[High(FEntries)].SoundEvent := TWarSoundEvent(AEvent);
  FEntries[High(FEntries)].SoundRace := ARace;
end;

procedure TWarCinematicCatalog.AddMapIntros(const APrefix: string);
var
  LMission: Integer;
begin
  for LMission := 1 to 12 do
    Add(Format('%s%.2d', [APrefix, LMission]), False, wcsNone, 0);
end;

function TWarCinematicCatalog.Count: Integer;
begin
  Result := Length(FEntries);
end;

function TWarCinematicCatalog.Item(AIndex: Integer): TWarCinematicEntry;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    raise EWarException.CreateFmt('The animation %d is not in the catalog', [AIndex]);
  Result := FEntries[AIndex];
end;

function TWarCinematicCatalog.TryFind(const AName: string; out AEntry: TWarCinematicEntry): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FEntries) do
    if SameText(FEntries[LIndex].Name, AName) then
    begin
      AEntry := FEntries[LIndex];
      Exit(True);
    end;
  AEntry := Default(TWarCinematicEntry);
  Result := False;
end;

end.
