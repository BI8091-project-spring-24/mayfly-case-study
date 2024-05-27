################################################################################

# 1.4 GBIF data exploration and vizualization

################################################################################

# Load cleaned insectdata
load(here::here("data","derived_data","cleaned_insectdata.rda"))

# Summarize the number of occurrences by institution
df_institutions <- cleaned_insectdata %>%
  group_by(institutionCode) %>%
  summarize(N_occurrences = length(occurrenceID))%>%
  mutate(across(where(is.character), ~ na_if(.,""))) %>%
  filter(!is.na(institutionCode))

# Plot and save figure for top 10 institutions
jpeg(here::here("results","top_10_institutions.jpg"),width=15,height=10,units="in",res=150)

df_institutions_barplot <- df_institutions %>% 
  arrange(desc(N_occurrences)) %>%
  slice(1:10) %>%
  ggplot(., aes(x = reorder(institutionCode,-N_occurrences), y = N_occurrences)) + 
  geom_bar(stat = "identity") +
  scale_x_discrete(guide = guide_axis(n.dodge = 2)) +
  xlab("Institution") + 
  ylab("Number of occurrences") +
  theme_classic()

dev.off()

