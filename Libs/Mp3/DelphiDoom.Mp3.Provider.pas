{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - where the engine gets its IMp3 from                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Provider;

interface

uses
  DelphiDoom.Mp3.Intf;

type
  /// <summary>
  ///   Gives the rest of the engine the IMp3 that creates the decoders
  /// </summary>
  /// <remarks>
  ///   By default it is TMp3Engine linked in the executable, so no DLL is
  ///   needed. To use DDMp3.dll (or a fake in the tests) call Use with the
  ///   IMp3 obtained from TMp3Loader. Unlike the other libraries there is no
  ///   shared client: every song has its own decoder (TMp3Client)
  /// </remarks>
  TMp3Provider = class
  private
    class var FMp3: IMp3;
  public
    /// <summary>
    ///   The factory of decoders; created on first use
    /// </summary>
    class function Mp3: IMp3; static;

    /// <summary>
    ///   Replaces the implementation (DLL or fake). Pass nil to go back to
    ///   the engine linked in the executable
    /// </summary>
    class procedure Use(const AMp3: IMp3); static;

    /// <summary>
    ///   Releases the factory; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  DelphiDoom.Mp3.Engine;

{ TMp3Provider }

class function TMp3Provider.Mp3: IMp3;
begin
  if not Assigned(FMp3) then
    FMp3 := TMp3Engine.Create;
  Result := FMp3;
end;

class procedure TMp3Provider.Use(const AMp3: IMp3);
begin
  FMp3 := AMp3;
end;

class procedure TMp3Provider.Release;
begin
  FMp3 := nil;
end;

initialization

finalization
  TMp3Provider.Release;

end.
