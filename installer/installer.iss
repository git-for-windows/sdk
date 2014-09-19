#define APP_NAME    'mingwGitDevEnv'
#define APP_VERSION GetEnv('APP_VERSION')

#if APP_VERSION==''
    #define APP_VERSION  'Snapshot'
    #define APP_VER_NAME APP_NAME+' '+APP_VERSION
    #define OUT_NAME     StringChange(APP_VER_NAME,' ','-')
    #define FILE_VERSION '0.0.0.0'
#else
    #define APP_VER_NAME APP_NAME+' '+APP_VERSION
    #define APP_VERSION  Delete(APP_VERSION,1,1)
    #define OUT_NAME     StringChange(APP_VER_NAME,' ','-')
    #if Pos('-g',APP_VERSION)>0
        #define FILE_VERSION ChangeFileExt(StringChange(APP_VERSION,'-','.'),'0')
    #else
        #define FILE_VERSION APP_VERSION
    #endif
#endif

#define PACKAGES_REPO_CONFIG '-c diff.lzma.textconv=""lzma -d -c -qq | cat"" -c filter.lzma.smudge=""lzma -d"" -c filter.lzma.clean=""lzma -z""'
#define PACKAGES_REPO_URL    'https://github.com/sschuberth/mingwGitDevEnv-packages.git'

#define GIT_REPO_CONFIG '-c core.autocrlf=false'
#define GIT_REPO_URL    'https://github.com/sschuberth/git.git'

[Setup]

