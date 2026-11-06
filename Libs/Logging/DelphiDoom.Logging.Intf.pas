{******************************************************************************}
{                                                                              }
{  DelphiDoom: logging library - contracts                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Logging.Intf;

interface

uses
  DelphiDoom.Logging.Types;

type
  /// <summary>A place that takes the messages of the log (the console, a file, a message box ...)</summary>
  ILogSink = interface
    ['{3C7E19A4-D852-4F06-9B31-E50A6D2C8F17}']
    /// <summary>AText is written as it is: the line breaks are the caller's</summary>
    procedure Write(AChannel: TLogChannel; const AText: string);
  end;

  /// <summary>
  ///   What the code that has something to say asks for. It does not end the program: that is
  ///   for the caller of Error. The text is already formatted
  /// </summary>
  ILog = interface
    ['{A06D4B83-29F1-4E75-8C0A-7B3E5D1F9C62}']
    /// <summary>Text for the standard output, as it is</summary>
    procedure Info(const AText: string);
    /// <summary>"I_Warning: " and the text, to the error file and to the standard output</summary>
    procedure Warning(const AText: string);
    /// <summary>A warning, only when the program runs in developer mode</summary>
    procedure DevWarning(const AText: string);
    /// <summary>
    ///   To the error file, to the message box (the text alone) and to the standard output,
    ///   in this order: "I_Error: ", the text and a line break
    /// </summary>
    procedure Error(const AText: string);
  end;

implementation

end.
