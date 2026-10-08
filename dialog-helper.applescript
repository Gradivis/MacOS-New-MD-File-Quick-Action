use framework "Foundation"
use framework "AppKit"
use scripting additions

on run
	set outputPath to (system attribute "NEW_MD_OUTPUT_PATH")

	set theAlert to current application's NSAlert's new()
	theAlert's setMessageText:"New MD File"
	theAlert's setInformativeText:"Enter a name for the new file."
	(theAlert's addButtonWithTitle:"Create")
	(theAlert's addButtonWithTitle:"Cancel")

	set inputField to current application's NSTextField's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 200, 22))
	inputField's setEditable:true
	inputField's setSelectable:true
	inputField's setStringValue:""

	set suffixLabel to current application's NSTextField's alloc()'s initWithFrame:(current application's NSMakeRect(204, 0, 40, 22))
	suffixLabel's setEditable:false
	suffixLabel's setSelectable:false
	suffixLabel's setBezeled:false
	suffixLabel's setDrawsBackground:false
	suffixLabel's setStringValue:".md"

	set accessory to current application's NSView's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 244, 22))
	(accessory's addSubview:inputField)
	(accessory's addSubview:suffixLabel)

	theAlert's setAccessoryView:accessory

	current application's NSApp's activateIgnoringOtherApps:true
	set theResult to theAlert's runModal()

	set baseName to ""
	if theResult is (current application's NSAlertFirstButtonReturn) then
		set baseName to (inputField's stringValue()) as text
	end if

	set nsOut to current application's NSString's stringWithString:baseName
	(nsOut's writeToFile:outputPath atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(missing value))

	quit
end run
