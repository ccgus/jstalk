This is Gus's rewrite of the js bridge.  It's probably a bad idea, and very broken.

This is not being done on a branch because Gus started doing that and kept on screwing things up oh lordy do I hate git.

## Notes from Gus, for Gus:

Oct 30, 2011:
Messages to objc are working, as are Foundation functions which don't take structs.  Structs are completely broken right now.  But hey- progress!

Oct 24, 2011:
There's a ton of unfinished code laying around, and since I tend to be scatterbrained it should probably be ignored.  It'll be rewritten, as this is currently a playground for my ideas.


## Random Things for Gus to Fix:

Jan 30, 2012:
Hey- regular expressions screw up the preprocessor and the syntax coloring:
title = "foo'"
title.replace(/['"]/g, ' ');

Oct 30, 2011:
Maybe you should cache all JSTFunction calls, so you don't have to lookup stuff a second time?

Oct 23, 2011:
Hey, mixing TDTokens and JSTPSymbolGroup(s) together in JSTPSymbolGroup's _args array is a really bad idea.  What you need to do is make a common subclass for those two, so you don't have to keep on checking if you're working with a TDToken first in description.



## Random Test things:

Make sure something like this is possible:

for (idx in args) {
    print("argument " + [args objectAtIndex:idx]);
}

var d = [NSMutableDictionary dictionary];

d['a'] = 'eh';
d['b'] = 'beee';

for (var key in d) {
    print(key + ": " + [d valueForKey:key]);
}