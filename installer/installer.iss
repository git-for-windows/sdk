#define APP_NAME    'mingwGitDevEnv'
#define APP_VERSION '0.1'

[Setup]

; Compiler-related
Compression=lzma2/ultra
LZMAUseSeparateProcess=yes
OutputBaseFilename={#APP_NAME+'-v'+APP_VERSION}
OutputDir=.
SolidCompression=yes
SourceDir=..

; Installer-related
AppName={#APP_NAME}
AppVersion={#APP_VERSION}
DefaultDirName={sd}\{#APP_NAME}
DisableReadyPage=yes
PrivilegesRequired=none

; Cosmetic
SetupIconFile=resources\git.ico
WizardImageBackColor=clWhite
WizardImageStretch=no
WizardImageFile=resources\git-large.bmp
WizardSmallImageFile=resources\git-small.bmp

[Files]

Source: root\*; DestDir: {app}; Flags: recursesubdirs

[Run]

Filename: "{app}\msys.bat"; Description: "Start the development environment"; Flags: postinstall 

[Code]

#include "xmlparser.inc.iss"

const
    RequiredPackages='msys-base msys-lndir msys-patch msys-perl msys-wget mingw32-gcc mingw32-libz';

var
    PackagesPage:TWizardPage;
    PackagesList:TNewCheckListBox;

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
    Hierarchy,Group,PrevPath,Path,PackageName,PackageClass:String;
    Required:Boolean;
begin
    if CurStep<>ssPostInstall then begin
        Exit;
    end;

    // Note that NumPackages is the number of unique packages while GetArrayLength(Packages)
    // is the number of entries in the tree (which is greater or equal).
    NumPackages:=GetAvailablePackages(Packages);

    if NumPackages=0 then begin
        // This should never happen as we bundle the package catalogue files with the installer.
        MsgBox('No packages found, please report this as an error to the developers.',mbError,MB_OK);
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
            Inc(Level);

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
        PackagesList.AddCheckBox(PackageName,PackageClass,Level,Required,not Required,False,True,nil);
    end;
end;

function GetCheckedPackages:String;
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

function NextButtonClick(CurPageID:Integer):Boolean;
var
    Packages:String;
    ResultCode:Integer;
begin
    Result:=True;

    if (CurPageID=wpSelectDir) and (Pos(' ',WizardDirValue)>0) then begin
        MsgBox('The installation directory must not contain any spaces, please choose a different one.',mbError,MB_OK);
        Result:=False;
    end else if CurPageID=PackagesPage.ID then begin
        Packages:=GetCheckedPackages;
        if Length(Packages)>0 then begin
            Log('Installing the following packages: '+Packages);
            Exec(WizardDirValue+'\mingw\bin\mingw-get.exe','install '+Packages,'',SW_SHOW,ewWaitUntilTerminated,ResultCode);
            Result:=(ResultCode=0);
        end else begin
            Result:=(MsgBox('You have not selected any packages. Are you sure you want to continue?',mbConfirmation,MB_YESNO)=IDYES);
        end;
    end;
end;

function ShouldSkipPage(PageID:Integer):Boolean;
begin
    if (PageID=PackagesPage.ID) and (PackagesList.Items.Count=0) then begin
        Result:=True;
    end else begin
        Result:=False;
    end;
end;