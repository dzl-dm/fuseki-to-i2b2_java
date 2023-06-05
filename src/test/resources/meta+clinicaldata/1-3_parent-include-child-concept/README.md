# Parent include child concept

## Feature being tested
Querying a parent concept will include data matching child concepts.

## Example data overview
The metadata has 1 top-level concept node with 1 notation and 1 child concept with 1 notation.

The sample clinical data has 3 observations, 1 from each of 3 patients. 2 patients match the notation for the child concept, while the 3rd patient matches the notation for the parent concept.

2 queries are performed:
1. Count matches for parent concept = Should include parent and child concept clinical data (3)
1. Count matches for child concept = should include only child concept clinical data (2)
