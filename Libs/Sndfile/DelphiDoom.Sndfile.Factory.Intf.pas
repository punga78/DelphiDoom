{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - how the provider obtains the decoding engine       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Factory.Intf;

interface

uses
  DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Builds the ISndfile the provider uses when no other one was given
  /// </summary>
  /// <remarks>
  ///   This is the meeting point between Libs\Sndfile and the libraries that
  ///   implement ISndfile (Libs\Sound): the dependency goes only from the
  ///   implementation to this contract, never the other way round
  /// </remarks>
  ISndfileFactory = interface
    ['{5B0E7A1C-3D52-4F0B-9A64-8C1D2E7F4A90}']
    /// <summary>
    ///   Creates a new engine; the caller owns the returned reference
    /// </summary>
    function CreateEngine: ISndfile;
  end;

implementation

end.