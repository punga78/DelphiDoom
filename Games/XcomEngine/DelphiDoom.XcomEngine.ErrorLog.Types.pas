{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - what an error of the program says to the  }
{  file of errors (issue 187)                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ErrorLog.Types;

interface

type
  /// <summary>
  ///   One error that reached the main loop of the program, as it is written in xcom_errors.log: the class and the
  ///   message of the exception, where it was raised, the callers, the states of the game and the version
  /// </summary>
  TXcomErrorEntry = record
    /// <summary>The class name of the exception</summary>
    ExceptionClass: string;
    ExceptionMessage: string;
    /// <summary>The address in the terms of the .map of the executable; empty when it is not known</summary>
    MapAddress: string;
    /// <summary>The callers, nearest first, in the terms of the .map; empty when it is not known</summary>
    CallStack: string;
    /// <summary>The class names of the states of the game, the one on top first; empty when there was no game</summary>
    States: TArray<string>;
    /// <summary>The version text of the game</summary>
    Version: string;
  end;

implementation

end.
