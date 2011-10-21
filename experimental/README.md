This is Gus's rewrite of the js bridge.  It's probably a bad idea, and very broken.

This is not being done on a branch because Gus started doing that and kept on screwing things up oh lordy do I hate git.


Notes from Gus, for Gus:

Oct 2, 2011:
The current plan for the new parser is to preprocess jstalk/objc messages into jstobjc_msgSend, since that's reasonably unique and we can special case things in there for calls that return floats or structs or whatever.  So '[NSString string]' would become 'jstobjc_msgSend(NSString, "string")', '[Foo isEqualTo:"foo"]' objc_msgSend(Foo, "isEqualToString:", "foo")

What's the best way to setup tests for this though?  I want them written in JSTalk itself, but that gets a bit tricky.  So currently that's what I'm working on exploring.

There's a ton of unfinished code laying around, and since I tend to be scatterbrained it should probably be ignored.  It'll be rewritten, as this is currently a playground for my ideas.