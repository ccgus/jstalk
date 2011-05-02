# we rewrite the class names, so that we don't get conflicts in folks who are using FMDatabase already in their applications.

for i in *.h *.m; do
    sed -e "s#FMDatabase#JSTDatabase#g" $i | sed -e "s#FMResultSet#JSTResultSet#g" | sed -e "s#FMStatement#JSTStatement#g" | sed -e "s#JSTResultSet.h#FMResultSet.h#g" | sed -e "s#JSTDatabase.h#FMDatabase.h#g" | sed -e "s#JSTDatabaseAdditions.h#FMDatabaseAdditions.h#g" > junk
    mv junk $i
    
done


