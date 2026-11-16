{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the hooks of the parity tools                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.Hooks;

interface

uses
  d_ticcmd;

type
  /// <summary>What the engine calls when the parity tools are on (the adapter of the tools implements it)</summary>
  IEngineParityHooks = interface
    ['{F1A92C60-3E85-4D17-B6A4-58C07D1E9F23}']
    /// <summary>The end of a tic of the game (P_Ticker)</summary>
    procedure AfterTick;
    /// <summary>The end of a frame, before it is shown (D_FinishUpdate)</summary>
    procedure AfterFrame;
    /// <summary>The command of the tic has been built; the pilot may replace it (TEngineNetServices.BuildTicCmd)</summary>
    procedure BuildTicCmd(ACommand: Pticcmd_t);
    /// <summary>Everything that was logged is in the files</summary>
    procedure Flush;
  end;

var
  /// <summary>nil as long as no option of the tools is on: this is the only thing that the engine reads</summary>
  parity_hooks: IEngineParityHooks = nil;

//==============================================================================
//
// Parity_AfterTick
//
//==============================================================================
procedure Parity_AfterTick;

//==============================================================================
//
// Parity_AfterFrame
//
//==============================================================================
procedure Parity_AfterFrame;

//==============================================================================
//
// Parity_BuildTicCmd
//
//==============================================================================
procedure Parity_BuildTicCmd(ACommand: Pticcmd_t);

implementation

//==============================================================================
//
// Parity_AfterTick
//
//==============================================================================
procedure Parity_AfterTick;
begin
  if parity_hooks <> nil then
    parity_hooks.AfterTick;
end;

//==============================================================================
//
// Parity_AfterFrame
//
//==============================================================================
procedure Parity_AfterFrame;
begin
  if parity_hooks <> nil then
    parity_hooks.AfterFrame;
end;

//==============================================================================
//
// Parity_BuildTicCmd
//
//==============================================================================
procedure Parity_BuildTicCmd(ACommand: Pticcmd_t);
begin
  if parity_hooks <> nil then
    parity_hooks.BuildTicCmd(ACommand);
end;

initialization

finalization
  // the program ends with Halt: what the logs still keep must reach the files
  if parity_hooks <> nil then
    parity_hooks.Flush;

end.
