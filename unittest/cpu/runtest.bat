@echo off
REM CAUTION: When editing with Emacs or Vi make SURE each line ends in ^M
REM to ensure that this file is compatible with DOS CR-LF style line endings.
REM If not, you can usually type CTRL+V CTRL+M on your terminal to manually
REM type a CR-LF sequence in your text editor. Emacs and Vi will auto-detect
REM CR/LF/CRLF text format so make sure to use a hex editor or hexdump to
REM check.

REM This batch file assumes a relatively stupid COMMAND.COM that may not
REM necessarily support IF statements, labels, goto, etc. It will run the
REM tests until completion or until system crash, CTRL+C, etc. This is so
REM that the test can be carried out even on older PC-DOS systems on ancient
REM hardware. The expectation, then, is that either all tests run and complete
REM or the lack of caching will ensure that test output is valid up to the
REM point where the system crashed (if it happens).

REM This test requires at least 100KB free space in the current directory.
REM Disk space is deliberately kept low so that it is possible to run this
REM on a PC/XT from a 360KB floppy if necessary.

REM Let the user know. The ECHO . at the bottom is to prevent MS-DOS from
REM printing "ECHO is OFF" or some other silly message associated with just
REM plain "ECHO".
ECHO Hackipedia.org DOSLIB2 unittest/cpu unit tests (8086 or higher).
ECHO Please make sure the current drive has as much free space as possible
ECHO before proceeding. If you do not wish to run these tests type CTRL+C
ECHO now.
PAUSE
ECHO Okay! Here we go!
ECHO .

REM ========================================================================
REM CPU unit testing script
REM ========================================================================

REM TEST: Trap flag sanity test (execute NOPs)
REM ..We want to make sure TFL8086 is able to log every instruction properly
echo ============== TEST: Trap flag sanity test ============
tfl8086p tf_null.com
qdel tf_null.log
ren tf8086.log tf_null.log

