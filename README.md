# Building the cumulative ESS dataset

This script allows you to combine each round of the [European Social Survey](https://www.europeansocialsurvey.org/) into one cumulative dataset, with harmonized variables for basic demographics and vote intention.

## Features

1. **Harmonized vote intention variable:** Vote intention is originally measured in the ESS with a country-round specific variable. For example, the variable `prtvtcgb` corresponds to the vote choice for respondents in the United Kingdom surveyed for ESS Round 9. This script coalesces these country-round specific variables into one generalized variable, by linking the ESS codes to the [Partyfacts](https://partyfacts.herokuapp.com/) ID. 

2. **Linking party IDs to external datasets:** This code also provides an example of how to merge in information from other party-level datasets. In this case, we use the Partyfacts IDs to link to the [Manifesto Project](https://manifesto-project.wzb.eu/) data, which provides the party families.

3. **Harmonized variables for basic demographics:** Educational attainment is measured by the variable `edulvla` for ESS Rounds 1-4, and by the variable `edulvlb` for ESS rounds 5-9. In this script we create an single indicator for whether the respondent has a bachelor's degree or above, across all rounds.

4. **Coding occupational class using the Oesch schema:** This script also adds a variable for social class using [Oesch](http://people.unil.ch/danieloesch/scripts/)'s simplified occupation-class crosswalk. The supplementary script `oesch_class_crosswalks.R` provides an easy way to access Oesch's Excel files in R without any manual editing.

## Getting started

In order to run the script `build_cumulative_core_ESS.R` you first need to [register your email address with the ESS](http://www.europeansocialsurvey.org/user/new). This allows you to download ESS data using the R package `essurvey`. You will need to fill in your registered email address in the `essurvey::set_email()` function.  

If you would like to link the party ID's to the Manifesto dataset, you will also need to register an account with the [Manifesto Project](https://manifesto-project.wzb.eu/signup). Once you have registered, you can login and go to your profile page to generate an API key. Fill in your API key in the `manifestoR::mp_setapikey()` function.
