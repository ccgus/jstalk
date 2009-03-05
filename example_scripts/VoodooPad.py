import JSTalk

vp = JSTalk.application("VoodooPad Pro")

print(vp)

firstDoc = vp.orderedDocuments().objectAtIndex_(0)

for pageKey in firstDoc.keys():
    print(pageKey)
    
    page = firstDoc.pageForKey_(pageKey)
    
    if (page.uti() == "com.fm.page"):
        pageText = page.dataAsAttributedString().string()
        print(pageText)
    

