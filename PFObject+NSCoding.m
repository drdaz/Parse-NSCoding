//
//  PFObject+NSCoding.m
//  UpdateZen
//
//  Created by Martin Rybak on 2/3/14.
//  Copyright (c) 2014 UpdateZen. All rights reserved.
//

#import "PFObject+NSCoding.h"
#import "PFObjectPrivate.h"
#import "NSObject+Properties.h"

@implementation PFObject (NSCoding)

@dynamic createdAt;
@dynamic updatedAt;

#define kPFObjectObjectId @"___PFObjectId"
#define kPFObjectAllKeys @"___PFObjectAllKeys"
#define kPFObjectClassName @"___PFObjectClassName"

- (void)encodeWithCoder:(NSCoder*)encoder
{
	//Serialize Parse-specific values
	[encoder encodeObject:[self objectId] forKey:kPFObjectObjectId];
	[encoder encodeObject:[self parseClassName] forKey:kPFObjectClassName];
	[encoder encodeObject:[self allKeys] forKey:kPFObjectAllKeys];
	
	//Serialize all non-nil Parse properties
	//[self allKeys] returns only the @dynamic properties that are not nil
	for (NSString* key in [self allKeys]) {
		id value = self[key];
        if (![value isMemberOfClass:[PFRelation class]]) {
            [encoder encodeObject:value forKey:key];
        }
        else
        {
            NSLog(@"**** WARNING! ****\n You tried to persist a PFRelation. This is unsupported in this NSCoding implementation.");
        }
	}
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
	//Deserialize Parse-specific values
    NSString* objectId = [aDecoder decodeObjectForKey:kPFObjectObjectId];
	NSString* parseClassName = [aDecoder decodeObjectForKey:kPFObjectClassName];
	NSArray* allKeys = [aDecoder decodeObjectForKey:kPFObjectAllKeys];
	
	if ([self isMemberOfClass:[PFObject class]]) {
		//If this is a PFObject, recreate the object using the Parse class name and objectId
		self = [PFObject objectWithoutDataWithClassName:parseClassName objectId:objectId];
	}
	else {
		//If this is a PFObject subclass, recreate the object using PFSubclassing
		self = [[self class] objectWithoutDataWithObjectId:objectId];
	}
	
	if (self) {
		//Deserialize all non-nil Parse properties
		for (NSString* key in allKeys) {
            id obj = [aDecoder decodeObjectForKey:key];
            if (obj) {
                self[key] = obj;
            }
		}
		
		//Deserialize all nil Parse properties with NSNull
		//This is to prevent an NSInternalConsistencyException when trying to access them in the future
		//Loop through all dynamic properties that aren't in [self allKeys]
		NSDictionary* allParseProperties = [self dynamicProperties];
		for (NSString* key in allParseProperties) {
			if (![allKeys containsObject:key]) {
				self[key] = [NSNull null];
			}
		}
    }
    
    return self;
}

@end
