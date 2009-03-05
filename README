What is JSTalk?
---------------

JSTalk is how I imagine AppleScript would be done today, if it was written by a Cocoa programmer who was smitten by Cocoa and Objective-C.

JSTalk's goal is not to kill off or replace AppleScript, but to provide a compelling alternative by blending together existing technologies.

JSTalk comes with a command line tool (jstalk), an editor (JSTalk Editor), and a framework that programmers can include in their application to add scripting support with a single line of code.

And finally, JSTalk is open source.  So if there is something wrong, or it's not running the way you expect it, you get the chance to peek under the covers and understand what's going on.  Here's the subversion repository: http://flycode.googlecode.com/svn/trunk/jstalk/

You can also download JSTalk binaries:
http://www.flyingmeat.com/download/private/JSTalkPreview.zip





A sane object model for programmers, using Distributed Objects.
-----------------------------------------------------------------------

Adding AppleScript support to your Cocoa application is a PITA, to put it bluntly.  Sure, it's easy to do simple tasks, but once you move away from sample code territory, you are on your own and in many cases, in a world of hurt.

Why not do something more modern?  Why not add scripting support the Cocoa way?  Here's how to make your app scriptable via JSTalk:

a) Come up with an object model for your application, using standard Cocoa classes.  In many cases this is already done, by virtue of writing a maintainable application.

b) Expose a "root" object to JSTalk, via Distributed Objects.  In most cases, this will just be NSApplication.  If choose to use the JSTalk framework, it's just one line of code:  [JSTalk listen];

c) Document what methods, properties, and objects you support.  There's no magic xml files to fill out!

Exposing your model this way lets your app be scripted from Cocoa, Python, Ruby, and JavaScript- any language that can reach over to Cocoa.  And no magic.  Did I mention that part yet?





How does JSTalk (the language) work?
------------------------------------

JSTalk is built on top of Apple's JavaScriptCore, the same JavaScript engine that powers Safari.  So when you write in JSTalk, you are really writing JavaScript.

JSTalk also includes a bridge which lets you access Apple's Cocoa frameworks from JavaScript.  This means you have a ton wonderful classes and functions you can use in addition to the standard JavaScript library.

JSTalk also adds a preprocessor to make using the Cocoa frameworks friendlier.  Since Cocoa is written in Objective-C, you get a different syntax that what you'd normally encounter in JavaScript for calling methods.  For example, here's some typical Cocoa code for writing a string to a file:

NSString *someContent = @"Hello World!";
NSString *path = @"/tmp/foo.txt";
[[someContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];

And here is how it would normally look in a bridged scripting language:

var someContent = NSString.stringWithString_("Hello World!")
var path = "/tmp/foo.txt"
someContent.dataUsingEncoding_(NSUTF8StringEncoding).writeToFile_atomically_(path, true)

This is a valid script in JSTalk, but it doesn't look very nice.  For instance, there are lots of underscores in the method names, and you don't get the nested message passing like you do in Objective-C.  To fix this quandary, JSTalk adds a light preprocessor which will allow you to use Objective-C message syntax like so:

var someContent = @"Hello World!"
var path = @"/tmp/foo.txt"
[[someContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:true]





But no apps out there currently support JSTalk!
-----------------------------------------------

Applications can also be scripted using Cocoa's Script Bridge class, SBApplication.  Here's an example:

[[SBApplication application:"iChat"] setStatusMessage:"Happy (funball)"];

Although this is great to have, it's not the same as an application natively support JSTalk over DO.  Anything more than simple tasks using SBApplication tends to be a little more than difficult.




But it doesn't do X:
--------------------

Let us know by sending an email to gus@flyingmeat.com.





TODO:
-----

Nicer editing features.
An "Edit in External Editor" command, so you can use BBEdit or whatever to edit your script.
The loading of ".jstalkextra" bundles.  This would be a collection of classes that JSTalk would load, which adds additional functionality to the standard Cocoa classes.  Think helper classes and categories.
A debugger would be killer.
JSLint built into it.





Credits:
--------

As said earlier, JSTalk is a blend of existing technologies, and has very little original code in it.  Here's what it uses:

JSTalk Icon, from Brad Ellis.
JavaScriptCore, from Apple and the WebKit team.
JSCocoa, from Patrick Geiller: http://inexdo.com/JSCocoa
TDParseKit, from Todd Ditchendorf: http://ditchnet.org/tdparsekit/
NoodleLineNumberView, from Paul Kim / Noodlesoft: http://www.noodlesoft.com/blog/2008/10/05/displaying-line-numbers-with-nstextview/
TextExtras, from Mike Ferris: http://www.lorax.com/FreeStuff/TextExtras.html
