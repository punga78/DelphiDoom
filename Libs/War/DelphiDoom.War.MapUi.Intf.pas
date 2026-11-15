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
