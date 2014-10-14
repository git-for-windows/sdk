Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)

command = "cmd /c " & dir & "\msys.bat"
If WScript.Arguments.Length > 0 Then command = command & " " & WScript.Arguments(0)

Set shell = CreateObject("WScript.Shell")
shell.Run command, 0, false
