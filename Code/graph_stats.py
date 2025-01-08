import pandas as pd
import seaborn as sns
from linearmodels.panel import PanelOLS

data=pd.read_csv('../Data/processed_data_main.csv')
data=data.set_index(['owner__participant__code','owner__round_number'])

reg1=PanelOLS.from_formula('owner__exit_price~1+EntityEffects',
                          data=data).fit()
data['resid']=reg1.resids