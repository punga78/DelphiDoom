{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sounds of the map in the model                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_audio.c (wa_createAudio,                    }
{  wa_createAudioRandom, wa_playDudeSelectionSound,                             }
{  wa_playBuildingSelectionSound, wa_playAcknowledgementSound), (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).      }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Audio;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Sound.Intf, DelphiDoom.War.Model.Context, DelphiDoom.War.MapUi.Intf;

type
  /// <summary>
  ///   The audio of the original as the model sees it: each sound is an entity of the pool (it takes an id and a slot and
  ///   nobody removes it, as in a game with no audio device) and a sound picked among several draws from the generator of
  ///   the game, in the order of the original. Nothing is played: the device is the part that is not ported
  /// </summary>
  TWarMapAudio = class(TInterfacedObject, IWarMapAudio)
  strict private
    FContext: TWarModelContext;
    FPicker: IWarSoundPicker;
    FRandom: IWarRandom;
    FLastAcknowledgement: Double;
    procedure CreateEntity;
  public
    /// <summary>The context is not owned: the audio does not outlive the model it makes entities in</summary>
    constructor Create(const AContext: TWarModelContext; const APicker: IWarSoundPicker; const ARandom: IWarRandom);
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure Acknowledge(APlayer: Integer);
    procedure DudeSelected(ASlot: Integer);
    procedure BuildingSelected(ASlot: Integer);
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Sound.Types;

const
  // MIN_ACK_SOUND_INTERVAL of war.h
  MIN_ACK_SOUND_INTERVAL: Single = 0.15;

{ TWarMapAudio }

constructor TWarMapAudio.Create(const AContext: TWarModelContext; const APicker: IWarSoundPicker;
  const ARandom: IWarRandom);
begin
  inherited Create;
  FContext := AContext;
  FPicker := APicker;
  FRandom := ARandom;
end;

procedure TWarMapAudio.CreateEntity;
begin
  // we_createEntity(WAR_ENTITY_TYPE_AUDIO, true): the id and the slot (0 if the pool is full: the original stops)
  FContext.Pool.CreateEntity(WAR_ENTITY_AUDIO, True);
end;

procedure TWarMapAudio.PlaySound(AAudioId: Integer);
begin
  CreateEntity;
end;

procedure TWarMapAudio.PlayRandomSound(AFromId, AToId: Integer);
begin
  // randomi(from, to + 1)
  FRandom.Below(AToId + 1 - AFromId);
  CreateEntity;
end;

procedure TWarMapAudio.Acknowledge(APlayer: Integer);
var
  LInterval: Double;
begin
  LInterval := FContext.RealTime - FLastAcknowledgement;
  if LInterval >= MIN_ACK_SOUND_INTERVAL then
  begin
    FLastAcknowledgement := FContext.RealTime;
    if FContext.Players[APlayer]^.Race = wraHumans then
      FPicker.Pick(wseAcknowledgement, wraHumans)
    else
      FPicker.Pick(wseAcknowledgement, wraOrcs);
    CreateEntity;
  end;
end;

procedure TWarMapAudio.DudeSelected(ASlot: Integer);
var
  LEntity: PWarEntity;
  LOnly: Boolean;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LOnly := (FContext.Selection.Count = 1) and (FContext.Selection[0] = LEntity^.Id);
  // wu_isHumanUnit ? the humans' sounds : the orcs' (a unit of no race gets the orcs')
  if TWarUnitClassifier.RaceOf(LEntity^.UnitData.UnitType) = wraHumans then
    FPicker.DudeSelectionSound(wraHumans, LOnly)
  else
    FPicker.DudeSelectionSound(wraOrcs, LOnly);
  CreateEntity;
end;

procedure TWarMapAudio.BuildingSelected(ASlot: Integer);
begin
  // the sound of a building does not draw (a click, a fire, a church...): one entity
  CreateEntity;
end;

end.
