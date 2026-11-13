{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - constants of the fuzzy weights                         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the constants of    }
{  code\botlib\be_ai_weight.h and be_ai_weight.c. Based on the Quake III Arena }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Types;

interface

const
  /// <summary>WT_BALANCE: the weight is a <c>balance(weight, min, max)</c></summary>
  WT_BALANCE = 1;
  /// <summary>MAX_WEIGHTS: the weights of a configuration</summary>
  MAX_WEIGHTS = 128;
  /// <summary>MAX_INVENTORYVALUE: the value of the default case</summary>
  MAX_INVENTORYVALUE = 999999;
  /// <summary>MAX_WEIGHT_FILES: the configurations the library keeps</summary>
  MAX_WEIGHT_FILES = 128;

implementation

end.
