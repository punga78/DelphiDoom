{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - where the engine gets its IJpeg from                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Provider;

interface

uses
  DelphiDoom.Jpeg.Intf, DelphiDoom.Jpeg.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TJpegClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TJpegEngine linked in the executable, so
  ///   no DLL is needed. To use DDJpeg.dll (or a fake in the tests) call Use
  ///   with the IJpeg obtained from TJpegLoader before the first use
  /// </remarks>
  TJpegProvider = class
  private
    class var FJpeg: IJpeg;
    class var FClient: TJpegClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TJpegClient; static;

    /// <summary>
    ///   Replaces the JPEG implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const AJpeg: IJpeg); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Jpeg.Engine;

{ TJpegProvider }

class function TJpegProvider.Client: TJpegClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FJpeg) then
      FJpeg := TJpegEngine.Create;
    FClient := TJpegClient.Create(FJpeg);
  end;
  Result := FClient;
end;

class procedure TJpegProvider.Use(const AJpeg: IJpeg);
begin
  FreeAndNil(FClient);
  FJpeg := AJpeg;
end;

class procedure TJpegProvider.Release;
begin
  FreeAndNil(FClient);
  FJpeg := nil;
end;

initialization

finalization
  TJpegProvider.Release;

end.
