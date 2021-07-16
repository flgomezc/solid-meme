import pandas as pd
import pickle
from rucio.client import Client
client = Client()

scope = 'cms'
rules = []
created_times = []
N = []

with open('datasets.dat', 'rt') as f:
    datasets = f.read().splitlines()

for name in datasets:
    
    print(name)
    filter = {'scope':scope, 'name':name}

    rules_json = list( client.list_replication_rules(filters=filter) )

    for rule in rules_json:
        id = rule['id']
        creationT = rule['created_at']

        rules.append(id)
        created_times.append(creationT)
        N.append(name)
        
df = pd.DataFrame(list(zip(rules, created_times, N)), columns=['rule_id', 'created_at', 'name'])
pickle.dump( df, open("rules_df.pickle", "wb"))
