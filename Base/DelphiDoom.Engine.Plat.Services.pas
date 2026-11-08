{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the machines that the platforms of the game use        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plat.Services;

interface

uses
  DelphiDoom.Thinkers.Platform.Intf;

//==============================================================================
//
// P_ConfigurePlats
//
// Gives the platforms their machines (the composition root calls it): the classic
// one (nil in Hexen, which has none) and the one of the scripted specials. Until
// it is called the platforms give an I_Error
//
//==============================================================================
procedure P_ConfigurePlats(const AMachine: IPlatMachine; const AUdmfMachine: IUdmfPlatMachine);

//==============================================================================
//
// PlatMachine
//
// The classic platforms (Doom, Heretic and Strife)
//
//==============================================================================
function PlatMachine: IPlatMachine;

//==============================================================================
//
// UdmfPlatMachine
//
// The platforms of the scripted specials (every game)
//
//==============================================================================
function UdmfPlatMachine: IUdmfPlatMachine;

implementation

uses
  i_system;

var
  plat_machine: IPlatMachine;
  plat_udmf_machine: IUdmfPlatMachine;

//==============================================================================
//
// P_ConfigurePlats
//
//==============================================================================
procedure P_ConfigurePlats(const AMachine: IPlatMachine; const AUdmfMachine: IUdmfPlatMachine);
begin
  plat_machine := AMachine;
  plat_udmf_machine := AUdmfMachine;
end;

//==============================================================================
//
// PlatMachine
//
//==============================================================================
function PlatMachine: IPlatMachine;
begin
  if plat_machine = nil then
    I_Error('P_ConfigurePlats(): the machine of the platforms was not given');
  result := plat_machine;
end;

//==============================================================================
//
// UdmfPlatMachine
//
//==============================================================================
function UdmfPlatMachine: IUdmfPlatMachine;
begin
  if plat_udmf_machine = nil then
    I_Error('P_ConfigurePlats(): the machine of the scripted platforms was not given');
  result := plat_udmf_machine;
end;

end.
