//------------------------------------------------------------------------------
//
//  Compiler switches for the JPEGLIB units when they are built into DDJpeg.dll
//
//  The units of JPEGLIB\ start with an include of Doom32.inc. This file takes
//  the place of the Doom32.inc of the project root for the projects that put
//  Libs\Jpeg in their include path (DDJpeg.dll and the tests): it has the same
//  language switches but not the settings of an executable (APPTYPE, IMAGEBASE
//  and stack sizes), which do not belong in a DLL or in a console test.
//  Keep the switches aligned with the real Doom32.inc.
//
//------------------------------------------------------------------------------

{$IFNDEF FPC}
{$DEFINE DELPHI}
{$ENDIF}

{$IFDEF DELPHI}
{$B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$ALIGN 8}
{$ENDIF}

{$IFDEF DEBUG}
{$O-}
{$ENDIF}
