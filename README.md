# Building the cumulative ESS dataset

This script allows you to combine each round of the [European Social Survey](https://www.europeansocialsurvey.org/) into one cumulative dataset, with harmonized variables for basic demographics and vote intention.

## Features

1. **Harmonized vote intention variable, with external links:** Vote intention is originally measured in the ESS with a country-round specific variable. For example, the variable `prtvtcgb` corresponds to the vote choice for respondents in the United Kingdom surveyed for ESS Round 9. This script coalesces these country-round specific variables into one generalized variable, and links the ESS codes to the Partyfacts ID. 

2. **Harmonized variables for basic demographics:** Educational attainment is measured by the variable `edulvla` for ESS Rounds 1-4, and by the variable `edulvlb` for ESS rounds 5-9. In this script we create an single indicator for whether the respondent has a bachelor's degree or above, across all rounds.

3. **Coding occupational class using the Oesch schema:** This script also adds a variable for social class using Oesch's simplified occupation-class crosswalk. The supplementary script `oesch_class_crosswalks.R` provides an easy way to access Oesch's Excel files in R without any manual editing.

## Getting started

In order to run the script `build_cumulative_ESS.R` you first need to [register your email address with the ESS](http://www.europeansocialsurvey.org/user/new). This allows you to download ESS data using the R package `essurvey`. You will need to fill in your registered email address in the `essurvey::set_email()` function.
