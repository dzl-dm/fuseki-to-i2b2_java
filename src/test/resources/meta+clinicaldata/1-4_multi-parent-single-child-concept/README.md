# Multi parent, single child concept

## Feature being tested
Querying a parent concept will include data matching child concepts even when the child concept is shared by multiple parents.

## Example data overview
The metadata has 2 top-level concept nodes without notation, each referencing the same single child concept with 1 notation.

The sample clinical data has 3 observations, 1 from each of 3 patients. 2 patients match the notation for the child concept, while the 3rd patient has an undefined notation.

A query is performed to count the patients belonging to each parent concept = Should include the patients with child concept notation and exclude the patient with undefined notation. Both queries should have the same result.
