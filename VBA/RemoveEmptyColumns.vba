Sub RemoveEmptyColumns()
	Dim xEndCol As Long
	Dim I As Long
	Dim xDel As Boolean
	On Error Resume Next
	xEndCol = Cells.Find("*", SearchOrder:=xlByColumns, SearchDirection:=xlPrevious).Column
	If xEndCol = 0 Then
		MsgBox "There is no data on """ & ActiveSheet.Name & """ .", vbExclamation, "Remove Empty Columns"
		Exit Sub
	End If
	Application.ScreenUpdating = False
	For I = xEndCol To 1 Step -1
		If Application.WorksheetFunction.CountA(Columns(I)) <= 1 Then
			Columns(I).Delete
			xDel = True
		End If
	Next
	If xDel Then
		MsgBox "All blank column(s) and column(s) with only headers have been deleted", vbInformation, "Remove Empty Columns"
	Else
		MsgBox "There are no column(s) to delete", vbExclamation, "Remove Empty Columns"
	End If
	Application.ScreenUpdating = True
End Sub 
