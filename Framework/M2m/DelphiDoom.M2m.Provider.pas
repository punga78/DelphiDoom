{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - the converter shared by the engine                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.Provider;

interface

uses
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TM2mClient
  /// </summary>
  /// <remarks>
  ///   The client works on TM2mEngine linked in the executable; a fake can be
  ///   put in its place with Use before the first use
  /// </remarks>
  TM2mProvider = class
  private
    class var FM2m: IM2m;
    class var FClient: TM2mClient;
  public
    /// <summary>The client shared by the engine; created on first use</summary>
    class function Client: TM2mClient; static;

    /// <summary>Replaces the implementation. Pass nil to go back to the engine</summary>
    class procedure Use(const AM2m: IM2m); static;

    /// <summary>Frees the shared client; called at shutdown</summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.M2m.Engine;

{ TM2mProvider }

class function TM2mProvider.Client: TM2mClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FM2m) then
      FM2m := TM2mEngine.Create;
    FClient := TM2mClient.Create(FM2m);
  end;
  Result := FClient;
end;

class procedure TM2mProvider.Use(const AM2m: IM2m);
begin
  FreeAndNil(FClient);
  FM2m := AM2m;
end;

class procedure TM2mProvider.Release;
begin
  FreeAndNil(FClient);
  FM2m := nil;
end;

initialization

finalization
  TM2mProvider.Release;

end.
