# Building the cumulative ESS dataset

This script allows you to combine each round of the [European Social Survey](https://www.europeansocialsurvey.org/) into one cumulative dataset, with harmonized variables for basic demographics and vote intention.

- Vote intention is originally measured in the ESS with a country-round specific variable. For example, the variable `prtvtcgb` corresponds to the vote choice for respondents in the United Kingdom surveyed for ESS Round 9. This script coalesces these country-round specific variables into one generalized variable, and links the ESS codes to the Partyfacts ID. 

- Create consistent variables for basic demographics. For example, educational attainment is measured by the variable `edulvla   for ESS Rounds 1-4, and by the variable `edulvlb` for ESS rounds 5-9. In this script we create an single indicator for whether the respondent has a bachelor's degree or above, across all rounds.

- Add a variable for social class using Oesch's occupation-class crosswalk. The supplementary script provides an easy way to access these Excel files in R without any manual editing.

