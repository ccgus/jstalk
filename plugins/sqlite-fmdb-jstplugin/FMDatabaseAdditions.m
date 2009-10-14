//
//  JSTDatabaseAdditions.m
//  fmkit
//
//  Created by August Mueller on 10/30/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@implementation JSTDatabase (JSTDatabaseAdditions)

#define RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(type, sel)             \
va_list args;                                                        \
va_start(args, query);                                               \
JSTResultSet *resultSet = [self executeQuery:query arguments:args];   \
va_end(args);                                                        \
if (![resultSet next]) { return (type)0; }                           \
type ret = [resultSet sel:0];                                        \
[resultSet close];                                                   \
[resultSet setParentDB:nil];                                         \
return ret;


- (NSString*)stringForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSString *, stringForColumnIndex);
}

- (int)intForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(int, intForColumnIndex);
}

- (long)longForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(long, longForColumnIndex);
}

- (BOOL)boolForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(BOOL, boolForColumnIndex);
}

- (double)doubleForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(double, doubleForColumnIndex);
}

- (NSData*)dataForQuery:(NSString*)query, ...; {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSData *, dataForColumnIndex);
}


//From Phong Long:
//sometimes you want to be able generate queries programatically
//with an arbitrary number of arguments, as well as be able to bind
//them properly. this method allows you to pass in a query string with any
//number of ?, then you pass in an appropriate number of objects in an NSArray
//to executeQuery:arguments:

//this technique is being implemented as described by Matt Gallagher at
//http://cocoawithlove.com/2009/05/variable-argument-lists-in-cocoa.html

- (id)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    
#ifdef __LP64__
    
    NSLog(@"executeQuery:withArgumentsInArray: does not work when compiled as 64 bit");
    // got a patch?  send it gus@flyingmeat.com
    
    return 0x00;
    
#else
	id returnObject;
	
	//also need make sure that everything in arguments is an Obj-C object
	//or else argList will be the wrong size
	NSUInteger argumentsCount = [arguments count];
	char *argList = (char *)malloc(sizeof(id *) * argumentsCount);
	[arguments getObjects:(id *)argList];
	
	returnObject = [self executeQuery:sql arguments:argList];
	
	free(argList);
	
	return returnObject;
#endif
}

- (BOOL) executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {
    
#ifdef __LP64__
    
    NSLog(@"executeUpdate:withArgumentsInArray: does not work when compiled as 64 bit");
    // got a patch?  send it gus@flyingmeat.com
    
    return 0x00;
    
#else
    
    BOOL returnBool;
	
	//also need make sure that everything in arguments is an Obj-C object
	//or else argList will be the wrong size
	NSUInteger argumentsCount = [arguments count];
	char *argList = (char *)malloc(sizeof(id *) * argumentsCount);
	[arguments getObjects:(id *)argList];
	
	returnBool = [self executeUpdate:sql arguments:argList];
	
	free(argList);
	
	return returnBool;
#endif
}


//check if table exist in database (patch from OZLB)
- (BOOL) tableExists:(NSString*)tableName {
    
    BOOL returnBool;
    //lower case table name
    tableName = [tableName lowercaseString];
    //search in sqlite_master table if table exists
    JSTResultSet *rs = [self executeQuery:@"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?", tableName];
    //if at least one next exists, table exists
    returnBool = [rs next];
    //close and free object
    [rs close];
    
    return returnBool;
}

//get table with list of tables: result colums: type[STRING], name[STRING],tbl_name[STRING],rootpage[INTEGER],sql[STRING]
//check if table exist in database  (patch from OZLB)
- (JSTResultSet*) getDataBaseSchema:(NSString*)tableName {
    
    //lower case table name
    tableName = [tableName lowercaseString];
    //result colums: type[STRING], name[STRING],tbl_name[STRING],rootpage[INTEGER],sql[STRING]
    JSTResultSet *rs = [self executeQuery:@"SELECT type, name, tbl_name, rootpage, sql FROM (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master) WHERE type != 'meta' AND name NOT LIKE 'sqlite_%' ORDER BY tbl_name, type DESC, name"];
    
    return rs;
}

@end
