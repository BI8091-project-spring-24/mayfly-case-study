################################################################################

# 1.4 GBIF data exploration and vizualization

################################################################################

# Load cleaned insectdata
load(here::here("data","derived_data", "cleaned_insectdata.rda"))

# Summarize the number of occurrences by institution
df_institutions <- cleaned_insectdata %>%
  group_by(institutionCode) %>%
  summarize(N_occurrences = length(occurrenceID))%>%
  mutate(across(where(is.character), ~ na_if(.,""))) %>%
  filter(!is.na(institutionCode))

df_institutions_barplot <- df_institutions %>% 
  arrange(desc(N_occurrences)) %>%
  slice(1:10) %>%
  ggplot(., aes(x = reorder(institutionCode,-N_occurrences), y = N_occurrences)) + 
  geom_bar(stat = "identity") +
  scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
  xlab("Institution") + 
  ylab("Number of occurrences") +
  theme_classic()

a <-table(cleaned_insectdata$samplingProtocol)

only_mdir <- insectdata_low_uncertainty |> filter(institutionCode == "miljodir")
as.data.frame(table(only_mdir$samplingProtocol))

only_ntnu <- insectdata_low_uncertainty |> filter(institutionCode == "NTNU-VM")
as.data.frame(table(only_ntnu$samplingProtocol))

only_nina <- insectdata_low_uncertainty |> filter(institutionCode == "NINA")
as.data.frame(table(only_nina$samplingProtocol))

table(only_ntnu$datasetKey)

