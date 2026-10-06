Set objShell = CreateObject("WScript.Shell")
objShell.CurrentDirectory = "D:\test"
exitCode = objShell.Run("cmd /c git add . & git commit -m ""auto update"" & git push", 0, True)
If exitCode = 0 Then
    MsgBox "Push successful!" & vbCrLf & vbCrLf & "GitHub Pages will update in 1-2 minutes.", 64, "GitHub Push"
Else
    MsgBox "Push failed (exit code " & exitCode & ")." & vbCrLf & vbCrLf & "Run git push manually to see the error.", 16, "GitHub Push"
End If