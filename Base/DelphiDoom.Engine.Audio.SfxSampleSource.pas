{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the samples of the sound effects                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Audio.SfxSampleSource;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf;

type
  /// <summary>The samples that i_sound finds in the WAD or in the files out of it</summary>
  TEngineSfxSampleSource = class(TInterfacedObject, ISfxSampleSource)
  public
    function Load(ASoundId: Integer): TSfxSample;
    procedure DiscardExternal(ASoundId: Integer);
    procedure StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
    function NameOf(ASoundId: Integer): string;
  end;

implementation

uses
  i_sound;

{ TEngineSfxSampleSource }

function TEngineSfxSampleSource.Load(ASoundId: Integer): TSfxSample;
begin
  Result := I_GetSfxSample(ASoundId);
end;

procedure TEngineSfxSampleSource.DiscardExternal(ASoundId: Integer);
begin
  I_DiscardExternalSfx(ASoundId);
end;

procedure TEngineSfxSampleSource.StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
begin
  I_StoreSfxAverageBytes(ASoundId, AAverageBytes);
end;

function TEngineSfxSampleSource.NameOf(ASoundId: Integer): string;
begin
  Result := I_SfxName(ASoundId);
end;

end.
