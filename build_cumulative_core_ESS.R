# load packages
library(tidyverse) # for data wrangling
library(essurvey) # to download ESS data
# if necessary, install with this command:
# devtools::install_github("ropensci/essurvey")
library(sjlabelled) # to convert party vote choice into names
library(data.table) # for the "fread" function to quickly load large csv files

# useful function
tabl <- function(...) table(..., useNA='ifany')

# IN ORDER TO DOWNLOAD DATA FROM THE ESS USING THE ESSURVEY PACKAGE,
# YOU NEED TO REGISTER YOUR EMAIL WITH THE ESS:
# you can do that here: http://www.europeansocialsurvey.org/user/new
# once you have registered, fill in your email address below
essurvey::set_email("your_email@gmail.com")

# Let's load all available rounds 1-9
# The function defaults to "stata" format
# BUT: there is an error with the haven package
# (more info here: https://github.com/ropensci/essurvey/issues/44)
# So if you import in stata format then rounds 1-8 get imported with haven
# and round 9 gets imported with foreign
# This means rounds 1-8 and round 9 end up being in different formats
# that's annoying!
# Instead, let's just import all rounds in SPSS format to avoid that error:
ess_raw <- import_rounds(1:9, format="spss")

# Now we need to create a function to:
# (i) select required variables from each of the 9 datasets
# (ii) create a generalized party vote choice variable, instead of having lots of country-round specific variables

# note: for Germany there are TWO vote intention variables
# since they cast 1 vote for a candidate "prtvde1" and then 1 vote for a party list "prtvde2"
# I will just use the party of the candidate vote
# which is why I drop variables ending in "de2" in the function below

# You can add the variables you want to extract in the select function below
# Make sure to get the variable name exactly right: http://nesstar.ess.nsd.uib.no/webview/
# Use "start_with()" / "ends_with()" to grab all variables starting with that string
es.df.clean <- function(x){
  esx <- x %>% select("essround", # REQUIRED: essround
                      "idno", # REQUIRED: respondent ID
                      "cntry", # REQUIRED: country 
                      starts_with("inw"), # REQUIRED: interview date (to match vote recall to specific election)
                      "gndr" , # gender
                      "agea", # age
                      starts_with("edulvl"), # educational attainment (several vars)
                      starts_with("isco"), # occupation
                      starts_with("prtv"), # party vote
                      -ends_with("de2"), # drop 2nd German vote intention var
  ) %>% 
    as.data.frame()
  # find FIRST country-specific vote variable
  start <- head(grep("prtv", colnames(esx)), n=1)
  # find LAST country-specific vote variable
  end <- tail(grep("prtv", colnames(esx)), n=1)
  # mini dataset of party choice vars
  es.vote <- esx %>% select(start:end)
  # create dataset-wide vote variable by merging the country-specific vars
  esx$party.vote.num <- as.vector(do.call(coalesce, es.vote))
  # convert numeric values into party names
  es.vote.named <- as_label(es.vote)
  # convert factors into characters to make sure they're stored properly
  es.vote.named[] <- lapply(es.vote.named, as.character)
  # create another dataset-wide vote variable, this time for the character variable
  esx$party.vote.name <- as.vector(do.call(coalesce, es.vote.named))
  # convert to UTF encoding to deal with special characters
  # delete unnecessary variables
  start <- head(grep("prtvt", colnames(esx)), n=1)
  end <- tail(grep("prtvt", colnames(esx)), n=1)
  esx <- esx %>% select(-(start:end))
  esx
}

# apply cleaning function to each of the 9 datasets in the lsit
ess_clean <- lapply(ess_raw, FUN=es.df.clean)
# bind all 9 datasets together
ess <- bind_rows(ess_clean)
# take a look!
head(ess)

# EDUCATION:
# Let's create a dummy variable indicating that the respondent
# has attained a bachelor's degree or above
# ESS rounds 1-4 use the "edulvla" variable
xtabs(~ essround + edulvla, data=ess)
# ESS rounds 5 onwards use a more detailed "edulvlb" variable
xtabs(~ essround + edulvlb, data=ess)

# First let's code "other" as missing
ess$edulvla[ess$edulvla==55] <- NA # "other"
ess$edulvlb[ess$edulvlb==5555] <- NA # "other"

# now create dummy for bachelors degree
# for more details on the categories: https://www.europeansocialsurvey.org/docs/round8/survey/ESS8_data_protocol_e01_4.pdf
ess$educ.ba <- ifelse(ess$essround<5 & ess$edulvla==5, 1,
                      ifelse(ess$essround>=5 & ess$edulvlb>600, 1, 0))
tabl(ess$educ.ba)


# OCCUPATION
names(ess)
head(xtabs(~  iscoco + essround, data=ess))
head(xtabs(~  isco08 + essround, data=ess))

# load Oesch occupation-class crosswalks from the Github repo
# Alternatively, you can run the script "oesch_class_crosswalks.R" to produce them yourself

