{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the contracts                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Intf;

interface

uses
  DelphiDoom.Parity.Types;

type
  /// <summary>Where the lines of a parity log go</summary>
  IParityLog = interface
    ['{3B6E1F52-8A47-4D90-B2C5-71E0F4A9D368}']
    procedure WriteLine(const ALine: string);
    /// <summary>Makes sure that everything written is in the file</summary>
    procedure Flush;
  end;

  /// <summary>
  ///   What the engine tells the hash of the state, tic by tic: the objects of a few categories (mobjs,
  ///   sectors, lines, players), each one a list of numbers, and some single numbers (the time of the level,
  ///   the indexes of the random generator). Never an address: an object is told by its index
  /// </summary>
  IParityStateSink = interface
    ['{C4A83D17-5E92-4B60-9F1D-2A7B6E0C8453}']
    /// <summary>Declares a category and the names of its fields; the answer is the number to use below</summary>
    function RegisterCategory(const AName: string; const AFieldNames: array of string): Integer;
    procedure BeginTic(ATic: Integer);
    procedure BeginObject(ACategory: Integer; AIndex: Integer);
    /// <summary>The value of a field of the object (the fields are numbered as they were declared)</summary>
    procedure Field(AField: Integer; AValue: Int64);
    /// <summary>The object is complete</summary>
    procedure EndObject;
    /// <summary>A single number of the tic, which goes in the line by name</summary>
    procedure Scalar(const AName: string; AValue: Int64);
    /// <summary>Writes the line of the tic</summary>
    procedure EndTic;
  end;

  /// <summary>Tells whether the parity tools are on; read when needed, because the command line is read late</summary>
  IParitySwitch = interface
    ['{91D5B7E0-34C8-4A1F-8E6B-D02F7A593C14}']
    function IsActive: Boolean;
  end;

  /// <summary>The automatic pilot: one command for every tic</summary>
  IParityPilot = interface
    ['{E7F20A58-6C13-4B9D-A845-3D9B1C70E6F2}']
    /// <summary>The command of the tic of the view (the same view always gets the same command)</summary>
    function NextCommand(const AView: TParityPilotView): TParityPilotCommand;
    /// <summary>True once the tics asked for are done</summary>
    function IsFinished(ATic: Integer): Boolean;
  end;

implementation

end.
