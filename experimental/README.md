This is Gus's rewrite of the js bridge.  It's probably a bad idea, and very broken.

This is not being done on a branch because Gus started doing that and kept on screwing things up oh lordy do I hate git.


Notes from Gus, for Gus:

Oct 29, 2011:
Hey Gus- you've got the bit where jst_msgSend creates a reusable JSTFuction, and right now you are working on calling plain-jane objc messages.  Since you are caching that JSTFuction, you've got to remember to clear it out after you are done with it.

Maybe you should cache all calls into objc?

Oct 24, 2011:
There's a ton of unfinished code laying around, and since I tend to be scatterbrained it should probably be ignored.  It'll be rewritten, as this is currently a playground for my ideas.

## Random Things for Gus to Fix:
Oct 23, 2011:
Hey, mixing TDTokens and JSTPSymbolGroup(s) together in JSTPSymbolGroup's _args array is a really bad idea.  What you need to do is make a common subclass for those two, so you don't have to keep on checking if you're working with a TDToken first in description.