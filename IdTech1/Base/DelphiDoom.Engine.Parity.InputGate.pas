{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the input gate of the parity tools                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.InputGate;

interface

uses
  DelphiDoom.Input.Intf,
  DelphiDoom.Parity.Intf;

type
  /// <summary>
  ///   The gate of the input when the parity tools may be on: while they are off it is the real gate; when
  ///   they are on it is closed for keyboard, mouse and joystick, so a key pressed by whoever uses the
  ///   computer cannot open the menu in the middle of a demo
  /// </summary>
  TEngineParityInputGate = class(TInterfacedObject, IInputGate)
  strict private
    FReal: IInputGate;
    FSwitch: IParitySwitch;
  public
    constructor Create(const AReal: IInputGate; const ASwitch: IParitySwitch);
    function IsInputAllowed: Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TEngineParityInputGate }

constructor TEngineParityInputGate.Create(const AReal: IInputGate; const ASwitch: IParitySwitch);
begin
  inherited Create;
  if not Assigned(AReal) then
    raise EArgumentNilException.Create('AReal');
  if not Assigned(ASwitch) then
    raise EArgumentNilException.Create('ASwitch');
  FReal := AReal;
  FSwitch := ASwitch;
end;

function TEngineParityInputGate.IsInputAllowed: Boolean;
begin
  if FSwitch.IsActive then
    Result := False
  else
    Result := FReal.IsInputAllowed;
end;

end.