; Compiler-related
Compression=lzma2/ultra
LZMAUseSeparateProcess=yes
OutputBaseFilename={#OUT_NAME}
OutputDir=.
SolidCompression=yes
SourceDir=..
VersionInfoVersion={#FILE_VERSION}

; Installer-related
AllowNoIcons=yes
AppName={#APP_NAME}
AppVersion={#APP_VERSION}
AppVerName={#APP_VER_NAME}
ChangesEnvironment=yes
DefaultDirName={sd}\{#APP_NAME}
DefaultGroupName={#APP_NAME}
DisableReadyPage=yes
InfoBeforeFile=installer\note.rtf
PrivilegesRequired=none
Uninstallable=not IsPortableMode

; Cosmetic
SetupIconFile=root\mingw\etc\git.ico
WizardImageBackColor=clWhite
WizardImageStretch=no
WizardImageFile=root\mingw\etc\git-large.bmp
WizardSmallImageFile=root\mingw\etc\git-small.bmp

[Files]

Source: root\*; DestDir: {app}; Flags: recursesubdirs

[Icons]

Name: "{group}\Git Development Environment"; Filename: "{app}\Git Bash.vbs"; IconFilename: "{uninstallexe}"
Name: "{group}\Git Development Environment (MSYS Mode)"; Filename: "{app}\Git Bash.vbs"; Parameters: "MSYS"; IconFilename: "{uninstallexe}"

[Run]

Description: "Rebase DLLs"; Filename: "{app}\rebaseall.cmd"; Flags: postinstall
Description: "Update Perl modules"; Filename: "{app}\update-perl-modules.cmd"; Flags: postinstall

; For the packages repository we have configured smudge / clean and diff filters that depend on lzma (and sh) to be in PATH, so make sure the environment is set up correctly. 
Description: "Clone the packages repository"; Filename: "{app}\bin\sh.exe"; Parameters: "--login -c 'git clone {#PACKAGES_REPO_CONFIG} {#PACKAGES_REPO_URL} packages'"; WorkingDir: "{app}"; Flags: postinstall skipifsilent
Description: "Clone the Git repository"; Filename: "{app}\mingw\bin\git.exe"; Parameters: "clone {#GIT_REPO_CONFIG} {#GIT_REPO_URL}"; WorkingDir: "{app}"; Flags: postinstall skipifsilent

Description: "Start the development environment"; Filename: "wscript"; Parameters: """{app}\Git Bash.vbs"""; Flags: postinstall skipifsilent

[UninstallDelete]

Type: filesandordirs; Name: "{app}"

[Messages]

ConfirmUninstall=This will uninstall %1 and remove all files in the installation directory including those that were added after installation (like custom packages and configuration files). Are you sure that you want to continue?

[Code]

#include "environment.inc.iss"
#include "xmlparser.inc.iss"

const
    // List packages required to build Git from sources, or those that must ship with the Git for Windows end-user installer.
    RequiredPackages    = 'msys-automake '
                        + 'msys-base '
                        + 'msys-coreutils '
                        + 'msys-libiconv '
                        + 'msys-libtool '
                        + 'msys-mktemp '
                        + 'msys-openssh '
                        + 'msys-perl '
                        + 'msys-python '
                        + 'msys-rebase '

                        + 'mingw32-gcc '
                        + 'mingw32-gcc-g++ '
                        + 'mingw32-gettext '
                        + 'mingw32-git '
                        + 'mingw32-libcurl '
                        + 'mingw32-libexpat '
                        + 'mingw32-libiconv '
                        + 'mingw32-libopenssl '
                        + 'mingw32-libz '
                        + 'mingw32-mgwport '
                        + 'mingw32-tk '
                        + 'mingw32-unzip '
                        ;

    // List packages needed to (re-)build the binaries Git depends on, or those for convenience tools.
    RecommendedPackages = 'msys-bison '
                        + 'msys-coreutils-ext '
                        + 'msys-gcc '
                        + 'msys-libcrypt '
                        + 'msys-libexpat '
                        + 'msys-libffi '
                        + 'msys-libminires '
                        + 'msys-libopenssl '
                        + 'msys-mktemp '
                        + 'msys-pcre '
                        + 'msys-rsync '
                        + 'msys-vim '
                        + 'msys-zlib '

                        + 'mingw32-gdb '
                        + 'mingw32-gnupg '
                        + 'mingw32-ntldd '
                        ;

var
    PackagesPage:TWizardPage;
    PackagesList:TNewCheckListBox;

function IsPortableMode:Boolean;
begin
    Result:=(ExpandConstant('{param:portable|0}')='1');
end;

procedure InitializeWizard;
var
    PrevPageID:Integer;
begin
    PrevPageID:=wpInstalling;

    PackagesPage:=CreateCustomPage(
        PrevPageID,
        'Package selection',
        'Which packages would like to have installed?'
    );
    PrevPageID:=PackagesPage.ID;

    PackagesList:=TNewCheckListBox.Create(PackagesPage);
    with PackagesList do begin
        Parent:=PackagesPage.Surface;
        Width:=PackagesPage.SurfaceWidth;
        Height:=PackagesPage.SurfaceHeight;
    end;
end;

procedure CurStepChanged(CurStep:TSetupStep);
var
    Packages:TArrayOfString;
    NumPackages,i,Level,p:Integer;
    Msg,Hierarchy,Group,PrevPath,Path,PackageName,PackageClass:String;
    Required,Recommended:Boolean;
begin
    // Initialize the package selection page just after the actual installation finishes.
    if CurStep<>ssPostInstall then begin
        Exit;
    end;

    // Note that NumPackages is the number of unique packages while GetArrayLength(Packages)
    // is the number of entries in the tree (which is greater or equal).
    NumPackages:=GetAvailablePackages(Packages);

    if NumPackages=0 then begin
        // This should never happen as we bundle the package catalogue files with the installer.
        Msg:='No packages found, please report this as an error to the developers.';
        SuppressibleMsgBox(Msg,mbError,MB_OK,IDOK);
        Log('Error: '+Msg);
        Exit;
    end;

    PackagesPage.Description:='Which of these '+IntToStr(NumPackages)+' packages would like to have installed?';

    for i:=0 to GetArrayLength(Packages)-1 do begin
        Hierarchy:=ExtractFilePath(Packages[i]);

        // Create only those groups of the hierarchy that were not previously created.
        Level:=0;
        p:=Pos('\',Hierarchy);
        while p>0 do begin
            Group:=Copy(Hierarchy,1,p-1);
            Path:=AddBackslash(Path)+Group;

            if Pos(Path,PrevPath)=0 then begin
                // Set a group entry's object to non-NIL to be able to easily distinguish them from package entries.
                PackagesList.AddCheckBox(Group,'',Level,False,True,False,True,PackagesList);
            end;

            Delete(Hierarchy,1,p);
            Level:=Level+1;

            p:=Pos('\',Hierarchy);
        end;
        PrevPath:=Path;
        Path:='';

        // Create the package entry.
        PackageName:=ExtractFileName(Packages[i]);
        PackageClass:='';
        p:=Pos('@',PackageName);
        if p>0 then begin
            PackageClass:=Copy(PackageName,p+1,Length(PackageName));
            Delete(PackageName,p,Length(PackageName));
        end;

        // Enclose the package name by spaces for the lookup as one name may be a substring of another name.
        Required:=(Pos(' '+PackageName+' ',' '+RequiredPackages+' ')>0);
        Recommended:=(Pos(' '+PackageName+' ',' '+RecommendedPackages+' ')>0);
        PackagesList.AddCheckBox(PackageName,PackageClass,Level,Required or Recommended,not Required,False,True,nil);
    end;
end;

function GetSelectedPackages:String;
var
    i:Integer;
begin
    if PackagesList=nil then begin
        Exit;
    end;

    for i:=0 to PackagesList.Items.Count-1 do begin
        if PackagesList.Checked[i] and (PackagesList.ItemObject[i]=nil) then begin
            Result:=Result+' '+PackagesList.ItemCaption[i];
        end;
    end;
end;

function GetMinGWGetLog:String;
begin
    Result:=ExpandConstant('{param:log-mingw-get}');
end;

function NextButtonClick(CurPageID:Integer):Boolean;
var
    Msg,Packages,MinGWGet,MinGWGetLog,PowerShell,HomePath:String;
    Home:TArrayOfString;
    ResultCode:Integer;
begin
    Result:=True;

    if (CurPageID=wpSelectDir) and (Pos(' ',WizardDirValue)>0) then begin
        Msg:='The installation directory must not contain any spaces, please choose a different one.';
        SuppressibleMsgBox(Msg,mbError,MB_OK,IDOK);
        Log('Error: '+Msg);
        Result:=False;
    end else if CurPageID=PackagesPage.ID then begin
        Packages:=GetSelectedPackages;
        if Length(Packages)>0 then begin
            Log('Installing the following packages: '+Packages);

            // Do not run "mingw-get update" here because it takes quite a long time to download the catalogue files.
            MinGWGet:=WizardDirValue+'\mingw\bin\mingw-get.exe';
            MinGWGetLog:=GetMinGWGetLog;

            if Length(MinGWGetLog)>0 then begin
                PowerShell:=ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
                if FileExists(PowerShell) then begin
                    Exec(PowerShell,'"'+MinGWGet+' install '+Packages+' 2>&1 | %{ \"$_\" } | tee '+MinGWGetLog+'"',WizardDirValue,SW_SHOW,ewWaitUntilTerminated,ResultCode);
                end else begin
                    Log('Error: Cannot create log file for mingw-get, PowerShell not found.');
                    MinGWGetLog:='';
                end;
            end;

            if Length(MinGWGetLog)=0 then begin
                Exec(MinGWGet,'install '+Packages,WizardDirValue,SW_SHOW,ewWaitUntilTerminated,ResultCode);
            end;

            if ResultCode<>0 then begin
                Msg:='mingw-get returned an error while installing packages. You may want to look into this when starting the development environment.';
                SuppressibleMsgBox(Msg,mbError,MB_OK,IDOK);
                Log('Error: '+Msg);
            end;

            // Set the HOME environment variable if not set. This is better than changing /etc/profile
            // because that file will be overwritten on msys-core upgrades.
            HomePath:=ExpandConstant('{%HOME}');
            if not DirExists(HomePath) then begin
                HomePath:=ExpandConstant('{%HOMEDRIVE}')+ExpandConstant('{%HOMEPATH}');
                if not DirExists(HomePath) then begin
                    HomePath:=ExpandConstant('{%USERPROFILE}');
                end;
                if DirExists(HomePath) then begin
                    SetArrayLength(Home,1);
                    Home[0]:=HomePath;
                    SetEnvStrings('HOME',False,False,Home);
                end;
            end;

            Result:=True;
        end else begin
            Result:=(SuppressibleMsgBox('You have not selected any packages. Are you sure you want to continue?',mbConfirmation,MB_YESNO,IDYES)=IDYES);
        end;
    end;
end;

function ShouldSkipPage(PageID:Integer):Boolean;
begin
    if (PageID=PackagesPage.ID) and (PackagesList.Items.Count=0) then begin
        // This should never happen as we bundle the package catalogue files with the installer.
        Result:=True;
    end else begin
        Result:=False;
    end;
end;

procedure CurPageChanged(CurPageID:Integer);
begin
    if CurPageID=wpInfoBefore then begin
        if WizardForm.NextButton.Enabled then begin
            WizardForm.ActiveControl:=WizardForm.NextButton;
        end;
    end;
end;

const
    Confirmation='You will loose those when uninstalling. Are you sure that you want to continue?';

function InitializeUninstall:Boolean;
var
    RepoNames:array of String;
    AppDir,CmdDir,TmpFile,RepoName,RepoDir:String;
    i,ResultCode,Size:Integer;
    UnpushedCommits:Boolean;
begin
    Result:=False;

    SetArrayLength(RepoNames,2);
    RepoNames[0]:='git';
    RepoNames[1]:='packages';

    AppDir:=ExpandConstant('{app}');
    CmdDir:=ExpandConstant('{cmd}');
    TmpFile:=ExpandConstant('{tmp}')+'\unpushed.log';

    for i:=0 to Length(RepoNames)-1 do begin
        RepoName:=RepoNames[i];
        RepoDir:=AppDir+'\'+RepoName;

        if FileExists(RepoDir+'\.git\refs\stash') then begin
            if MsgBox('You have stashed changes in the "'+RepoName+'" repository. '+Confirmation,mbConfirmation,MB_YESNO)=IDNO then begin
                Exit;
            end
        end;

        if Exec(AppDir+'\mingw\bin\git.exe','diff --quiet',RepoDir,SW_HIDE,ewWaitUntilTerminated,ResultCode) then begin
            if ResultCode<>0 then begin
                if MsgBox('You have unstaged changes in the "'+RepoName+'" repository. '+Confirmation,mbConfirmation,MB_YESNO)=IDNO then begin
                    Exit;
                end
            end;
        end;

        if Exec(AppDir+'\mingw\bin\git.exe','diff --quiet --cached',RepoDir,SW_HIDE,ewWaitUntilTerminated,ResultCode) then begin
            if ResultCode<>0 then begin
                if MsgBox('You have uncommitted changes in the "'+RepoName+'" repository. '+Confirmation,mbConfirmation,MB_YESNO)=IDNO then begin
                    Exit;
                end
            end;
        end;

        if Exec(CmdDir,'/c '+AppDir+'\mingw\bin\git.exe log --branches --not --remotes > '+TmpFile,RepoDir,SW_HIDE,ewWaitUntilTerminated,ResultCode) then begin
            if ResultCode=0 then begin
                UnpushedCommits:=FileSize(TmpFile,Size) and (Size>0);
                DeleteFile(TmpFile);
                if UnpushedCommits and (MsgBox('You have unpushed commits in the "'+RepoName+'" repository. '+Confirmation,mbConfirmation,MB_YESNO)=IDNO) then begin
                    Exit;
                end
            end;
        end;
    end;

    Result:=true;
end;
