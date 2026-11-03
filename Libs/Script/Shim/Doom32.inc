// Replacement of Doom32.inc for the script DLL and its tests.
//
// SCRIPT\ps_defs.pas and SCRIPT\ps_keywords.pas start with {$I Doom32.inc}.
// The real file also sets application level switches ($APPTYPE GUI,
// $IMAGEBASE, stack sizes) that belong to the engine executables and would
// change the type of a console test project. This file keeps only the code
// generation switches of the original: put the folder Libs\Script\Shim in the
// include path BEFORE the folder of the engine and the compiler finds this
// file first. Keep the switches aligned with the real Doom32.inc.

{$IFNDEF FPC}
{$DEFINE DELPHI}
{$ENDIF}

{$B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$ALIGN 8}

{$IFDEF DEBUG}
{$O-}
{$ENDIF}
