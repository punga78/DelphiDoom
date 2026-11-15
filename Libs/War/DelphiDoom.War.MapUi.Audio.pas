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
  System.SysUtils, DelphiDoom.War.Sound.Intf, DelphiDoom.War.Model.Context, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.MapUi.Intf;

type
  /// <summary>
  ///   The audio of the original as the model sees it: each sound is an entity of the pool (it takes an id and a slot and
  ///   nobody removes it, as in a game with no audio device) and a sound picked among several draws from the generator of
  ///   the game, in the order of the original. With an output (the scenes' IWarSceneAudio, given by a program that has a
  ///   sound device) the sound that was chosen is also played, without a place on the map (the volume does not follow the
  ///   camera); the draws, and so the game, are the same with or without it
  /// </summary>
  TWarMapAudio = class(TInterfacedObject, IWarMapAudio, IWarMapAudioAt)
  strict private
    FContext: TWarModelContext;
    FPicker: IWarSoundPicker;
    FRandom: IWarRandom;
    FOutput: IWarSceneAudio;
    /// <summary>The same output when it knows places (IWarPositionalAudio), else nil: a sound with a place then plays without one</summary>
    FPositional: IWarPositionalAudio;
    FLastAcknowledgement: Double;
    procedure CreateEntity;
    procedure Emit(AAudioId: Integer);
    procedure EmitAt(AAudioId: Integer; AX, AY: Single);
  public
    /// <summary>
    ///   The context is not owned: the audio does not outlive the model it makes entities in. The output may be nil
    ///   (nothing is played)
    /// </summary>
    constructor Create(const AContext: TWarModelContext; const APicker: IWarSoundPicker; const ARandom: IWarRandom;
      const AOutput: IWarSceneAudio = nil);
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure PlaySoundAt(AAudioId: Integer; AX, AY: Single; AAudible: Boolean);
    procedure PlayRandomSoundAt(AFromId, AToId: Integer; AX, AY: Single; AAudible: Boolean);
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
  // the records 0..44 of DATA.WAR are the songs (the cheat Music takes 1..45)
  LAST_MUSIC_ID = 44;

{ TWarMapAudio }

constructor TWarMapAudio.Create(const AContext: TWarModelContext; const APicker: IWarSoundPicker;
  const ARandom: IWarRandom; const AOutput: IWarSceneAudio);
begin
  inherited Create;
  FContext := AContext;
  FPicker := APicker;
  FRandom := ARandom;
  FOutput := AOutput;
  if not Supports(AOutput, IWarPositionalAudio, FPositional) then
    FPositional := nil;
end;

procedure TWarMapAudio.CreateEntity;
begin
  // we_createEntity(WAR_ENTITY_TYPE_AUDIO, true): the id and the slot (0 if the pool is full: the original stops)
  FContext.Pool.CreateEntity(WAR_ENTITY_AUDIO, True);
end;

procedure TWarMapAudio.Emit(AAudioId: Integer);
begin
  if Assigned(FOutput) and (AAudioId >= 0) then
    // the songs (the records 0..44) go round, the effects play once
    FOutput.Play(AAudioId, AAudioId <= LAST_MUSIC_ID);
end;

procedure TWarMapAudio.EmitAt(AAudioId: Integer; AX, AY: Single);
begin
  if AAudioId < 0 then
    Exit;
  if Assigned(FPositional) then
    FPositional.PlayAt(AAudioId, AX, AY)
  else
    Emit(AAudioId);
end;

procedure TWarMapAudio.PlaySound(AAudioId: Integer);
begin
  CreateEntity;
  Emit(AAudioId);
end;

procedure TWarMapAudio.PlaySoundAt(AAudioId: Integer; AX, AY: Single; AAudible: Boolean);
begin
  // wa_createAudioWithPosition: with the fog on, a place that is not visible makes no entity and plays nothing
  if not AAudible then
    Exit;
  CreateEntity;
  EmitAt(AAudioId, AX, AY);
end;

procedure TWarMapAudio.PlayRandomSoundAt(AFromId, AToId: Integer; AX, AY: Single; AAudible: Boolean);
var
  LChosen: Integer;
begin
  // randomi(from, to + 1) is evaluated before the call that looks at the place: the number is drawn in any case
  LChosen := AFromId + FRandom.Below(AToId + 1 - AFromId);
  PlaySoundAt(LChosen, AX, AY, AAudible);
end;

procedure TWarMapAudio.PlayRandomSound(AFromId, AToId: Integer);
var
  LChosen: Integer;
begin
  // randomi(from, to + 1)
  LChosen := AFromId + FRandom.Below(AToId + 1 - AFromId);
  CreateEntity;
  Emit(LChosen);
end;

procedure TWarMapAudio.Acknowledge(APlayer: Integer);
var
  LInterval: Double;
  LSound: Integer;
begin
  LInterval := FContext.RealTime - FLastAcknowledgement;
  if LInterval >= MIN_ACK_SOUND_INTERVAL then
  begin
    FLastAcknowledgement := FContext.RealTime;
    if FContext.Players[APlayer]^.Race = wraHumans then
      LSound := FPicker.Pick(wseAcknowledgement, wraHumans)
    else
      LSound := FPicker.Pick(wseAcknowledgement, wraOrcs);
    CreateEntity;
    Emit(LSound);
  end;
end;

procedure TWarMapAudio.DudeSelected(ASlot: Integer);
var
  LEntity: PWarEntity;
  LOnly: Boolean;
  LSound: Integer;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LOnly := (FContext.Selection.Count = 1) and (FContext.Selection[0] = LEntity^.Id);
  // wu_isHumanUnit ? the humans' sounds : the orcs' (a unit of no race gets the orcs')
  if TWarUnitClassifier.RaceOf(LEntity^.UnitData.UnitType) = wraHumans then
    LSound := FPicker.DudeSelectionSound(wraHumans, LOnly)
  else
    LSound := FPicker.DudeSelectionSound(wraOrcs, LOnly);
  CreateEntity;
  Emit(LSound);
end;

procedure TWarMapAudio.BuildingSelected(ASlot: Integer);
begin
  // the sound of a building does not draw (a click, a fire, a church...): one entity
  CreateEntity;
end;

end.
