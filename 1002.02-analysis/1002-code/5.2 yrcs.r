# ---------------------------------------------------------------------------- #
#      Difficulties in explaining factors affecting multiple trajectories      #
# ---------------------------------------------------------------------------- #

# //ANCHOR - sodium

library(rcssci)

rcs_logistic.ushap(
    data = dfCTTraj,
    y = "group",
    x = "sodium",
    prob = 0.1,
    filepath = "C:/Users/zhouh/OneDrive/321-stat/1002.02"
)

# //ANCHOR - paco2

library(rcssci)

rcssci_logistic(
    data = dfCTTraj,
    y = "group",
    x = "paco2",
    prob = 0.1,
    filepath = "C:/Users/zhouh/OneDrive/321-stat/1002.02"
)

