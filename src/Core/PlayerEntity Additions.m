//
//  PlayerEntity Additions.m
/*
 *
 *  Oolite
 *
 *  Created by Giles Williams on Sat Apr 03 2004.
 *  Copyright (c) 2004 for aegidian.org. All rights reserved.
 *

Copyright (c) 2004, Giles C Williams
All rights reserved.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

You are free:

•	to copy, distribute, display, and perform the work
•	to make derivative works

Under the following conditions:

•	Attribution. You must give the original author credit.

•	Noncommercial. You may not use this work for commercial purposes.

•	Share Alike. If you alter, transform, or build upon this work,
you may distribute the resulting work only under a license identical to this one.

For any reuse or distribution, you must make clear to others the license terms of this work.

Any of these conditions can be waived if you get permission from the copyright holder.

Your fair use and other rights are in no way affected by the above.

*/

#import "PlayerEntity.h"
#import "PlayerEntity Additions.h"
#import "GuiDisplayGen.h"
#import "Universe.h"
#import "ResourceManager.h"
#import "AI.h"
#import "OOSound.h"

#ifdef GNUSTEP
#import "Comparison.h"
#endif

@implementation PlayerEntity (Scripting)

static NSString * mission_string_value;
static NSString * mission_key;

- (void) checkScript
{
	int i;

	[self setScript_target:self];

	if (debug)
		NSLog(@"----- checkScript");

	for (i = 0; i < [[script allKeys] count]; i++)
	{
		NSString *missionTitle = (NSString *)[[script allKeys] objectAtIndex:i];
		NSArray *mission = (NSArray *)[script objectForKey:missionTitle];
		mission_key = missionTitle;
		[self scriptActions: mission forTarget: self];
	}
}

- (void) scriptActions:(NSArray*) some_actions forTarget:(ShipEntity*) a_target
{
	PlayerEntity* player = (PlayerEntity *)[universe entityZero];
	int i;
	for (i = 0; i < [some_actions count]; i++)
	{
		NSObject* action = [some_actions objectAtIndex:i];
		if ([action isKindOfClass:[NSDictionary class]])
			[player checkCouplet:(NSDictionary *)action onEntity: a_target];
		if ([action isKindOfClass:[NSString class]])
			[player scriptAction:(NSString *)action onEntity: a_target];
	}
}

- (BOOL) checkCouplet:(NSDictionary *) couplet onEntity:(Entity *) entity
{
	NSArray *conditions = (NSArray *)[couplet objectForKey:@"conditions"];
	NSArray *actions = (NSArray *)[couplet objectForKey:@"do"];
	NSArray *else_actions = (NSArray *)[couplet objectForKey:@"else"];
	BOOL success = YES;
	int i;
	if (conditions == nil)
	{
		NSLog(@"SCRIPT ERROR no 'conditions' in %@ - returning YES.", [couplet description]);
		NSBeep();
		return success;
	}
	if (![conditions isKindOfClass:[NSArray class]])
	{
		NSLog(@"SCRIPT ERROR \"conditions = %@\" is not an array - returning YES.", [conditions description]);
		NSBeep();
		return success;
	}
	for (i = 0; (i < [conditions count])&&(success); i++)
		success &= [self scriptTestCondition:(NSString *)[conditions objectAtIndex:i]];
	if ((success) && (actions))
	{
		if (![actions isKindOfClass:[NSArray class]])
		{
			NSLog(@"SCRIPT ERROR \"actions = %@\" is not an array.", [actions description]);
			NSBeep();
		}
		else
		{
			for (i = 0; i < [actions count]; i++)
			{
				if ([[actions objectAtIndex:i] isKindOfClass:[NSDictionary class]])
					[self checkCouplet:(NSDictionary *)[actions objectAtIndex:i] onEntity:entity];
				if ([[actions objectAtIndex:i] isKindOfClass:[NSString class]])
					[self scriptAction:(NSString *)[actions objectAtIndex:i] onEntity:entity];
			}
		}
	}
	// now check if there's an 'else' to do if the couplet is false
	if ((!success) && (else_actions))
	{
		if (![else_actions isKindOfClass:[NSArray class]])
		{
			NSLog(@"SCRIPT ERROR \"else_actions = %@\" is not an array.", [else_actions description]);
			NSBeep();
		}
		else
		{
			for (i = 0; i < [else_actions count]; i++)
			{
				if ([[else_actions objectAtIndex:i] isKindOfClass:[NSDictionary class]])
					[self checkCouplet:(NSDictionary *)[else_actions objectAtIndex:i] onEntity:entity];
				if ([[else_actions objectAtIndex:i] isKindOfClass:[NSString class]])
					[self scriptAction:(NSString *)[else_actions objectAtIndex:i] onEntity:entity];
			}
		}
	}
	return success;
}

