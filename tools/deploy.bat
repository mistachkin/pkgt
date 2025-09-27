@ECHO OFF

::
:: deploy.bat --
::
:: Extensible Adaptable Generalized Logic Engine (Eagle)
:: Package Repository/Downloader Client Deployment Tool
::
:: Copyright (c) 2007-2012 by Joe Mistachkin.  All rights reserved.
::
:: See the file "license.terms" for information on usage and redistribution of
:: this file, and for a DISCLAIMER OF ALL WARRANTIES.
::
:: RCS: @(#) $Id: $
::

SETLOCAL

REM SET __ECHO=ECHO
IF NOT DEFINED _AECHO (SET _AECHO=REM)
IF NOT DEFINED _CECHO (SET _CECHO=REM)
IF NOT DEFINED _VECHO (SET _VECHO=REM)

%_AECHO% Running %0 %*

REM SET DFLAGS=/L

%_VECHO% DFlags = '%DFLAGS%'

SET FFLAGS=/V /F /G /H /I /R /Y /Z

%_VECHO% FFlags = '%FFLAGS%'

SET ROOT=%~dp0\..
SET ROOT=%ROOT:\\=\%

%_VECHO% Root = '%ROOT%'

SET TARGET=%1

IF NOT DEFINED TARGET (
  GOTO usage
)

CALL :fn_UnquoteVariable TARGET

%_VECHO% Target = '%TARGET%'

SET SOURCE=%2

IF DEFINED SOURCE (
  CALL :fn_UnquoteVariable SOURCE
) ELSE (
  %_AECHO% No source directory specified, using default...
  CALL :fn_UseDefaultSource
)

%_VECHO% Source = '%SOURCE%'

SET DUMMY2=%3

IF DEFINED DUMMY2 (
  GOTO usage
)

IF NOT DEFINED DIRNAME (
  SET DIRNAME=pkg_r_an_d
)

%_VECHO% DirName = '%DIRNAME%'

SET TARGETDIR=%TARGET%\%DIRNAME%
SET TARGETDIR=%TARGETDIR:\\=\%

%_VECHO% TargetDir = '%TARGETDIR%'

REM ****************************************************************************
REM ************************* Check Source Directories *************************
REM ****************************************************************************

IF NOT EXIST "%SOURCE%" (
  ECHO Cannot copy from "%SOURCE%", it does not exist.
  GOTO errors
)

REM ****************************************************************************
REM *********************** Package Script Library Files ***********************
REM ****************************************************************************

SET PKGFILES=common.tcl common.tcl.asc
SET PKGFILES=%PKGFILES% pkgd.eagle pkgd.eagle.asc
SET PKGFILES=%PKGFILES% pkgd.eagle.harpy pkgd.eagle.harpy.asc
SET PKGFILES=%PKGFILES% pkgIndex.eagle pkgIndex.eagle.asc
SET PKGFILES=%PKGFILES% pkgIndex.eagle.harpy pkgIndex.eagle.harpy.asc
SET PKGFILES=%PKGFILES% pkgIndex.tcl pkgIndex.tcl.asc
SET PKGFILES=%PKGFILES% pkgr.eagle pkgr.eagle.asc
SET PKGFILES=%PKGFILES% pkgr.eagle.harpy pkgr.eagle.harpy.asc
SET PKGFILES=%PKGFILES% pkgr_install.eagle pkgr_install.eagle.asc
SET PKGFILES=%PKGFILES% pkgr_install.eagle.harpy pkgr_install.eagle.harpy.asc
SET PKGFILES=%PKGFILES% pkgr_setup.eagle pkgr_setup.eagle.asc
SET PKGFILES=%PKGFILES% pkgr_setup.eagle.harpy pkgr_setup.eagle.harpy.asc
SET PKGFILES=%PKGFILES% pkgr_upload.eagle pkgr_upload.eagle.asc
SET PKGFILES=%PKGFILES% pkgr_upload.eagle.harpy pkgr_upload.eagle.harpy.asc
SET PKGFILES=%PKGFILES% pkgu.eagle pkgu.eagle.asc
SET PKGFILES=%PKGFILES% pkgu.eagle.harpy pkgu.eagle.harpy.asc
SET PKGFILES=%PKGFILES% VERSION VERSION.asc

%_VECHO% PkgFiles = '%PKGFILES%'

REM ****************************************************************************
REM ************************ Eagle Script Library Files ************************
REM ****************************************************************************

SET EAGLEFILES=auxiliary.eagle auxiliary.eagle.asc
SET EAGLEFILES=%EAGLEFILES% auxiliary.eagle.harpy auxiliary.eagle.harpy.asc
SET EAGLEFILES=%EAGLEFILES% file1.eagle file1.eagle.asc
SET EAGLEFILES=%EAGLEFILES% file1.eagle.harpy file1.eagle.harpy.asc
SET EAGLEFILES=%EAGLEFILES% pkgIndex.tcl pkgIndex.tcl.asc
SET EAGLEFILES=%EAGLEFILES% platform.eagle platform.eagle.asc
SET EAGLEFILES=%EAGLEFILES% platform.eagle.harpy platform.eagle.harpy.asc

%_VECHO% EagleFiles = '%EAGLEFILES%'

REM ****************************************************************************

CALL :fn_ResetErrorLevel

REM ****************************************************************************

FOR %%F IN (%PKGFILES%) DO (
  %__ECHO% XCOPY "%SOURCE%\client\1.0\neutral\%%F" "%TARGETDIR%\" %FFLAGS% %DFLAGS%

  IF ERRORLEVEL 1 (
    ECHO Failed to copy "%SOURCE%\client\1.0\neutral\%%F" to "%TARGETDIR%\".
    GOTO errors
  )
)

REM ****************************************************************************

FOR %%F IN (%EAGLEFILES%) DO (
  %__ECHO% XCOPY "%SOURCE%\externals\Eagle\lib\Eagle1.0\%%F" "%TARGETDIR%\Eagle1.0\" %FFLAGS% %DFLAGS%

  IF ERRORLEVEL 1 (
    ECHO Failed to copy "%SOURCE%\externals\Eagle\lib\Eagle1.0\%%F" to "%TARGETDIR%\Eagle1.0\".
    GOTO errors
  )
)

REM ****************************************************************************

GOTO no_errors

:fn_UseDefaultSource
  IF DEFINED ROOT (
    SET SOURCE=%ROOT%
  ) ELSE (
    SET SOURCE=.
  )
  SET SOURCE=%SOURCE:\\=\%
  GOTO :EOF

:fn_UnquoteVariable
  IF NOT DEFINED %1 GOTO :EOF
  SETLOCAL
  SET __ECHO_CMD=ECHO %%%1%%
  FOR /F "delims=" %%V IN ('%__ECHO_CMD%') DO (
    SET VALUE=%%V
  )
  SET VALUE=%VALUE:"=%
  REM "
  ENDLOCAL && SET %1=%VALUE%
  GOTO :EOF

:fn_ResetErrorLevel
  VERIFY > NUL
  GOTO :EOF

:fn_SetErrorLevel
  VERIFY MAYBE 2> NUL
  GOTO :EOF

:usage
  ECHO.
  ECHO Usage: %~nx0 ^<target^> [source]
  GOTO errors

:errors
  CALL :fn_SetErrorLevel
  ENDLOCAL
  ECHO.
  ECHO Deploy failure, errors were encountered.
  GOTO end_of_file

:no_errors
  CALL :fn_ResetErrorLevel
  ENDLOCAL
  ECHO.
  ECHO Deploy success, no errors were encountered.
  GOTO end_of_file

:end_of_file
%__ECHO% EXIT /B %ERRORLEVEL%
