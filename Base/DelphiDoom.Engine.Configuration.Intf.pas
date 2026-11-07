{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the defaults of the configuration file                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Configuration.Intf;

{$I Doom32.inc}

interface

type
  /// <summary>
  ///   The table of the defaults of the engine (m_defs: the options with a pointer to their
  ///   variable) read from and written to the configuration file. The composition root gives it
  ///   to the main loop (d_main reads it), to the system (i_system writes it at the end) and to
  ///   who forces an option (#CVARFORCE, the scripts). It was the facade m_misc.pas
  /// </summary>
  IEngineDefaults = interface
    ['{8D2F6B13-A74C-4E95-B0D8-1C6E37F92A50}']
    /// <summary>
    ///   Sets every option to its default value, then reads the configuration file (or the one
    ///   of -config) over it (M_LoadDefaults)
    /// </summary>
    procedure Load;
    /// <summary>Writes every option to the configuration file read by Load (M_SaveDefaults)</summary>
    procedure Save;
    /// <summary>
    ///   Gives an option (or every option that matches a mask with *) its default value, as the
    ///   command "setdefault" does (M_SetDefault)
    /// </summary>
    procedure Reset(const AName: string);
    /// <summary>
    ///   Forces an option: the variable takes the value and the option can not be changed any
    ///   more, nor written to the file. False if there is no boolean option with that name
    /// </summary>
    function ForceBoolean(const AName: string; const AValue: Boolean): Boolean;
    /// <summary>As ForceBoolean, for an option that is a number</summary>
    function ForceInteger(const AName: string; const AValue: Integer): Boolean;
    /// <summary>As ForceBoolean, for an option that is a text</summary>
    function ForceString(const AName: string; const AValue: string): Boolean;
    /// <summary>True until Load reads a configuration file with a version it accepts</summary>
    function ConfigNotFound: Boolean;
  end;

implementation

end.
