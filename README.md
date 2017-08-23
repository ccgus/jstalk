*This project has been superceeded by [CocoaScript](https://github.com/ccgus/CocoaScript), and you should head there instead.*

What is JSTalk?
===============

JSTalk is how I imagine AppleScript would be done today, if it was written by a Cocoa programmer who was smitten by Cocoa and Objective-C.

JSTalk's goal is not to kill off or replace AppleScript, but to provide a compelling alternative by blending together existing technologies.

JSTalk comes with a command line tool (jstalk), an editor (JSTalk Editor), and a framework that programmers can include in their application to add scripting support with a single line of code.

And finally, JSTalk is open source. So if there is something wrong, or it's not running the way you expect it, you get the chance to peek under the covers and understand what's going on.

Here's the git repository: <http://github.com/ccgus/jstalk/tree/master>

You can also download JSTalk binaries: <http://www.flyingmeat.com/download/latest/JSTalkPreview.zip>



A sane object model for programmers, using Distributed Objects.
---------------------------------------------------------------

Adding AppleScript support to your Cocoa application is a PITA, to put it bluntly. Sure, it's easy to do simple tasks, but once you move away from sample code territory, you are on your own and in many cases, in a world of hurt.

Why not do something more modern? Why not add scripting support the Cocoa way? Here's how to make your app scriptable via JSTalk:

1. Come up with an object model for your application, using standard Cocoa classes. In many cases this is already done, by virtue of writing a maintainable application.

2. Expose a "root" object to JSTalk, via Distributed Objects. In most cases, this will just be NSApplication. If you choose to use the JSTalk framework, it's just one line of code: [JSTalk listen];

3. Document what methods, properties, and objects you support. There's no magic xml files to fill out!

Exposing your model this way lets your app be scripted from Cocoa, Python, Ruby, and JavaScript- any language that can reach over to Cocoa. And no magic. Did I mention that part yet?



How does JSTalk (the language) work?
------------------------------------

JSTalk is built on top of Apple's JavaScriptCore, the same JavaScript engine that powers Safari. So when you write in JSTalk, you are really writing JavaScript.

JSTalk also includes a bridge which lets you access Apple's Cocoa frameworks from JavaScript. This means you have a ton wonderful classes and functions you can use in addition to the standard JavaScript library.

JSTalk also adds a preprocessor to make using the Cocoa frameworks friendlier. Since Cocoa is written in Objective-C, you get a different syntax than what you'd normally encounter in JavaScript for calling methods. For example, here's some typical Cocoa code for writing a string to a file:

    NSString *someContent = @"Hello World!";
    NSString *path = @"/tmp/foo.txt";
    [[someContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];

And here is how it would normally look in a bridged scripting language:

    var someContent = NSString.stringWithString_("Hello World!")
    var path = "/tmp/foo.txt"
    someContent.dataUsingEncoding_(NSUTF8StringEncoding).writeToFile_atomically_(path, true)

This is a valid script in JSTalk, but it doesn't look very nice. For instance, there are lots of underscores in the method names, and you don't get the nested message passing like you do in Objective-C. To fix this quandary, JSTalk adds a light preprocessor which will allow you to use Objective-C message syntax like so:

    var someContent = @"Hello World!"
    var path = @"/tmp/foo.txt"
    [[someContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:true]



Give me an example
------------------

Here's an AppleScript example, for adding a new rectangle object to a sketch document:

    tell application "Sketch"
      tell document 1
        set o to make new box
        set width of o to 100
        set height of o to 100
        set stroke thickness of o to 10
      end tell
    end tell

And here's how you do it with JSTalk, using a doctored version of Sketch(6 lines of code, + the JSTalk framework):

    var sketch = [JSTalk application:"Sketch"];
    var doc = [sketch orderedDocuments][0]
    var rectangle = [doc makeNewBox];
    
    [rectangle setWidth:100];
    [rectangle setHeight:100];
    [rectangle setXPosition:100];
    [rectangle setYPosition:100];


If you aren't a fan of the optional bracket syntax, you can also write the script this way:

    var sketch = JSTalk.application_("Sketch");
    var doc = sketch.orderedDocuments()[0]
    var rectangle = doc.makeNewBox();
    
    rectangle.setWidth_(100);
    rectangle.setHeight_(100);
    rectangle.setXPosition_(100);
    rectangle.setYPosition_(100);



But no apps out there currently support JSTalk!
-----------------------------------------------

Applications can also be scripted using Cocoa's Script Bridge class, SBApplication. Here's an example:

    [[SBApplication application:"iChat"] setStatusMessage:"Happy (funball)"];

Although this is great to have, it's not the same as an application natively support JSTalk over DO. Anything more than simple tasks using SBApplication tends to be a little more than difficult.



JSTalk Plugins
--------------

Aka, loadable bundles which add functionality to JSTalk, via helper classes, wrappers, and categories.

JSTalk comes with some standard helper categories (which you can currently find in JSTalkExtras.m), but it will also look in your ~/Library/Application Support/JSTalk/Plug-ins/ folder, and load any .jstplugin bundles it sees. You can turn this off in your application if you don't like that idea, via [JSTalk setShouldLoadJSTPlugins:NO];

There are two examples with JSTalk, one that just adds a category cocoa's string class: - [NSString reversedString]. The other example is "FMDB.jstplugin", which loads the FMDB SQLite classes, for use in JSTalk. This allows you to use sqlite to create, insert, update, etc, sql tables from JSTalk.



But it doesn't do X:
--------------------

Let us know by sending an email to <gus@flyingmeat.com>



Mailing list and bug reporting:
-------------------------------

- Developer mailing list: <http://groups.google.com/group/jstalk-dev>
- Bug reporting: <http://jstalk.lighthouseapp.com/projects/26692-jstalk/>

A user mailing list will pop up at some point, but we're not there yet.



Here's what is currently being worked on, what's broken:
--------------------------------------------------------

- No PPC support. The main reason is I don't have a testable PPC box lying around, but in theory it should work.
- The preprocessor isn't perfect, and it screws up on some code. For instance:

        [NSFullUserName() lowercaseString];

  Doesn't preprocess correctly. To find out if your script is being preprocessed incorrectly, just use the Script->Preprocess menu item to see what it spits out.



Checking out the code:
----------------------
	$ git clone git://github.com/ccgus/jstalk.git


TODO:
-----

- Nicer editing features.
- A debugger would be killer.



Credits:
--------

As said earlier, JSTalk is a blend of existing technologies, and has very little original code in it. Here's what it uses:

- JSTalk Icon, from Brad Ellis.
- JavaScriptCore, from Apple and the WebKit team.
- [JSCocoa](http://inexdo.com/JSCocoa), from Patrick Geiller.
- [TDParseKit](http://ditchnet.org/tdparsekit/), from Todd Ditchendorf.
- [NoodleLineNumberView](http://www.noodlesoft.com/blog/2008/10/05/displaying-line-numbers-with-nstextview/), from Paul Kim / Noodlesoft.
- [TextExtras](http://www.lorax.com/FreeStuff/TextExtras.html), from Mike Ferris.