- (void) scriptAction:(NSString *) scriptAction onEntity:(Entity *) entity
{
	/*
	a script action takes the form of an expression:

	action[: string_expression]

	where 'action' is a  selector for the entity or (failing that) PlayerEntity
	optionally taking a NSString object ('string_expression') as a variable

	The special action 'set: mission_variable string_expression'

	is used to set a mission variable to the given string_expression

	*/
	NSMutableArray*	tokens = [Entity scanTokensFromString:scriptAction];
	NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
	NSString*   selectorString = nil;
	NSString*	valueString = nil;
	SEL			_selector;

	if (debug)
		NSLog(@"DEBUG ::::: scriptAction: \"%@\"", scriptAction);

	if ([tokens count] < 1)
	{
		NSLog(@"***** No scriptAction '%@'",scriptAction);
		return;
	}

	selectorString = (NSString *)[tokens objectAtIndex:0];

	if ([tokens count] > 1)
	{
		[tokens removeObjectAtIndex:0];
		valueString = [[tokens componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		valueString = [universe expandDescriptionWithLocals:valueString forSystem:[self system_seed] withLocalVariables:locals];
		if (debug)
 			NSLog(@"DEBUG ::::: after expansion: \"%@ %@\"", selectorString, valueString);
	}

	_selector = NSSelectorFromString(selectorString);

	if ((entity)&&([entity respondsToSelector:_selector]))
	{
		if ([selectorString hasSuffix:@":"])
			[entity performSelector:_selector withObject:valueString];
		else
			[entity performSelector:_selector];
		return;
	}

	if (![self respondsToSelector:_selector])
	{
		NSLog(@"***** PlayerEntity DOES NOT RESPOND TO scriptAction: \"%@\"", scriptAction);
		return;
	}

	if ([selectorString hasSuffix:@":"])
		[self performSelector:_selector withObject:valueString];
	else
		[self performSelector:_selector];
}

- (BOOL) scriptTestCondition:(NSString *) scriptCondition
{
	/*
	a script condition takes the form of an expression:

	testable_variable lessthan|equals|greaterthan constant_expression

	where testable_variable is an accessor selector for PlayerEntity returning an object
	that can be compared with the constant expression. They are supposed to take the form:
		variablename_type where type can be 'string', 'bool', or 'number'

	or where testable_variable is prefixed with 'mission_' in which case it is a 'mission variable'
	which is a string used by the script as a means of setting flags or indicating state

	The special test:

	testable_variable undefined

	is used only with mission variables and is true when that mission variable has yet to be used

	v1.31+
	constant_expression can now also be an accessor selector recognised by having the suffix
	"_bool", "_number" or "_string".

	dajt: black ops
	a new comparison operator "oneof" can be used to test a numeric variable against a set of
	comma separated numeric constants (eg "planet_number oneof 1,5,9,12,14,234").

	*/
	NSArray*	tokens = [Entity scanTokensFromString:scriptCondition];
	NSString*   selectorString = nil;
	NSString*	comparisonString = nil;
	NSString*	valueString = nil;
	SEL			_selector;
	int			comparator = COMPARISON_NO;

	if (debug)
		NSLog(@"DEBUG ::::: scriptTestCondition: \"%@\"", scriptCondition);

	if ([tokens count] < 1)
	{
		NSLog(@"***** No scriptCondition '%@'",scriptCondition);
		return NO;
	}
	selectorString = (NSString *)[tokens objectAtIndex:0];
	if ([selectorString hasPrefix:@"mission_"])
	{
		if (debug)
			NSLog(@"DEBUG ..... checking mission_variable '%@'",selectorString);
		mission_string_value = (NSString *)[mission_variables objectForKey:selectorString];
		selectorString = @"mission_string";
	}

	if ([tokens count] > 1)
	{
		comparisonString = (NSString *)[tokens objectAtIndex:1];
		if ([comparisonString isEqual:@"equal"])
			comparator = COMPARISON_EQUAL;
		if ([comparisonString isEqual:@"lessthan"])
			comparator = COMPARISON_LESSTHAN;
		if (([comparisonString isEqual:@"greaterthan"])||([comparisonString isEqual:@"morethan"]))
			comparator = COMPARISON_GREATERTHAN;
// +dajt: black ops
		if ([comparisonString isEqual:@"oneof"])
			comparator = COMPARISON_ONEOF;
// -dajt: black ops
		if ([comparisonString isEqual:@"undefined"])
			comparator = COMPARISON_UNDEFINED;
	}

	if ([tokens count] > 2)
	{
		NSMutableString* allValues = [NSMutableString stringWithCapacity:256];
		int value_index = 2;
		while (value_index < [tokens count])
		{
			valueString = (NSString *)[tokens objectAtIndex:value_index++];
			if (([valueString hasSuffix:@"_number"])||([valueString hasSuffix:@"_bool"])||([valueString hasSuffix:@"_string"]))
			{
				SEL value_selector = NSSelectorFromString(valueString);
				if ([self respondsToSelector:value_selector])
				{
					// substitute into valueString the result of the call
					valueString = [NSString stringWithFormat:@"%@", [self performSelector:value_selector]];
				}
			}
			[allValues appendString:valueString];
			if (value_index < [tokens count])
				[allValues appendString:@" "];
		}
		valueString = allValues;
	}

	_selector = NSSelectorFromString(selectorString);
	if (![self respondsToSelector:_selector])
		return NO;

	// test string values (method returns NSString*)
	if ([selectorString hasSuffix:@"_string"])
	{
		NSString *result = [self performSelector:_selector];
		if (debug)
			NSLog(@"DEBUG ..... comparing \"%@\" (%@) to \"%@\" (%@)", result, [result class], valueString, [valueString class]);
		switch (comparator)
		{
			case COMPARISON_UNDEFINED :
				return (result == nil);
			case COMPARISON_NO :
				return NO;
			case COMPARISON_EQUAL :
				return ([result isEqual:valueString]);
			case COMPARISON_LESSTHAN :
				return ([result floatValue] < [valueString floatValue]);
			case COMPARISON_GREATERTHAN :
				return ([result floatValue] > [valueString floatValue]);
			case COMPARISON_ONEOF:
				{
					int i;
					NSArray *valueStrings = [valueString componentsSeparatedByString:@","];
					if (debug)
						NSLog(@"performing a ONEOF comparison: is %@ ONEOF %@ ?", result, valueStrings);
					NSString* r1 = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					for (i = 0; i < [valueStrings count]; i++)
					{
						if ([r1 isEqual:[(NSString*)[valueStrings objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]])
						{
							if (debug)
								NSLog(@"found a match in ONEOF!");
							return YES;
						}
					}
				}
				return NO;
		}
	}
	// test number values (method returns NSNumber*)
	if ([selectorString hasSuffix:@"_number"])
	{
		NSNumber *result = [NSNumber numberWithDouble:[[self performSelector:_selector] doubleValue]];
// +dajt: black ops
		if (comparator == COMPARISON_ONEOF)
		{
			NSArray *valueStrings = [valueString componentsSeparatedByString:@","];
			if (debug)
				NSLog(@"performing a ONEOF comparison with %d elements: is %@ ONEOF %@", [valueStrings count], result, valueStrings);
			int i;
			for (i = 0; i < [valueStrings count]; i++)
			{
				NSNumber *value = [NSNumber numberWithDouble:[[valueStrings objectAtIndex: i] doubleValue]];
				if ([result isEqual:value])
				{
					if (debug)
						NSLog(@"found a match in ONEOF!");
					return YES;
				}
			}
			if (debug)
				NSLog(@"No match in ONEOF");
			return NO;
		}
		else
		{
			NSNumber *value = [NSNumber numberWithDouble:[valueString doubleValue]];

			if (debug)
				NSLog(@"DEBUG ..... comparing \"%@\" (%@) to \"%@\" (%@)", result, [result class], value, [value class]);

			switch (comparator)
			{
				case COMPARISON_UNDEFINED :
				case COMPARISON_NO :
					return NO;
				case COMPARISON_EQUAL :
					return ([result isEqual:value]);
				case COMPARISON_LESSTHAN :
					return ([result isLessThan:value]);
				case COMPARISON_GREATERTHAN :
					return ([result isGreaterThan:value]);
			}
		}
// -dajt: black ops
	}
	// test boolean values (method returns @"YES" or @"NO")
	if ([selectorString hasSuffix:@"_bool"])
	{
		BOOL result = ([[self performSelector:_selector] isEqual:@"YES"]);
		BOOL value = [valueString isEqual:@"YES"];
		switch (comparator)
		{
			case COMPARISON_GREATERTHAN :
			case COMPARISON_LESSTHAN :
			case COMPARISON_UNDEFINED :
			case COMPARISON_NO :
				return NO;
			case COMPARISON_EQUAL :
				return (result == value);
		}
	}
	// default!
	return NO;
}


- (NSDictionary*) mission_variables
{
	return mission_variables;
}

/*-----------------------------------------------------*/

- (NSArray*) missionsList
{
	int i;
	NSArray*  keys = [script allKeys];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity:[keys count]];
	for (i = 0; i < [keys count]; i++)
	{
		if ([mission_variables objectForKey:[keys objectAtIndex:i]])
			[result addObject:[NSString stringWithFormat:@"\t%@",[mission_variables objectForKey:[keys objectAtIndex:i]]]];
	}
	return result;
}

- (void) setMissionDescription:(NSString *)textKey
{
	NSString		*text = (NSString *)[[universe missiontext] objectForKey:textKey];
	if (!text)
	{
		NSLog(@"SCRIPT ERROR ***** no missiontext set for key '%@' [universe missiontext] is:\n%@ ", textKey, [universe missiontext]);
		return;
	}
	if (!mission_key)
	{
		NSLog(@"SCRIPT ERROR ***** mission_key not set");
		return;
	}
	text = [universe expandDescription:text forSystem:system_seed];
	text = [self replaceVariablesInString: text];

	[mission_variables setObject:text forKey:mission_key];
}

- (void) clearMissionDescription
{
	if (!mission_key)
	{
		NSLog(@"SCRIPT ERROR ***** mission_key not set");
		return;
	}
	if (![mission_variables objectForKey:mission_key])
		return;
	[mission_variables removeObjectForKey:mission_key];
}

- (NSString *) mission_string
{
	return mission_string_value;
}
- (NSString *) status_string
{
	switch(status)
	{
		case STATUS_AUTOPILOT_ENGAGED :
			return @"STATUS_AUTOPILOT_ENGAGED";
		case STATUS_DEAD :
			return @"STATUS_DEAD";
		case STATUS_DEMO :
			return @"STATUS_DEMO";
		case STATUS_DOCKING :
			return @"STATUS_DOCKING";
		case STATUS_DOCKED :
			return @"STATUS_DOCKED";
		case STATUS_EFFECT :
			return @"STATUS_EFFECT";
		case STATUS_ENTERING_WITCHSPACE :
			return @"STATUS_ENTERING_WITCHSPACE";
		case STATUS_ESCAPE_SEQUENCE :
			return @"STATUS_ESCAPE_SEQUENCE";
		case STATUS_EXITING_WITCHSPACE :
			return @"STATUS_EXITING_WITCHSPACE";
		case STATUS_EXPERIMENTAL :
			return @"STATUS_EXPERIMENTAL";
		case STATUS_IN_FLIGHT :
			return @"STATUS_IN_FLIGHT";
		case STATUS_IN_HOLD :
			return @"STATUS_IN_HOLD";
		case STATUS_INACTIVE :
			return @"STATUS_INACTIVE";
		case STATUS_LAUNCHING :
			return @"STATUS_LAUNCHING";
		case STATUS_TEST :
			return @"STATUS_TEST";
		case STATUS_WITCHSPACE_COUNTDOWN :
			return @"STATUS_WITCHSPACE_COUNTDOWN";
		default :
			return @"UNDEFINED";
	}
}
- (NSString *) gui_screen_string
{
	switch(gui_screen)
	{
		case GUI_SCREEN_EQUIP_SHIP :
			return @"GUI_SCREEN_EQUIP_SHIP";
		case GUI_SCREEN_INTRO1 :
			return @"GUI_SCREEN_INTRO1";
		case GUI_SCREEN_INTRO2 :
			return @"GUI_SCREEN_INTRO2";
		case GUI_SCREEN_INVENTORY :
			return @"GUI_SCREEN_INVENTORY";
		case GUI_SCREEN_LONG_RANGE_CHART :
			return @"GUI_SCREEN_LONG_RANGE_CHART";
		case GUI_SCREEN_MAIN :
			return @"GUI_SCREEN_MAIN";
		case GUI_SCREEN_MARKET :
			return @"GUI_SCREEN_MARKET";
		case GUI_SCREEN_MISSION :
			return @"GUI_SCREEN_MISSION";
		case GUI_SCREEN_OPTIONS :
			return @"GUI_SCREEN_OPTIONS";
		case GUI_SCREEN_SHORT_RANGE_CHART :
			return @"GUI_SCREEN_SHORT_RANGE_CHART";
		case GUI_SCREEN_STATUS :
			return @"GUI_SCREEN_STATUS";
		case GUI_SCREEN_SYSTEM_DATA :
			return @"GUI_SCREEN_SYSTEM_DATA";
		default :
			return @"UNDEFINED";
	}
}
- (NSNumber *) galaxy_number
{
	return [NSNumber numberWithInt:galaxy_number];
}
- (NSNumber *) planet_number
{
	if (![universe sun])
		return [NSNumber numberWithInt:-1];
	return [NSNumber numberWithInt:[universe findSystemNumberAtCoords:galaxy_coordinates withGalaxySeed:galaxy_seed]];
}
- (NSNumber *) score_number
{
	return [NSNumber numberWithInt:ship_kills];
}
- (NSNumber *) credits_number
{
	return [NSNumber numberWithFloat: 0.1 * credits];
}
- (NSNumber *) scriptTimer_number
{
	return [NSNumber numberWithDouble:script_time];
}

static int shipsFound;
- (NSNumber *) shipsFound_number
{
	return [NSNumber numberWithInt:shipsFound];
}

- (NSNumber *) legalStatus_number
{
	return [NSNumber numberWithInt:legal_status];
}


- (NSNumber *) d100_number
{
	int d100 = ranrot_rand() % 100;
	return [NSNumber numberWithInt:d100];
}

- (NSNumber *) pseudoFixedD100_number
{
	// set the system seed for random number generation
	seed_RNG_only_for_planet_description(system_seed);
//	seed_for_planet_description(system_seed);
	int d100 = (gen_rnd_number()+gen_rnd_number()) % 100;
	return [NSNumber numberWithInt:d100];
}

- (NSNumber *) clock_number				// returns the game time in seconds
{
	return [NSNumber numberWithDouble:ship_clock];
}

- (NSNumber *) clock_secs_number		// returns the game time in seconds
{
	return [NSNumber numberWithInt:floor(ship_clock)];
}

- (NSNumber *) clock_mins_number		// returns the game time in minutes
{
	return [NSNumber numberWithInt:floor(ship_clock / 60.0)];
}

- (NSNumber *) clock_hours_number		// returns the game time in hours
{
	return [NSNumber numberWithInt:floor(ship_clock / 3600.0)];
}

- (NSNumber *) clock_days_number		// returns the game time in days
{
	return [NSNumber numberWithInt:floor(ship_clock / 86400.0)];
}

- (NSNumber *) fuel_level_number		// returns the fuel level in LY
{
	return [NSNumber numberWithFloat:floor(0.1 * fuel)];
}


- (NSString *) dockedAtMainStation_bool
{
	if ((status == STATUS_DOCKED)&&(docked_station == [universe station]))
		return @"YES";
	else
		return @"NO";
}

- (NSString *) foundEquipment_bool
{
	return (found_equipment)? @"YES" : @"NO";
}

- (NSString *) sunWillGoNova_bool		// returns whether the sun is going to go nova
{
	return ([[universe sun] willGoNova])? @"YES" : @"NO";
}

- (NSString *) sunGoneNova_bool		// returns whether the sun has gone nova
{
	return ([[universe sun] goneNova])? @"YES" : @"NO";
}

- (NSString *) missionChoice_string		// returns nil or the key for the chosen option
{
	return missionChoice;
}

- (NSString *) dockedStationName_string	// returns 'NONE' if the player isn't docked, [station name] if it is, 'UNKNOWN' otherwise
{
	if (status != STATUS_DOCKED)
		return @"NONE";
	if (docked_station)
		return [docked_station name];
	return @"UNKNOWN";
}

- (NSString *) systemGovernment_string
{
	NSDictionary *systeminfo = [universe generateSystemData:system_seed];
	int government = [(NSNumber *)[systeminfo objectForKey:KEY_GOVERNMENT] intValue]; // 0 .. 7 (0 anarchic .. 7 most stable)
	switch (government) // oh, that we could...
	{
		case 0:
			return @"Anarchy";
		case 1:
			return @"Feudal";
		case 2:
			return @"Multi-Government";
		case 3:
			return @"Dictatorship";
		case 4:
			return @"Communist";
		case 5:
			return @"Confederacy";
		case 6:
			return @"Democracy";
		case 7:
			return @"Corporate State";
	}
	return @"UNKNOWN";
}

- (NSNumber *) systemGovernment_number
{
	NSDictionary *systeminfo = [universe generateSystemData:system_seed];
	return (NSNumber *)[systeminfo objectForKey:KEY_GOVERNMENT];
}

- (NSNumber *) systemEconomy_number
{
	NSDictionary *systeminfo = [universe generateSystemData:system_seed];
	return (NSNumber *)[systeminfo objectForKey:KEY_ECONOMY];
}

- (NSNumber *) systemTechLevel_number
{
	NSDictionary *systeminfo = [universe generateSystemData:system_seed];
	return (NSNumber *)[systeminfo objectForKey:KEY_TECHLEVEL];
}

- (NSNumber *) systemPopulation_number
{
	NSDictionary *systeminfo = [universe generateSystemData:system_seed];
	return (NSNumber *)[systeminfo objectForKey:KEY_POPULATION];
}

- (NSNumber *) systemProductivity_number
{
	NSDictionary *systeminfo = [universe generateSystemData:system_seed];
	return (NSNumber *)[systeminfo objectForKey:KEY_PRODUCTIVITY];
}




/*-----------------------------------------------------*/

- (void) commsMessage:(NSString *)valueString
{
	Random_Seed very_random_seed;
	very_random_seed.a = rand() & 255;
	very_random_seed.b = rand() & 255;
	very_random_seed.c = rand() & 255;
	very_random_seed.d = rand() & 255;
	very_random_seed.e = rand() & 255;
	very_random_seed.f = rand() & 255;
	seed_RNG_only_for_planet_description(very_random_seed);
	NSString* expandedMessage = [universe expandDescription:valueString forSystem:[universe systemSeed]];
	expandedMessage = [self replaceVariablesInString: expandedMessage];

	[universe addCommsMessage:expandedMessage forCount:4.5];
}


- (void) consoleMessage3s:(NSString *)valueString
{
	Random_Seed very_random_seed;
	very_random_seed.a = rand() & 255;
	very_random_seed.b = rand() & 255;
	very_random_seed.c = rand() & 255;
	very_random_seed.d = rand() & 255;
	very_random_seed.e = rand() & 255;
	very_random_seed.f = rand() & 255;
	seed_RNG_only_for_planet_description(very_random_seed);
	NSString* expandedMessage = [universe expandDescription:valueString forSystem:[universe systemSeed]];
	expandedMessage = [self replaceVariablesInString: expandedMessage];

	[universe addMessage: expandedMessage forCount: 3];
}

- (void) consoleMessage6s:(NSString *)valueString
{
	Random_Seed very_random_seed;
	very_random_seed.a = rand() & 255;
	very_random_seed.b = rand() & 255;
	very_random_seed.c = rand() & 255;
	very_random_seed.d = rand() & 255;
	very_random_seed.e = rand() & 255;
	very_random_seed.f = rand() & 255;
	seed_RNG_only_for_planet_description(very_random_seed);
	NSString* expandedMessage = [universe expandDescription:valueString forSystem:[universe systemSeed]];
	expandedMessage = [self replaceVariablesInString: expandedMessage];

	[universe addMessage: expandedMessage forCount: 6];
}

- (void) setLegalStatus:(NSString *)valueString
{
	legal_status = [valueString intValue];
}

- (void) awardCredits:(NSString *)valueString
{

	if ((!script_target)||(!script_target->isPlayer))
		return;

	int award = 10 * [valueString intValue];
	credits += award;
}

- (void) awardShipKills:(NSString *)valueString
{

	if ((!script_target)||(!script_target->isPlayer))
		return;

	ship_kills += [valueString intValue];
}

- (void) awardEquipment:(NSString *)equipString  //eg. EQ_NAVAL_ENERGY_UNIT
{
	NSString*   eq_type		= equipString;

	if ((!script_target)||(!script_target->isPlayer))
		return;

	if ([eq_type isEqual:@"EQ_FUEL"])
	{
		fuel = 70;
		return;
	}

	if ([eq_type hasSuffix:@"MISSILE"]||[eq_type hasSuffix:@"MINE"])
	{
		if ([self mountMissile:[[universe getShipWithRole:eq_type] autorelease]])
			missiles++;
		return;
	}

	if (![self has_extra_equipment:eq_type])
	{
		[self add_extra_equipment:eq_type];
	}

}

- (void) removeEquipment:(NSString *)equipString  //eg. EQ_NAVAL_ENERGY_UNIT
{
	NSString*   eq_type		= equipString;

	if ((!script_target)||(!script_target->isPlayer))
		return;

	if ([eq_type isEqual:@"EQ_FUEL"])
	{
		fuel = 0;
		return;
	}

	if ([self has_extra_equipment:eq_type])
	{
		[self remove_extra_equipment:eq_type];
	}

}

- (void) setPlanetinfo:(NSString *)key_valueString	// uses key=value format
{
	NSArray*	tokens = [[key_valueString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"="];
	NSString*   keyString = nil;
	NSString*	valueString = nil;

	if ([tokens count] != 2)
	{
		NSLog(@"***** CANNOT SETPLANETINFO: '%@'", key_valueString);
		return;
	}

	keyString = [(NSString*)[tokens objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	valueString = [(NSString*)[tokens objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	[universe setSystemDataKey:keyString value:valueString];

}

- (void) setSpecificPlanetInfo:(NSString *)key_valueString  // uses galaxy#=planet#=key=value
{
	NSArray*	tokens = [[key_valueString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"="];
	NSString*   keyString = nil;
	NSString*	valueString = nil;
	int gnum, pnum;

	if ([tokens count] != 4)
	{
		NSLog(@"***** CANNOT SETPLANETINFO: '%@'", key_valueString);
		return;
	}

	gnum = [(NSString*)[tokens objectAtIndex:0] intValue];
	pnum = [(NSString*)[tokens objectAtIndex:1] intValue];
	keyString = [(NSString*)[tokens objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	valueString = [(NSString*)[tokens objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	[universe setSystemDataForGalaxy:gnum planet:pnum key:keyString value:valueString];
}

- (void) awardCargo:(NSString *)amount_typeString
{
//	NSArray*	tokens = [amount_typeString componentsSeparatedByString:@" "];

	if ((!script_target)||(!script_target->isPlayer))
		return;

	NSArray*	tokens = [Entity scanTokensFromString:amount_typeString];
	NSString*   amountString = nil;
	NSString*	typeString = nil;

	if ([tokens count] != 2)
	{
		NSLog(@"***** CANNOT AWARDCARGO: '%@'",amount_typeString);
		return;
	}

	amountString =	(NSString *)[tokens objectAtIndex:0];
	typeString =	(NSString *)[tokens objectAtIndex:1];

	int amount =	[amountString intValue];
	int type =		[universe commodityForName:typeString];
	if (type == NSNotFound)
		type = [typeString intValue];
	if ((type < 0)||(type >= [[universe commoditydata] count]))
	{
		NSLog(@"***** CANNOT AWARDCARGO: '%@'",amount_typeString);
		return;
	}

	NSArray* commodityArray = (NSArray *)[[universe commoditydata] objectAtIndex:type];
	NSString* cargoString = [(NSArray*)commodityArray objectAtIndex:MARKET_NAME];

	if (debug)
		NSLog(@"DEBUG ..... Going to award cargo %d x '%@'", amount, cargoString);

	int unit = [(NSNumber *)[commodityArray objectAtIndex:MARKET_UNITS] intValue];

	if (status != STATUS_DOCKED)
	{	// in-flight
		while (amount)
		{
			if (unit != UNITS_TONS)
			{
				int amount_per_container = (unit == UNITS_KILOGRAMS)? 1000 : 1000000;
				while (amount > 0)
				{
					int smaller_quantity = 1 + ((amount - 1) % amount_per_container);
					if ([cargo count] < max_cargo)
					{
						ShipEntity* container = [universe getShipWithRole:@"cargopod"];
						if (container)
						{
							[container setUniverse:universe];
							[container setScanClass: CLASS_CARGO];
							[container setCommodity:type andAmount:smaller_quantity];
							[cargo addObject:container];
							[container release];
						}
					}
					amount -= smaller_quantity;
				}
			}
			else
			{
				// put each ton in a separate container
				while (amount)
				{
					if ([cargo count] < max_cargo)
					{
						ShipEntity* container = [universe getShipWithRole:@"cargopod"];
						if (container)
						{
							[container setUniverse:universe];
							[container setScanClass: CLASS_CARGO];
							[container setStatus:STATUS_IN_HOLD];
							[container setCommodity:type andAmount:1];
							[cargo addObject:container];
							[container release];
						}
					}
					amount--;
				}
			}
		}
	}
	else
	{	// docked
		// like purchasing a commodity
		NSMutableArray* manifest =  [NSMutableArray arrayWithArray:shipCommodityData];
		NSMutableArray* manifest_commodity =	[NSMutableArray arrayWithArray:(NSArray *)[manifest objectAtIndex:type]];
		int manifest_quantity = [(NSNumber *)[manifest_commodity objectAtIndex:MARKET_QUANTITY] intValue];
		while ((amount)&&(current_cargo < max_cargo))
		{
			manifest_quantity++;
			amount--;
			if (unit == UNITS_TONS)
				current_cargo++;
		}
		[manifest_commodity replaceObjectAtIndex:MARKET_QUANTITY withObject:[NSNumber numberWithInt:manifest_quantity]];
		[manifest replaceObjectAtIndex:type withObject:[NSArray arrayWithArray:manifest_commodity]];
		[shipCommodityData release];
		shipCommodityData = [[NSArray arrayWithArray:manifest] retain];
	}
}

- (void) removeAllCargo
{
	int type;

	if ((!script_target)||(!script_target->isPlayer))
		return;

	if (debug)
		NSLog(@"DEBUG ..... Going to removeAllCargo");

	NSMutableArray* manifest = [NSMutableArray arrayWithArray:shipCommodityData];
	for (type = 0; type < [manifest count]; type++)
	{
		NSMutableArray* manifest_commodity = [NSMutableArray arrayWithArray:(NSArray *)[manifest objectAtIndex:type]];
		int unit = [(NSNumber *)[manifest_commodity objectAtIndex:MARKET_UNITS] intValue];
		if (unit == 0)
		{
			[manifest_commodity replaceObjectAtIndex:MARKET_QUANTITY withObject:[NSNumber numberWithInt:0]];
			[manifest replaceObjectAtIndex:type withObject:[NSArray arrayWithArray:manifest_commodity]];
		}
	}
	[shipCommodityData release];
	shipCommodityData = [[NSArray arrayWithArray:manifest] retain];
	if (specialCargo)
		[specialCargo release];
	specialCargo = nil;
}

- (void) useSpecialCargo:(NSString *)descriptionString;
{

	if ((!script_target)||(!script_target->isPlayer))
		return;

	[self removeAllCargo];
	specialCargo = [[universe expandDescription:descriptionString forSystem:system_seed] retain];
	//
	if (debug)
		NSLog(@"DEBUG ..... Going to useSpecialCargo:'%@'", specialCargo);
}

- (void) testForEquipment:(NSString *)equipString	//eg. EQ_NAVAL_ENERGY_UNIT
{
	found_equipment = [self has_extra_equipment:equipString];
}

- (void) awardFuel:(NSString *)valueString	// add to fuel up to 7.0 LY
{
	fuel += 10 * [valueString floatValue];
	if (fuel > 70)
		fuel = 70;
	if (fuel < 0)
		fuel = 0;
}

- (void) messageShipAIs:(NSString *)roles_message
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:roles_message];
	NSString*   roleString = nil;
	NSString*	messageString = nil;

	if ([tokens count] < 2)
	{
		NSLog(@"***** CANNOT MESSAGESHIPSAIS: '%@'",roles_message);
		return;
	}

	roleString = (NSString *)[tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	messageString = [tokens componentsJoinedByString:@" "];

	[universe sendShipsWithRole:roleString messageToAI:messageString];
}

- (void) ejectItem:(NSString *)item_key
{
	ShipEntity* item = [universe getShip:item_key];
	if (script_target == nil)
		script_target = self;
	if (item)
		[script_target dumpItem:item];
}

- (void) addShips:(NSString *)roles_number
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:roles_number];
	NSString*   roleString = nil;
	NSString*	numberString = nil;

	if ([tokens count] != 2)
	{
		NSLog(@"***** CANNOT ADDSHIPS: '%@' - MUST BE '<role> <number>'",roles_number);
		return;
	}

	roleString = (NSString *)[tokens objectAtIndex:0];
	numberString = (NSString *)[tokens objectAtIndex:1];

	int number = [numberString intValue];

	if (debug)
		NSLog(@"DEBUG ..... Going to add %d ships with role '%@'", number, roleString);

	while (number--)
		[universe witchspaceShipWithRole:roleString];
}

- (void) addSystemShips:(NSString *)roles_number_position
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:roles_number_position];
	NSString*   roleString = nil;
	NSString*	numberString = nil;
	NSString*	positionString = nil;

	if ([tokens count] != 3)
	{
		NSLog(@"***** CANNOT ADDSYSTEMSHIPS: '%@'",roles_number_position);
		return;
	}

	roleString = (NSString *)[tokens objectAtIndex:0];
	numberString = (NSString *)[tokens objectAtIndex:1];
	positionString = (NSString *)[tokens objectAtIndex:2];

	int number = [numberString intValue];
	double posn = [positionString doubleValue];

	if (debug)
		NSLog(@"DEBUG Going to add %d ships with role '%@' at a point %.3f along route1", number, roleString, posn);

	while (number--)
		[universe addShipWithRole:roleString nearRouteOneAt:posn];
}

- (void) addShipsAt:(NSString *)roles_number_system_x_y_z
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:roles_number_system_x_y_z];

	NSString*   roleString = nil;
	NSString*	numberString = nil;
	NSString*	systemString = nil;
	NSString*	xString = nil;
	NSString*	yString = nil;
	NSString*	zString = nil;

	if ([tokens count] != 6)
	{
		NSLog(@"***** CANNOT ADDSYSTEMSHIPSAT: '%@'",roles_number_system_x_y_z);
		return;
	}

	roleString = (NSString *)[tokens objectAtIndex:0];
	numberString = (NSString *)[tokens objectAtIndex:1];
	systemString = (NSString *)[tokens objectAtIndex:2];
	xString = (NSString *)[tokens objectAtIndex:3];
	yString = (NSString *)[tokens objectAtIndex:4];
	zString = (NSString *)[tokens objectAtIndex:5];

	Vector posn = make_vector( [xString floatValue], [yString floatValue], [zString floatValue]);

	int number = [numberString intValue];

	if (debug)
		NSLog(@"DEBUG Going to add %d ship(s) with role '%@' at point (%.3f, %.3f, %.3f) using system %@", number, roleString, posn.x, posn.y, posn.z, systemString);

	if (![universe addShips: number withRole:roleString nearPosition: posn withCoordinateSystem: systemString])
		NSLog(@"***** CANNOT addShipsAt: '%@' (should be addShipsAt: role number coordinate_system x y z)",roles_number_system_x_y_z);
}

- (void) addShipsAtPrecisely:(NSString *)roles_number_system_x_y_z
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:roles_number_system_x_y_z];

	NSString*   roleString = nil;
	NSString*	numberString = nil;
	NSString*	systemString = nil;
	NSString*	xString = nil;
	NSString*	yString = nil;
	NSString*	zString = nil;

	if ([tokens count] != 6)
	{
		NSLog(@"***** CANNOT ADDSYSTEMSHIPSAT: '%@'",roles_number_system_x_y_z);
		return;
	}

	roleString = (NSString *)[tokens objectAtIndex:0];
	numberString = (NSString *)[tokens objectAtIndex:1];
	systemString = (NSString *)[tokens objectAtIndex:2];
	xString = (NSString *)[tokens objectAtIndex:3];
	yString = (NSString *)[tokens objectAtIndex:4];
	zString = (NSString *)[tokens objectAtIndex:5];

	Vector posn = make_vector( [xString floatValue], [yString floatValue], [zString floatValue]);

	int number = [numberString intValue];

	if (debug)
		NSLog(@"DEBUG Going to add %d ship(s) with role '%@' precisely at point (%.3f, %.3f, %.3f) using system %@", number, roleString, posn.x, posn.y, posn.z, systemString);

	if (![universe addShips: number withRole:roleString atPosition: posn withCoordinateSystem: systemString])
		NSLog(@"***** CANNOT addShipsAtPrecisely: '%@' (should be addShipsAt: role number coordinate_system x y z)",roles_number_system_x_y_z);
}

- (void) addShipsWithinRadius:(NSString *)roles_number_system_x_y_z_r
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:roles_number_system_x_y_z_r];

	if ([tokens count] != 7)
	{
		NSLog(@"***** CANNOT 'addShipsWithinRadius: %@' (should be 'addShipsWithinRadius: role number coordinate_system x y z r')",roles_number_system_x_y_z_r);
		return;
	}

	NSString* roleString = (NSString *)[tokens objectAtIndex:0];
	int number = [[tokens objectAtIndex:1] intValue];
	NSString* systemString = (NSString *)[tokens objectAtIndex:2];
	GLfloat x = [[tokens objectAtIndex:3] floatValue];
	GLfloat y = [[tokens objectAtIndex:4] floatValue];
	GLfloat z = [[tokens objectAtIndex:5] floatValue];
	GLfloat r = [[tokens objectAtIndex:6] floatValue];
	Vector posn = make_vector( x, y, z);

	if (debug)
		NSLog(@"DEBUG Going to add %d ship(s) with role '%@' within %.2f radius about point (%.3f, %.3f, %.3f) using system %@", number, roleString, r, x, y, z, systemString);

	if (![universe addShips:number withRole: roleString nearPosition: posn withCoordinateSystem: systemString withinRadius: r])
		NSLog(@"***** CANNOT 'addShipsWithinRadius: %@' (should be 'addShipsWithinRadius: role number coordinate_system x y z r')",roles_number_system_x_y_z_r);
}

- (void) spawnShip:(NSString *)ship_key
{
	BOOL spawnedOkay = [universe spawnShip:ship_key];
	if (debug)
	{
		if (spawnedOkay)
			NSLog(@"DEBUG Spawned ship with shipdata key '%@'.", ship_key);
		else
			NSLog(@"***** Could not spawn ship with shipdata key '%@'.", ship_key);
	}
}

- (void) set:(NSString *)missionvariable_value
{
	NSMutableArray*	tokens = [Entity scanTokensFromString:missionvariable_value];
	NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
	NSString*   missionVariableString = nil;
	NSString*	valueString = nil;
	BOOL hasMissionPrefix, hasLocalPrefix;

	if ([tokens count] < 2)
	{
		NSLog(@"***** CANNOT SET: '%@'", missionvariable_value);
		return;
	}

	missionVariableString = (NSString *)[tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix != YES && hasLocalPrefix != YES)
	{
		NSLog(@"***** IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", missionVariableString);
		return;
	}

	if (hasMissionPrefix)
		[mission_variables setObject:valueString forKey:missionVariableString];
	else
		[locals setObject:valueString forKey:missionVariableString];
}

- (void) reset:(NSString *)missionvariable
{
	NSString*   missionVariableString = [missionvariable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL hasMissionPrefix, hasLocalPrefix;

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		[mission_variables removeObjectForKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
		[locals removeObjectForKey:missionVariableString];
	}
	else
	{
		NSLog(@"***** IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", missionVariableString);
	}
}

- (void) increment:(NSString *)missionVariableString
{
	BOOL hasMissionPrefix, hasLocalPrefix;
	int value = 0;

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		if ([mission_variables objectForKey:missionVariableString])
			value = [(NSString *)[mission_variables objectForKey:missionVariableString] intValue];
		value++;
		[mission_variables setObject:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
		if ([locals objectForKey:missionVariableString])
			value = [(NSString *)[locals objectForKey:missionVariableString] intValue];
		value++;
		[locals setObject:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString];
	}
}

- (void) decrement:(NSString *)missionVariableString
{
	BOOL hasMissionPrefix, hasLocalPrefix;
	int value = 0;

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		if ([mission_variables objectForKey:missionVariableString])
			value = [(NSString *)[mission_variables objectForKey:missionVariableString] intValue];
		value--;
		[mission_variables setObject:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
		if ([locals objectForKey:missionVariableString])
			value = [(NSString *)[locals objectForKey:missionVariableString] intValue];
		value--;
		[locals setObject:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString];
	}
}

- (void) add:(NSString *)missionVariableString_value
{
	NSString*   missionVariableString = nil;
	NSString*   valueString;
	double	value;
	NSMutableArray*	tokens = [Entity scanTokensFromString:missionVariableString_value];
	NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
	BOOL hasMissionPrefix, hasLocalPrefix;

	if ([tokens count] < 2)
	{
		NSLog(@"***** CANNOT ADD: '%@'",missionVariableString_value);
		return;
	}

	missionVariableString = (NSString *)[tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		value = [[mission_variables objectForKey:missionVariableString] doubleValue];
		value += [valueString doubleValue];

		[mission_variables setObject:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		value = [[locals objectForKey:missionVariableString] doubleValue];
		value += [valueString doubleValue];

		[locals setObject:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString];
	}
	else
	{
		NSLog(@"***** CANNOT ADD: '%@'",missionVariableString_value);
		NSLog(@"***** IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'",missionVariableString);
	}
}

- (void) subtract:(NSString *)missionVariableString_value
{
	NSString*   missionVariableString = nil;
	NSString*   valueString;
	double	value;
	NSMutableArray*	tokens = [Entity scanTokensFromString:missionVariableString_value];
	NSMutableDictionary* locals = [local_variables objectForKey:mission_key];
	BOOL hasMissionPrefix, hasLocalPrefix;

	if ([tokens count] < 2)
	{
		NSLog(@"***** CANNOT SUBTRACT: '%@'",missionVariableString_value);
		return;
	}

	missionVariableString = (NSString *)[tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		value = [[mission_variables objectForKey:missionVariableString] doubleValue];
		value -= [valueString doubleValue];

		[mission_variables setObject:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		value = [[locals objectForKey:missionVariableString] doubleValue];
		value -= [valueString doubleValue];

		[locals setObject:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString];
	}
	else
	{
		NSLog(@"***** CANNOT SUBTRACT: '%@'",missionVariableString_value);
		NSLog(@"***** IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'",missionVariableString);
	}
}

- (void) checkForShips: (NSString *)roleString
{
	shipsFound = [universe countShipsWithRole:roleString];
}

- (void) resetScriptTimer
{
	script_time = 0.0;
	script_time_check = SCRIPT_TIMER_INTERVAL;
	script_time_interval = SCRIPT_TIMER_INTERVAL;
}

- (void) addMissionText: (NSString *)textKey
{
	if ([textKey isEqual:lastTextKey])
		return; // don't repeatedly add the same text
	//
	GuiDisplayGen   *gui =  [universe gui];
	NSString		*text = (NSString *)[[universe missiontext] objectForKey:textKey];
	text = [universe expandDescription:text forSystem:system_seed];
	text = [self replaceVariablesInString: text];
	//NSLog(@"::::: Adding text '%@':\n'%@'", textKey, text);
	NSArray			*paras = [text componentsSeparatedByString:@"\\n"];
	if (text)
	{
		int i;
		for (i = 0; i < [paras count]; i++)
			missionTextRow = [gui addLongText:[self replaceVariablesInString:(NSString *)[paras objectAtIndex:i]] startingAtRow:missionTextRow align:GUI_ALIGN_LEFT];
	}
	if (lastTextKey)
		[lastTextKey release];
	lastTextKey = [[NSString stringWithString:textKey] retain];  //
}

- (void) setMissionChoices:(NSString *)choicesKey	// choicesKey is a key for a dictionary of
{													// choices/choice phrases in missiontext.plist and also..
	GuiDisplayGen* gui = [universe gui];
	// TODO MORE STUFF HERE
	// must find list of choices in missiontext.plist
	// add them to gui setting the key for each line to the key in the dict of choices
	// and the text of the line to the value in the dict of choices
	// and also set the selectable range
	// ++ change the mission screen's response to wait for a choice
	// and only if the selectable range is not present ask:
	// Press Space Commander...
	//
	NSDictionary* choices_dict = (NSDictionary *)[[universe missiontext] objectForKey:choicesKey];
	if ((choices_dict == nil)||([choices_dict count] == 0))
		return;
	//
	NSArray* choice_keys = [choices_dict allKeys];
	//
	[gui setText:@"" forRow:21];			// clears out the 'Press spacebar' message
	[gui setKey:@"" forRow:21];				// clears the key to enable pollDemoControls to check for a selection
	[gui setSelectableRange:NSMakeRange(0,0)];	// clears the selectable range
	//
	int choices_row = 22 - [choice_keys count];
	int i;
	for (i = 0; i < [choice_keys count]; i++)
	{
		NSString* choice_key = (NSString *)[choice_keys objectAtIndex:i];
		NSString* choice_text = [NSString stringWithFormat:@" %@ ",[choices_dict objectForKey:choice_key]];
		choice_text = [universe expandDescription:choice_text forSystem:system_seed];
		choice_text = [self replaceVariablesInString: choice_text];
		[gui setText:choice_text forRow:choices_row align: GUI_ALIGN_CENTER];
		[gui setKey:choice_key forRow:choices_row];
		[gui setColor:[NSColor yellowColor] forRow:choices_row];
		choices_row++;
	}
	//
	[gui setSelectableRange:NSMakeRange( 22 - [choice_keys count], [choice_keys count])];
	[gui setSelectedRow: 22 - [choice_keys count]];
	//
	[self resetMissionChoice];						// resets MissionChoice to nil
}


- (void) resetMissionChoice							// resets MissionChoice to nil
{
	if (missionChoice)
		[missionChoice release];
	missionChoice = nil;
}

- (void) showShipModel: (NSString *)shipKey
{
	ShipEntity		*ship;

	if (!docked_station)
		return;

	[universe removeDemoShips];	// get rid of any pre-existing models on display

    quaternion_into_gl_matrix(q_rotation, rotMatrix);

	Quaternion		q2 = q_rotation;
	q2.w = -q2.w;
	Vector			pos = position;
	quaternion_rotate_about_axis(&q2,vector_right_from_quaternion(q2), 0.5 * PI);

	ship = [universe getShipWithRole: shipKey];   // retain count = 1
	if (ship)
	{
		double cr = ship->collision_radius;
		if (debug)
			NSLog(@"::::: showShipModel:'%@' (%@) (%@)", shipKey, ship, [ship name]);
		[ship setQRotation: q2];
		pos.x += 3.6 * cr * v_forward.x;
		pos.y += 3.6 * cr * v_forward.y;
		pos.z += 3.6 * cr * v_forward.z;

		[ship setStatus: STATUS_DEMO];
		[ship setPosition: pos];
		[ship setScanClass: CLASS_NO_DRAW];
		[ship setRoll: PI/5.0];
		[ship setPitch: PI/10.0];
		[universe addEntity: ship];
		[[ship getAI] setStateMachine: @"nullAI.plist"];

		[ship release];
	}
	//
}

- (void) setMissionMusic: (NSString *)value
{
	[missionMusic release];
	if (NSOrderedSame == [value caseInsensitiveCompare:@"none"])
	{
		missionMusic = nil;
	}
	else
	{
		missionMusic =  [[ResourceManager ooMusicNamed:value inFolder:@"Music"] retain];
	}
}

- (void) setMissionImage: (NSString *)value
{
	if (missionBackgroundImage)   [missionBackgroundImage release];
	if ([[value lowercaseString] isEqual:@"none"])
		missionBackgroundImage = nil;
	else
 	{
#ifdef WIN32
 		missionBackgroundImage =  [[ResourceManager surfaceNamed:value inFolder:@"Images"] retain];
#else
		missionBackgroundImage =  [[ResourceManager imageNamed:value inFolder:@"Images"] retain];
#endif
 	}
}

- (void) setFuelLeak: (NSString *)value
{
	fuel_leak_rate = [value doubleValue];
	if (fuel_leak_rate > 0)
	{
		if (![universe playCustomSound:@"[fuel-leak]"])
			[self warnAboutHostiles];
		[universe addMessage:@"Danger! Fuel leak!" forCount:6];
		if (debug)
			NSLog(@"DEBUG FUEL LEAK activated!");
	}
}

- (void) setSunNovaIn: (NSString *)time_value
{
	double time_until_nova = [time_value doubleValue];
	[[universe sun] setGoingNova:YES inTime: time_until_nova];
	if (debug)
		NSLog(@"DEBUG NOVA activated! time until Nova : %.1f s", time_until_nova);
}

- (void) launchFromStation
{
	[self leaveDock:docked_station];
	[universe setDisplayCursor:NO];
	[breakPatternSound play];
}

- (void) blowUpStation
{
	[[universe station] takeEnergyDamage:500000000.0 from:nil becauseOf:nil];	// 500 million should do it!
}

- (void) sendAllShipsAway
{
	if (!universe)
		return;
	int			ent_count =		universe->n_entities;
	Entity**	uni_entities =	universe->sortedEntities;	// grab the public sorted list
	Entity*		my_entities[ent_count];
	int i;
	for (i = 0; i < ent_count; i++)
		my_entities[i] = [uni_entities[i] retain];		//	retained

	for (i = 1; i < ent_count; i++)
	{
		Entity* e1 = my_entities[i];
		if (e1->isShip)
		{
			ShipEntity* se1 = (ShipEntity*)e1;
			int e_class = e1->scan_class;
			if ((e_class == CLASS_NEUTRAL)||(e_class == CLASS_POLICE)||(e_class == CLASS_MILITARY)||(e_class == CLASS_THARGOID))
			{
				AI*	se1AI = [se1 getAI];
				[se1 setFuel: 70];
				[se1AI setStateMachine:@"exitingTraderAI.plist"];
				[se1AI setState:@"EXIT_SYSTEM"];
				[se1AI reactToMessage:[NSString stringWithFormat:@"pauseAI: %d", 3 + (ranrot_rand() & 15)]];
				[se1 setRoles:@"none"];	// prevents new ship from appearing at witchpoint when this one leaves!
			}
		}
	}
	for (i = 0; i < ent_count; i++)
		[my_entities[i] release];		//	released
}

- (void) addPlanet: (NSString *)planetKey
{
	if (debug)
		NSLog(@"DEBUG addPlanet: %@", planetKey);

	if (!universe)
		return;
	NSDictionary* dict = (NSDictionary*)[[universe planetinfo] objectForKey:planetKey];
	if (!dict)
	{
		NSLog(@"ERROR - could not find an entry in planetinfo.plist for '%@'", planetKey);
		return;
	}

	/*- add planet -*/
	if (debug)
		NSLog(@"DEBUG initPlanetFromDictionary: %@", dict);
	//
	PlanetEntity*	planet = [[PlanetEntity alloc] initPlanetFromDictionary:dict inUniverse:universe];	// alloc retains!
	[planet setStatus:STATUS_ACTIVE];

	if ([dict objectForKey:@"orientation"])
		[planet setQRotation: [Entity quaternionFromString:(NSString *)[dict objectForKey:@"orientation"]]];

	if (![dict objectForKey:@"position"])
	{
		NSLog(@"ERROR - you must specify a position for scripted planet '%@' before it can be created", planetKey);
		[planet release];
		return;
	}
	//
	Vector posn = [Entity vectorFromString:(NSString *)[dict objectForKey:@"position"]];
	if (debug)
	{
		NSLog(@"DEBUG planet position (%.2f %.2f %.2f) derived from %@",
			posn.x, posn.y, posn.z, [dict objectForKey:@"position"]);
	}
	//
	[planet setPosition: posn];
	//
	[universe addEntity:planet];
	//
	[planet release];
	//
}

- (void) addMoon: (NSString *)moonKey
{
	if (debug)
		NSLog(@"DEBUG addMoon: %@", moonKey);

	if (!universe)
		return;
	NSDictionary* dict = (NSDictionary*)[[universe planetinfo] objectForKey:moonKey];
	if (!dict)
	{
		NSLog(@"ERROR - could not find an entry in planetinfo.plist for '%@'", moonKey);
		return;
	}

	if (debug)
		NSLog(@"DEBUG initMoonFromDictionary: %@", dict);
	//
	PlanetEntity*	planet = [[PlanetEntity alloc] initMoonFromDictionary:dict inUniverse:universe];	// alloc retains!
	[planet setStatus:STATUS_ACTIVE];

	if ([dict objectForKey:@"orientation"])
		[planet setQRotation: [Entity quaternionFromString:(NSString *)[dict objectForKey:@"orientation"]]];

	if (![dict objectForKey:@"position"])
	{
		NSLog(@"ERROR - you must specify a position for scripted moon '%@' before it can be created", moonKey);
		[planet release];
		return;
	}
	//
	Vector posn = [Entity vectorFromString:(NSString *)[dict objectForKey:@"position"]];
	if (debug)
	{
		NSLog(@"DEBUG moon position (%.2f %.2f %.2f) derived from %@",
			posn.x, posn.y, posn.z, [dict objectForKey:@"position"]);
	}
	//
	[planet setPosition: posn];
	//
	[universe addEntity:planet];
	//
	[planet release];
	//
}

- (void) debugOn
{
	NSLog(@"SCRIPT debug messages ON");
	debug = YES;
}

- (void) debugOff
{
	NSLog(@"SCRIPT debug messages OFF");
	debug = NO;
}

- (void) debugMessage:(NSString *)args
{
	NSLog(@"SCRIPT debugMessage: %@", [self replaceVariablesInString: args]);
}

- (NSString*) replaceVariablesInString:(NSString*) args
{
	NSString*   valueString;
	int i;
	NSMutableArray*	tokens = [Entity scanTokensFromString:args];

	for (i = 0; i < [tokens  count]; i++)
	{
		valueString = (NSString *)[tokens objectAtIndex:i];

		if ([mission_variables objectForKey:valueString])
		{
			[tokens replaceObjectAtIndex:i withObject:[mission_variables objectForKey:valueString]];
		}
		else if (([valueString hasSuffix:@"_number"])||([valueString hasSuffix:@"_bool"])||([valueString hasSuffix:@"_string"]))
		{
			SEL value_selector = NSSelectorFromString(valueString);
			if ([self respondsToSelector:value_selector])
			{
				[tokens replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"%@", [self performSelector:value_selector]]];
			}
		}
	}
	return [tokens componentsJoinedByString:@" "];
}




/*-----------------------------------------------------*/



- (void) setGuiToMissionScreen
{
	GuiDisplayGen* gui = [universe gui];

	// GUI stuff
	{
		[gui clear];
		[gui setTitle:@"Mission Information"];
		//
		[gui setText:@"Press Space Commander" forRow:21 align:GUI_ALIGN_CENTER];
		[gui setColor:[NSColor yellowColor] forRow:21];
		[gui setKey:@"spacebar" forRow:21];
		//
		[gui setSelectableRange:NSMakeRange(0,0)];
		[gui setBackgroundImage:missionBackgroundImage];

		[gui setShowTextCursor:NO];
	}
	/* ends */

	missionTextRow = 1;

	if (gui)
		gui_screen = GUI_SCREEN_MISSION;

	if (lastTextKey)
	{
		[lastTextKey release];
		lastTextKey = nil;
	}

#ifdef GNUSTEP
//TODO: 3.???? 4. Profit!
#else
	if ((missionMusic)&&(!ootunes_on))
	{
//		GoToBeginningOfMovie ([missionMusic QTMovie]);
//		StartMovie ([missionMusic QTMovie]);
		[missionMusic play];
	}
#endif

	// the following are necessary...
	status = STATUS_DEMO;
	[universe setDisplayText:YES];
	[universe setViewDirection:VIEW_DOCKED];
}



@end
