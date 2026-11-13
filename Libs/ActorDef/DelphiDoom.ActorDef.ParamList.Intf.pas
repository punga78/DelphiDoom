{******************************************************************************}
{                                                                              }
{  DelphiDoom: actor definition library - the contracts of the parameter list  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.ParamList.Intf;

interface

type
  /// <summary>How the text of a parameter is read when the action asks for its value</summary>
  TActorDefParamKind = (
    /// <summary>A number or a plain text, read once when it is added</summary>
    apkNumber,
    /// <summary>"RANDOM min max": an integer drawn every time</summary>
    apkRandom,
    /// <summary>"FRANDOM min max" (or "FLOATRANDOM"): a float drawn every time</summary>
    apkFloatRandom,
    /// <summary>An expression computed on the actor every time</summary>
    apkEvaluate,
    /// <summary>"EVAL ...": an expression computed on the actor every time</summary>
    apkForceEvaluate
  );

  /// <summary>
  ///   The random numbers of the parameters (the old N_Random, the generator that is not
  ///   part of the demos); the parameters ask for one every time they are read
  /// </summary>
  IActorDefParamRandom = interface
    ['{4D1A8C75-3E62-4B90-A7F3-95C0E2B6D184}']
    /// <summary>The next number, from 0 to 255</summary>
    function Next: Integer;
  end;

implementation

end.
