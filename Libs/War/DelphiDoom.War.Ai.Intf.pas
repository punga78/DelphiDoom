{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the training states tell the AI               }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_train.c (the call of          }
{  wai_applyUnitRequestProgress), (c) 2019 Alejandro Coto Gutierrez, zlib       }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Intf;

interface

type
  /// <summary>
  ///   The only thing the model asks of the AI: a training ordered by an AI request has been paid, so the request counts
  ///   one more unit. It is called once per purchase, never per unit and per tic. The handle is
  ///   TWarComputerPlayers.MakeHandle(player, command id); 0 means "no request"
  /// </summary>
  IWarAiProgress = interface
    ['{6B4C1E7A-3D55-4B0E-9E0C-1D2F6A87C3A1}']
    procedure UnitRequestProgress(AHandle: Cardinal);
  end;

  /// <summary>
  ///   What the tic of the world asks of the computer players: wai_updateAIPlayers, run once per tic after the orders of the
  ///   human player and before the requests of change of the states are processed (the order of wmap_updateMap)
  /// </summary>
  IWarComputerUpdate = interface
    ['{0F8E0B52-7C1B-4F0D-8A55-4C9B6D2E31B7}']
    procedure UpdateComputerPlayers;
  end;

implementation

end.
