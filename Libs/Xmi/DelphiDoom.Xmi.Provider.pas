{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI - where the engine gets its IXmi from                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Provider;

interface

uses
  DelphiDoom.Xmi.Intf, DelphiDoom.Xmi.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TXmiClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TXmiEngine linked in the executable, so
  ///   no DLL is needed. To use DDXmi.dll (or a fake in the tests) call Use
  ///   with the IXmi obtained from TXmiLoader before the first use
  /// </remarks>
  TXmiProvider = class
  private
    class var FXmi: IXmi;
    class var FClient: TXmiClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TXmiClient; static;

    /// <summary>
    ///   Replaces the XMI implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const AXmi: IXmi); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Xmi.Engine;

{ TXmiProvider }

class function TXmiProvider.Client: TXmiClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FXmi) then
      FXmi := TXmiEngine.Create;
    FClient := TXmiClient.Create(FXmi);
  end;
  Result := FClient;
end;

class procedure TXmiProvider.Use(const AXmi: IXmi);
begin
  FreeAndNil(FClient);
  FXmi := AXmi;
end;

class procedure TXmiProvider.Release;
begin
  FreeAndNil(FClient);
  FXmi := nil;
end;

initialization

finalization
  TXmiProvider.Release;

end.
