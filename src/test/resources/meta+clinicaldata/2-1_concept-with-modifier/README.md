# Concept with modifier

## Feature being tested
Querying by modifier excludes data for the concept if it does not have the modifier.

## Example data overview
The meta data has a single concept with 2 modifiers. Each node (concept or modifier) has a single notation of its own, 1 of the modifiers has 2 notations.

The sample clinical data has 4 observations from 3 patients. All patients have the concept notation; 1 without any modifier, 1 with 1 modifier, 1 with 2 modifiers.

3 queries are performed:
1. All patients are returned for the concept.
1. 2 patients are returned for the modifier where both match.
1. 1 patient is returned for the modifier where only 1 matches.