# crosswalk for ISCO 1988 codes
cw88 <- read_csv(url("https://raw.githubusercontent.com/sophieehill/ess-cumulative/master/crosswalks/oesch_88_4dig_cleaned.csv")) 
cw88 <- cw88[,-1]
# crosswalk for ISCO 2008 codes
names(cw88) <- c("isco88", "isco88_desc", "oesch_class88")
cw08 <- read_csv(url("https://raw.githubusercontent.com/sophieehill/ess-cumulative/master/crosswalks/oesch_08_4dig_cleaned.csv")) 
cw08 <- cw08[,-1]
names(cw08) <- c("isco08", "isco_desc08", "oesch_class08")

ess <- left_join(ess, cw88, by=c("iscoco"="isco88"))
ess <- left_join(ess, cw08, by=c("isco08"="isco08"))
ess <- ess %>% mutate(oesch_class = coalesce(oesch_class88, oesch_class08))
tabl(ess$oesch_class)

ess <- ess %>% mutate(oesch_class_sum = case_when(oesch_class %in% c(1,2) ~ "Self-employed professionals",
                                                  oesch_class %in% c(3,4) ~ "Small business owners",
                                                  oesch_class %in% c(5,6) ~ "Technical (semi-)professionals",
                                                  oesch_class %in% c(7,8) ~ "Production workers",
                                                  oesch_class %in% c(9,10) ~ "(Associate) managers",
                                                  oesch_class %in% c(11,12) ~ "Clerks",
                                                  oesch_class %in% c(13,14) ~ "Sociocultural (semi-)professionals",
                                                  oesch_class %in% c(15,16) ~ "Service workers"))
tabl(ess$oesch_class_sum)

# gender
tabl(ess$gndr)
ess$female <- ifelse(ess$gndr==1, 0, ifelse(ess$gndr==2, 1, NA))
tabl(ess$female)

# age
table(ess$agea)
ess$age <- ess$agea
ess$age[ess$agea==999] <- NA
table(ess$age)
ess$age.group <- cut(ess$age, breaks=c(0,20,35,50,65,75, 120))
table(ess$age.group)

# year
ess$essround.year <- NA
ess$essround.year[ess$essround==1] <- 2002
ess$essround.year[ess$essround==2] <- 2004
ess$essround.year[ess$essround==3] <- 2006
ess$essround.year[ess$essround==4] <- 2008
ess$essround.year[ess$essround==5] <- 2010
ess$essround.year[ess$essround==6] <- 2012
ess$essround.year[ess$essround==7] <- 2014
ess$essround.year[ess$essround==8] <- 2016
ess$essround.year[ess$essround==9] <- 2018

table(ess$cntry)
ess$party.vote.ess <- ifelse(is.na(ess$party.vote.num), NA,
                             paste0(ess$cntry, "-", ess$essround, "-", ess$party.vote.num))
tabl(ess$party.vote.ess)

# load the ESS-Partyfacts extended crosswalk
cw_ess_pf <- read_csv(url("https://raw.githubusercontent.com/sophieehill/ess-partyfacts-crosswalk/master/ess-partyfacts-extended.csv"))
cw_ess_pf$party.vote.ess <- paste0(cw_ess_pf$cntry, "-", cw_ess_pf$essround, "-", cw_ess_pf$ess_id)
cw_ess_pf <- cw_ess_pf %>% select(party.vote.ess, partyfacts_id, partyfacts_name)

# merge partyfacts IDs into main dataset
ess <- left_join(ess, cw_ess_pf, by=c("party.vote.ess"))
tabl(temp$party.vote.ess)
tabl(temp$partyfacts_id)

# now load the Partyfacts-External crosswalk and select the Manifesto dataset
# this lets us link those partyfacts IDs to *other* datasets
cw_pf <- read_csv(url("https://partyfacts.herokuapp.com/download/external-parties-csv/"))
cw_pf$dataset_party_id <- as.numeric(as.character(cw_pf$dataset_party_id))
cw_pf_cmp <- cw_pf %>% filter(dataset_key == "manifesto") %>% select(partyfacts_id, dataset_party_id)

names(cw_pf_cmp) <- c("partyfacts_id", "cmp_id")

ess <- left_join(ess, cw_pf_cmp, by=c("partyfacts_id"))
tabl(ess$cmp_id)

# In order to merge in election-level variables (e.g. measures of a party's manifesto for a particular election), we need to match up the ESS dates to the most recent election
# Some ESS fieldwork occurs over an election period, meaning that respondents within the same country-round would be referring to different elections when they recall their "past vote"
# First, let's import the dataset from Denis Cohen's github: https://github.com/denis-cohen/ess-election-dates
ess_dates <- read_csv(url("https://raw.githubusercontent.com/denis-cohen/ess-election-dates/master/ess_election_dates.csv"))
# select needed vars
ess_dates <- ess_dates %>% select(cntry, essround, recent_election, recent_election_split1)
# merge in
ess <- left_join(ess, ess_dates, by=c("cntry", "essround"))

