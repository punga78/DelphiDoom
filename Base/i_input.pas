//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_input;

interface

uses
  DelphiDoom.Input.Intf;

type
  /// <summary>Makes the poller of the input; it is told if DirectInput is wanted</summary>
  TInputPollerFactory = reference to function(AUseDirectInput: Boolean): IInputPoller;

//==============================================================================
//
// I_ConfigureInput
// Gives the unit the way to make its poller. The composition root calls it
//
//==============================================================================
procedure I_ConfigureInput(const AFactory: TInputPollerFactory);

//==============================================================================
//
// I_InitInput
//
//==============================================================================
procedure I_InitInput;

//==============================================================================
//
// I_ProcessInput
//
//==============================================================================
procedure I_ProcessInput;

//==============================================================================
//
// I_ShutDownInput
//
//==============================================================================
procedure I_ShutDownInput;

//==============================================================================
//
// I_SynchronizeInput
//
//==============================================================================
procedure I_SynchronizeInput(active: boolean);

//==============================================================================
//
// I_SetMouseClicks
//
//==============================================================================
procedure I_SetMouseClicks(val: integer);

//==============================================================================
//
// I_GetCapsLock
//
//==============================================================================
function I_GetCapsLock: boolean;

var
  usedirectinput: boolean = false;

implementation

uses
  DelphiDoom.Input.Types,
  i_system;

var
  // given by the composition root (I_ConfigureInput)
  input_factory: TInputPollerFactory = nil;
  input_poller: IInputPoller = nil;

//==============================================================================
//
// I_ConfigureInput
//
//==============================================================================
procedure I_ConfigureInput(const AFactory: TInputPollerFactory);
begin
  input_factory := AFactory;
end;

//==============================================================================
//
// I_InitInput
//
//==============================================================================
procedure I_InitInput;
begin
  if not Assigned(input_factory) then
    I_Error('I_InitInput(): the input was not configured');

  input_poller := input_factory(usedirectinput);
  try
    input_poller.Initialize;
  except
    on E: EInputDeviceException do
      I_Error('%s', [E.Message]);
  end;
end;

//==============================================================================
//
// I_ShutDownInput
// Terminate our usage of the input devices
//
//==============================================================================
procedure I_ShutDownInput;
begin
  if input_poller <> nil then
  begin
    input_poller.Shutdown;
    input_poller := nil;
  end;
end;

//==============================================================================
//
// I_ProcessInput
// The game plays here. Read keyboard data and displaying it.
//
//==============================================================================
procedure I_ProcessInput;
begin
  if input_poller <> nil then
    input_poller.Process;
end;

//==============================================================================
//
// I_SetMouseClicks
//
//==============================================================================
procedure I_SetMouseClicks(val: integer);
begin
  if input_poller <> nil then
    input_poller.SetMouseClicks(val);
end;

//==============================================================================
//
// I_GetCapsLock
//
//==============================================================================
function I_GetCapsLock: boolean;
begin
  result := (input_poller <> nil) and input_poller.IsCapsLockOn;
end;

//==============================================================================
//
// I_SynchronizeInput
//
//==============================================================================
procedure I_SynchronizeInput(active: boolean);
begin
  if input_poller <> nil then
    input_poller.Synchronize(active);
end;

end.