REM Paths
set INIT_PATH=bootstrap-git-binaries
set GIT_EXE=%INIT_PATH%\git.exe

REM URLs
set GIT_REPO_URL=git://github.com/msysgit/git.git

REM uncomment for testing
REM set GIT_OPTS=--depth=1
set GIT_OPTS=

%GIT_EXE% clone %GIT_OPTS% %GIT_REPO_URL%

