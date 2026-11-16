{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the unpredictable numbers that are repeatable  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.SwitchEntropy;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Random;

type
  /// <summary>
  ///   The source of the unpredictable numbers of the game (the old I_Random, used for example by the melt
  ///   of the screen): the real one as long as the parity tools are off; when they are on, a generator with a
  ///   fixed seed, so two runs draw the same pixels
  /// </summary>
  TParitySwitchEntropy = class(TInterfacedObject, IEntropySource)
  strict private
    FReal: IEntropySource;
    FSwitch: IParitySwitch;
    FRepeatable: TParityRandom;
  public
    constructor Create(const AReal: IEntropySource; const ASwitch: IParitySwitch; ASeed: Cardinal);
    destructor Destroy; override;
    function Next(ARange: Integer): Integer;
  end;

implementation

uses
  System.SysUtils;

{ TParitySwitchEntropy }

constructor TParitySwitchEntropy.Create(const AReal: IEntropySource; const ASwitch: IParitySwitch;
  ASeed: Cardinal);
begin
  inherited Create;
  if not Assigned(AReal) then
    raise EArgumentNilException.Create('AReal');
  if not Assigned(ASwitch) then
    raise EArgumentNilException.Create('ASwitch');
  FReal := AReal;
  FSwitch := ASwitch;
  FRepeatable := TParityRandom.Create(ASeed);
end;

destructor TParitySwitchEntropy.Destroy;
begin
  FRepeatable.Free;
  inherited Destroy;
end;

function TParitySwitchEntropy.Next(ARange: Integer): Integer;
begin
  if FSwitch.IsActive then
    Result := FRepeatable.NextBelow(ARange)
  else
    Result := FReal.Next(ARange);
end;

end.
