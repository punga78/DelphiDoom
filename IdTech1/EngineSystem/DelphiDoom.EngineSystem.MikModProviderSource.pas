{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the MikMod client of the program        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.MikModProviderSource;

interface

uses
  DelphiDoom.Mikmod.Client, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>
  ///   The MikMod client that TMikModProvider keeps for the whole program: the provider makes it
  ///   the first time somebody asks for it and frees it on Release
  /// </summary>
  TMikModProviderSource = class(TInterfacedObject, IMikModClientSource)
  public
    function Client: TMikModClient;
    procedure Release;
  end;

implementation

uses
  DelphiDoom.Mikmod.Provider;

{ TMikModProviderSource }

function TMikModProviderSource.Client: TMikModClient;
begin
  Result := TMikModProvider.Client;
end;

procedure TMikModProviderSource.Release;
begin
  TMikModProvider.Release;
end;

end.
