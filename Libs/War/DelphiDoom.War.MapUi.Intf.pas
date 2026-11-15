{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contract between the game of the scenes and the   }
{  maker of the maps                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Intf;

interface

uses
  DelphiDoom.War.Ui.SceneBase;

type
  /// <summary>
  ///   The sounds of the map as far as the model of the game is concerned: the audio of the original is a list of entities
  ///   (wa_createAudio) that take an id and a place of the pool, and the choice of a sound among several draws a number
  ///   from the generator of the game; both matter to everything that comes after, so they are done even if nothing plays
  /// </summary>
  IWarMapAudio = interface
    ['{E94B2A60-1D87-4F3C-B5A9-80C2D7E41F36}']
    /// <summary>wa_createAudio: the entity of a sound</summary>
    procedure PlaySound(AAudioId: Integer);
    /// <summary>wa_createAudioRandom: one of the sounds from the first to the last, drawn</summary>
    procedure PlayRandomSound(AFromId, AToId: Integer);
    /// <summary>wa_playAcknowledgementSound: the units answer (not twice within 150 ms)</summary>
    procedure Acknowledge(APlayer: Integer);
    /// <summary>wa_playDudeSelectionSound for the unit of the slot</summary>
    procedure DudeSelected(ASlot: Integer);
    /// <summary>wa_playBuildingSelectionSound for the building of the slot</summary>
    procedure BuildingSelected(ASlot: Integer);
  end;

  /// <summary>
  ///   What a maker of maps (an IWarMapLauncher) that draws with the interface of the game implements besides: the game
  ///   gives it the services (the input, the canvas, the immediate interface, the sprites) once it has made them, because the
  ///   map is made after them and needs them
  /// </summary>
  IWarMapServicesTarget = interface
    ['{C3E81F4A-7B25-4D90-A6E1-092D5B73F8A1}']
    procedure AttachServices(const AServices: TWarSceneServices);
  end;

implementation

end.
