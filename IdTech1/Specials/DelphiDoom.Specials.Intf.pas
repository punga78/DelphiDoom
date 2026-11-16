{******************************************************************************}
{                                                                              }
{  DelphiDoom: specials library - the registry of the line specials            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Specials.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What a special receives: the number, the five arguments, the line that fired it, the
  ///   side that was crossed and the thing that did it. The library does not know the types of
  ///   the engine: line and thing are opaque pointers that the handlers of the engine cast back
  /// </summary>
  TSpecialContext = record
    Special: Integer;
    Args: PByte;
    Line: Pointer;
    Side: Integer;
    Actor: Pointer;
  end;

  /// <summary>The code of a special; it returns true if the special did something</summary>
  TSpecialHandler = reference to function(const AContext: TSpecialContext): Boolean;

  /// <summary>
  ///   The table that gives to each number of special the code that runs it: a new special is
  ///   a new registration, not a new branch of a big case
  /// </summary>
  ISpecialRegistry = interface
    ['{6C1B0E52-8F3A-4D7B-9A25-3E41D0B7C968}']
    /// <summary>Adds a special; a number that is already there is an error</summary>
    procedure Register(ANumber: Integer; const AHandler: TSpecialHandler);
    /// <summary>True if the number has a handler</summary>
    function Contains(ANumber: Integer): Boolean;
    /// <summary>Runs the special of the context; a number that nobody registered does nothing and gives false</summary>
    function Execute(const AContext: TSpecialContext): Boolean;
    /// <summary>The numbers that have a handler, in ascending order</summary>
    function Numbers: TArray<Integer>;
  end;

  /// <summary>A special registered twice</summary>
  ESpecialRegistryException = class(Exception);

implementation

end.
