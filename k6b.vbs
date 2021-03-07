' USAGE: cscript k6b.vbs < sourcefile > outputfile
'   where sourcefile is a BF or my extended code file and
'   outputfile will be a vbs file so name it something.vbs
'  just run the vbs file FROM THE COMMAND PROMPT to execute your program
'  cscript outputfile.vbs
'
' also run "cscript /nologo /s" at least once so it won't put the 
' the cscript logo in your output file

' code constants
' double quote (") is there
validCode = "[]<>,.+-!@0_IVXLC(){}?*"""
mathCode = "+-0_IVXLC"
incdecCode = "+-"
moveCode = "<>"

Dim oTab
Set oTab = New TabLevel

' preamble
'    30000 locations
PrintString "DIM a(30000),t,p,i,m" 
PrintString ""
'    make sure they're zero
PrintString "for i = 1 to 30000"
PrintString "  a(i)=0"
PrintString "next"
'    pointer starts at zero
PrintString "p=0"
'    eight bit memory locations
PrintString "m=255"
PrintString ""

' read in the entire program
ProgramCode = wscript.StdIn.ReadAll
' get length of program
progsize = Len(ProgramCode)

' SubTotal of consecutive math instructions
stM = 0
' SubTotal of consecutive pointer movement instructions
stP = 0

' ip is the instruction pointer
for ip=1 to progsize

    'get current character in file
    cc=Mid(ProgramCode,ip,1)

    ' if it's not an instruction, get on to the next one
    if InStr(validCode,cc) then

        ' if we are still adding up math ops
        if stM <> 0 then
             ' and if the current character isn't another one
             if InStr(mathcode,cc) = 0 then
                ' then output the math instruction
                PrintString "a(p)=(a(p)+(" & CStr(stM)& ")) AND m"
                ' reset the math subtotal
                stM=0
            end if
        end if

        ' if we are still adding up pointer ops
        if stP <> 0 then
            ' and if the current character isn't another one
            if InStr(moveCode,cc) = 0 then
                ' then output the pointer instruction
                PrintString "p=p+(" & CStr(stP)& ")"
                ' reset the pointer subtotal
                stP=0
            end if
        end if

        ' lets handle the valid characters
        select case cc
            
            ' increment the math subtotal
            case "+"
                stM=stM+1

            case "I"
                stM=stM+1

            case "V"
                stM=stM+5

            case "X"
                stM=stM+10

            case "L"
                stM=stM+50

            case "C"
                stM=stM+100

            ' force stM to zero
            case "0","_"
                PrintString "a(p)=0"
                stM=0
    
            ' decrement the math subtotal
            case "-"
                stM=stM-1
            
            ' increment the pointer subtotal
            case ">"
                stP=stP+1
            
            ' decrement the pointer subtotal
            case "<"
                stP=stP-1

            ' store to temp
            case "!"
                PrintString "t=a(p)"

            ' fetch from temp
            case "@"
                PrintString "a(p)=t"

            ' comment handler
            case "*"
                ip=ip+1
                while Mid(ProgramCode,ip,1)<>"*"
                    ip=ip+1
                wend
            
            ' loop start
            case "["
                'special case - check for [-] or [+] and just zero the location
                if InStr(incdecCode, Mid(ProgramCode,ip+1,1)) _
                  and (Mid(ProgramCode,ip+2,1)="]") then
                    PrintString "a(p)=0"
                    ip=ip+2
                ' wasn't a zero so write out a loop start
                else
                    ' blank line before a loop start
                    wscript.StdOut.Write VBCRLF
                    PrintString "while (a(p) <> 0)"
                    'adjust the indentation
                    oTab.Inward
                end if

            ' Loop end
            case "]"
                'adjust the indentation
                oTab.Outward
                PrintString "wend"
                ' blank line after a loop
                PrintString ""

            case "("
                ' blank line before a loop start
                PrintString ""
                PrintString "if (a(p) <> 0) then"
                'adjust the indentation
                oTab.Inward
                
            case "{"
                ' blank line before a loop start
                PrintString ""
                PrintString "if (a(p) = 0) then"
                'adjust the indentation
                oTab.Inward
                
            ' Loop end
            case ")","}"
                'adjust the indentation
                oTab.Outward
                PrintString "end if"
                ' blank line after a loop
                PrintString ""
                
            ' write character to stdout
            case "?"
                ip=ip+1
                while Mid(ProgramCode,ip,1)<>"?"
                    cc = Mid(ProgramCode,ip,1)
                    PrintString "wscript.StdOut.Write chr("&Asc(cc)&")"
                    ip=ip+1
                wend
            
            ' store string in memory
            ' case double-quote
            case """"
                PrintString ""
                ip=ip+1
                while Mid(ProgramCode,ip,1)<> chr(34)
                    cc = Mid(ProgramCode,ip,1)
                    PrintString "a(p)=" & CStr(Asc(cc)) 
                    PrintString "p=p+1" 
                    ip=ip+1
                wend
                PrintString ""
            
            case "."
                PrintString "wscript.StdOut.Write chr(a(p))" 

            ' read character from stdin whilst checking for EOF
            case ","
                ' leaves value at location unchanged on end of input
                PrintString "if not(Wscript.StdIn.AtEndOfStream) then a(p)=Asc(wscript.StdIn.Read(1))"

        end select

    end if

next

' cleanup - if we're out of instructions but haven't printed yet
if stM <> 0 then
    PrintString "a(p)=(a(p)+(" & CStr(stM)& ")) AND m"
end if

if stP <> 0 then
    PrintString "p=p+(" & CStr(stP)& ")"
end if

' pass value in current location back as an exit code for batch file use
'wscript.StdOut.Write VBCRLF & "wscript.Quit(a(p))"
PrintString ""
PrintString "wscript.Quit(a(p))"

'print the current tab level string, the input string (can not be null) and then a newline
Sub PrintString(strIn)
    'tab in
    wscript.StdOut.Write oTab.Current 
    'write data
    wscript.StdOut.Write strIn 
    'new line
    wscript.StdOut.Write VBCRLF
End Sub

Class TabLevel
    'current tab level of output and indentation string
    ' makes for prettier output code
    private t
    public Current
    private iSpaces
        
    Private Sub Class_Initialize   ' Setup Initialize event.
        '   t - tab level
        t=0
        'how far to tab
        iSpaces = 2
        '   current indent string
        AdjustTabLevel(0)
    End Sub
    
    Private Sub AdjustTabLevel(iAmount)
        t=t+iAmount
        Current=Space(t)
    End Sub

    Public Property Get Inward()
        AdjustTabLevel(iSpaces)
    End Property

    Public Property Get Outward
        AdjustTabLevel(-iSpaces)
    End Property
    
End Class​