# create a variable indicating date of interview for each respondent
# first create day/month/year variables consistent across rounds
# from ESS Round 3 onwards, they give us the start (inwdds) AND end date (inwdde) of the interview
# here I am taking the start date as our reference point
# I *think* the politics module occurs fairly early during the survey
# Alternatively we coulld take the midpoint, or use the end date? 
ess <- ess %>% mutate(int.day = case_when(essround<3 ~ inwdd,
                                          essround>2 ~ inwdds)) %>%
              mutate(int.month = case_when(essround<3 ~ inwmm,
                                          essround>2 ~ inwmms)) %>%
              mutate(int.year = case_when(essround<3 ~ inwyr,
                                          essround>2 ~ inwyys))
ess <- ess %>% mutate(int.date = as.Date(paste(int.year, int.month, int.day, sep="-")))
tabl(ess$int.date)
# for each respondent, let's define their "most recent election", based on start interview date
ess <- ess %>% mutate(ref.election = case_when(int.date > recent_election ~ recent_election,
                                               int.date <= recent_election ~ recent_election_split1))
tabl(ess$ref.election)
# if the specific date is missing let's just match up using the country-year pair


# Merge with CMP data to get party families
# Download latest CMP dataset
# (Use API or just load "cmp.csv")
library(manifestoR)
# set API key
mp_setapikey(key = "70af9d9d7f76a3d66d41142debe969f6")
# download latest dataset
cmp <- as.data.frame(mp_maindataset())
# save for replicability
# write.csv(cmp, "cmp_main_2020.csv")
head(cmp)
tabl(cmp$edate)
summary(cmp$party)
# create election year variable
cmp$election.year <- as.numeric(as.character(substr(cmp$date, 1, 4)))
# create econ l-r and lib-auth scales, following Bakker & Hobolt (2013)
cmp <- cmp %>% mutate(econlr = scale_logit(data=cmp,
                                           pos=c("per401", "per402", "per407", "per505", 
                                                 "per507", "per410", "per414", "per702"), 
                                           neg=c("per403", "per404", "per406", "per504", 
                                                 "per506", "per413", "per412", "per701", 
                                                 "per405", "per409", "per415", "per503"),
                                           zero_offset = 0.5))

cmp <- cmp %>% mutate(econlr.sal = (per401 + per402 + per407 + per505 + per507 + per410 + per414 + per702) +
                        (per403 + per404 + per406 + per504 + per506 + per413 + per412 + per701 + per405 + per409 + per415 + per503))


summary(cmp$econlr.sal)

cmp <- cmp %>% mutate(auth = scale_logit(data=cmp,
                                         pos=c("per305", "per601", "per603", "per605", 
                                               "per608", "per606"), 
                                         neg=c("per501", "per602", "per604", "per502", 
                                               "per607", "per416", "per705", "per706", 
                                               "per201", "per202"),
                                         zero_offset = 0.5))

cmp <- cmp %>% mutate(auth.sal = (per305 + per601 + per603 + per605 + per608  + per606) +
                        (per501 + per602 + per604 + per502 + per607 + per416 + per705 + per706 + per201 + per202))
# select party code, party family
# as well as party-election specific variables like right/left coding of the manifesto
cmp.x <- cmp %>% select(party, parfam, election.year, edate, rile, 
                        econlr, econlr.sal, auth, auth.sal)
names(cmp.x)[1:2] <- c("cmp_id", "cmp_parfam") # relabel for clarity
head(cmp.x)
ess$election.year <- as.numeric(as.character(substr(ess$ref.election, 1, 4)))
tabl(ess$election.year)
# match up by election year
# N.B. this won't work for cases where two elections happen in the same year, and ESS fieldwork window covers the 2nd election
ess <- left_join(ess, cmp.x, by=c("cmp_id", "election.year"))
# alternatively we could match on exact election date
# cmp.x$election.date <- as.Date(cmp.x$edate)
# ess$election.date <- as.Date(ess$ref.election)
# ess <- left_join(ess, cmp.x, by=c("cmp_id", "election.date"))

# create left vote recall based on party families
# 10 = ecological
# 20 = socialist or other left
# 30 = social democratic
ess$vote.left <- ifelse(ess$cmp_parfam==10 | ess$cmp_parfam==20 | ess$cmp_parfam==30, 1, 0)
tabl(ess$vote.left)

names(ess)

head(ess)
essx <- ess %>% select(idno, cntry, essround, essround.year, int.date,
                       female, age, age.group, educ.ba, domicil,
                       oesch_class, oesch_class_sum,
                       nace.summary, lrscale,
                       party.vote.ess, partyfacts_id, partyfacts_name,
                       cmp_id, cmp_parfam, vote.left, ref.election,
                       election.year, edate, rile, vote.int.left,
                       econlr, econlr.sal, auth, auth.sal) %>% 
                       as.data.frame()

write.csv(essx, "ess_cumulative_core.csv")
