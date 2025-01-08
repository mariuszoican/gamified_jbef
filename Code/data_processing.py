import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

#session_code='9pqvaeel' # trial 1 (Nov 9)
#session_code='6jpxnq92' # trial 2 (Nov 11)
#session_code='mv9ewgi2' # trial 3 (Nov 12)

session_codes=['tcbozsj9','xm39f2ij','hgp2owka','cv9yjdhy']
# tcbozsj9 - Postgraduate x Frequent Shopper
# xm39f2ij - Below Postgraduate x Frequent Shopper
# hgp2owka - Postgraduate x Non-Frequent Shopper
# cv9yjdhy - Below Postgraduate x Non-Frequent Shopper


# players who did not complete the experiment
submissions_to_drop=['v2w8kot6']



# meta=pd.read_csv('../Data/trader_wrapper_2021-11-10.csv')
# meta=meta[meta['session.code']==session_code] # select session(s) of interest
# meta=meta.rename(columns={'participant.code':'owner__participant__code',
#                           'subsession.round_number':'owner__round_number',
#                           'session.code':'owner__session__code'})


data=pd.read_csv('../Data/events_main.csv')
data=data[data['owner__session__code'].isin(session_codes)]
data=data[data['owner__training']==False].reset_index(drop=True)
data['subsession.tick_frequency']=data['owner__subsession__tick_frequency']
del data['owner__subsession__tick_frequency']

# register crashes
# -----------------------------------
data['zero_price']=np.where(data['current_price']==0,1,0)
data['exit_crash']=data.groupby(['owner__participant__code',
                            'owner__round_number']).transform(max)['zero_price']
del data['zero_price']

# register sells
# ---------------------------
data['sell_dummy']=np.where(data['name']=='Sell',1,0)
data['exit_sell']=data.groupby(['owner__participant__code',
                            'owner__round_number']).transform(max)['sell_dummy']
del data['sell_dummy']

# register HODLs
# ------------------------
max_prices=30 # maximum number of prices per round
data['hodl_dummy']=np.where(data['priceIndex']==max_prices,1,0)
data['exit_hodl']=data.groupby(['owner__participant__code',
                            'owner__round_number']).transform(max)['hodl_dummy']
del data['hodl_dummy']

# count "change-of-mind" sells
data['change_dummy']=np.where(data['name']=='continueKeeping',1,0)
data['mindchanges']=data.groupby(['owner__participant__code',
                            'owner__round_number']).transform(sum)['change_dummy']
del data['change_dummy']

data['exit_correct']=data.exit_sell+data.exit_hodl+data.exit_crash

# dummy if start with gamified treatment
data['gamified_first']=data.groupby('owner__participant__code').transform('first')['owner__gamified']*1

data_final=data[(data.name=='Trade_ends') & (data.exit_correct>0)]

# load post-experimental data
demo=pd.read_csv('../Data/post_experimental_2021-11-17.csv')
demo=demo.rename(columns={'participant.code':'owner__participant__code'})

data_final=data_final.merge(demo[['owner__participant__code', 'player.gender', 'player.age', 'player.education', 'participant.payoff',
                                  'player.payoff','player.study_major','player.course_financial','player.trading_experience',
                                  'player.online_trading_experience','player.trading_frequency','player.portfolio_frequency',
                                  'player.asset_class', 'player.use_leverage', 'player.nationality'
                                  ]],on='owner__participant__code',how='left')
data_final=data_final.rename(columns={'player.payoff':'FinScore'})
data_final['censoring']=np.where((data_final['exit_crash']==1) | (data_final['exit_hodl']==1), data_final['secs_since_round_starts'],1000)
data_final['censoring_price']=np.where((data_final['exit_crash']==1) , data_final['owner__exit_price'],1000)

data_final=data_final[data_final.secs_since_round_starts<=60]
data_final=data_final[data_final.owner__participant__code.apply(lambda x: not(x in submissions_to_drop))]

data_final.to_csv('../Data/processed_data_main.csv')

# plot
trad=data_final.drop_duplicates('owner__participant__code')
import seaborn as sns
from matplotlib import rc, font_manager
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

def settings_plot(ax):
    for label in ax.get_xticklabels():
        label.set_fontproperties(ticks_font)
    for label in ax.get_yticklabels():
        label.set_fontproperties(ticks_font)
    ax.spines['right'].set_visible(False)
    ax.spines['top'].set_visible(False)
    return ax

sizeOfFont=18
ticks_font = font_manager.FontProperties(size=sizeOfFont)

sizefigs_L=(16.5,8)
gs = gridspec.GridSpec(1, 2)


fig=plt.figure(facecolor='white',figsize=sizefigs_L)
ax=fig.add_subplot(gs[0, 1])
ax=settings_plot(ax)

sns.histplot(data=trad, x="FinScore",hue='player.online_trading_experience',
             stat='percent', multiple='dodge',bins=11,common_norm=False,ax=ax)

plt.xlabel('Financial quiz score', fontsize=20)
plt.ylabel(r'Percent of sample (%)',fontsize=20)

plt.title('Quiz score and trading experience', fontsize=20)
plt.xticks(np.arange(1, 11+1, 1.0))
plt.xticks(rotation=60)

legend = ax.get_legend()
handles = legend.legendHandles
legend.remove()
ax.legend(handles,['No trading experience','Trading experience'],frameon=False,fontsize=16)



ax=fig.add_subplot(gs[0, 0])
ax=settings_plot(ax)

sns.histplot(x=trad.FinScore,hue=trad['player.course_financial'],
             stat='percent', multiple='dodge',bins=11,common_norm=False)

plt.xlabel('Financial quiz score', fontsize=20)
plt.ylabel(r'Percent of sample (%)',fontsize=20)

plt.title('Quiz score and finance courses', fontsize=20)
plt.xticks(np.arange(1, 11+1, 1.0))
plt.xticks(rotation=60)

legend = ax.get_legend()
handles = legend.legendHandles
legend.remove()
ax.legend(handles,['No finance course','Finance course'],frameon=False,fontsize=16)



plt.tight_layout(pad=5.0)
#plt.show()
plt.savefig('quizscores.png',bbox_inches='tight')

# demographics plot

dem=data_final.drop_duplicates(subset=['owner__participant__code'])

sizefigs_L=(18,10)
gs = gridspec.GridSpec(2, 3)


fig=plt.figure(facecolor='white',figsize=sizefigs_L)
ax=fig.add_subplot(gs[0, 0])
ax=settings_plot(ax)

sns.countplot(data=dem, x="player.gender")

plt.xlabel('Gender', fontsize=20)
plt.ylabel(r'Count',fontsize=20)

ax=fig.add_subplot(gs[0, 1])
ax=settings_plot(ax)

sns.countplot(data=dem, x="player.trading_experience",order=[1,0])

ax.set_xticklabels(['Yes','No'],fontsize=20)

plt.xlabel('Trading experience', fontsize=20)
plt.ylabel(r'Count',fontsize=20)

ax=fig.add_subplot(gs[0, 2])
ax=settings_plot(ax)

sns.countplot(data=dem, x="player.trading_frequency",
              order=['Less than once a month','Monthly','Weekly','Daily','Multiple times a day'])

ax.set_xticklabels(['<1/month','Monthly','Weekly','Daily','Intra-day'],fontsize=20)
plt.xticks(rotation=45)

plt.xlabel('Trading frequency', fontsize=20)
plt.ylabel(r'Count',fontsize=20)


ax=fig.add_subplot(gs[1, 0])
ax=settings_plot(ax)

sns.histplot(data=dem, x="player.age")

plt.xlabel('Player age', fontsize=20)
plt.ylabel(r'Count',fontsize=20)

ax=fig.add_subplot(gs[1, 1])
ax=settings_plot(ax)

dict_educ={'MBA':'MBA', 'PhD':'PhD', 'did not graduate high school':'High school', 'high-school graduate':'High school',
           'master':'Master',
            'undergraduate: 1st year':'UG', 'undergraduate: 2nd year':'UG', 'undergraduate: 3d year':'UG',
           'undergraduate: 4th year':'UG',np.nan:np.nan}

dem['education']=dem['player.education'].apply(lambda x: dict_educ[x])

sns.countplot(data=dem, x="education",order=['High school','UG','Master','MBA','PhD'])

#ax.set_xticklabels(['Yes','No'],fontsize=20)
plt.xticks(rotation=45)

plt.xlabel('Education', fontsize=20)
plt.ylabel(r'Count',fontsize=20)

ax=fig.add_subplot(gs[1, 2])
ax=settings_plot(ax)

sns.countplot(data=dem, x="player.asset_class",
              order=['Stocks','Cryptocurrencies','Bonds','Derivatives (Options, Futures)'])

ax.set_xticklabels(['Equity','Crypto','Bonds','Options'],fontsize=20)
plt.xticks(rotation=45)

plt.xlabel('Primary asset class', fontsize=20)
plt.ylabel(r'Count',fontsize=20)


plt.tight_layout(pad=5.0)
plt.savefig('demographics.png',bbox_inches='tight')

plt.show()

data_final['Payoff']=data_final['participant.payoff']+data_final['FinScore']
dem=data_final.drop_duplicates(subset=['owner__participant__code'])
dem['PayoffDollar']=dem['Payoff']/5

sizefigs_L=(16,9)
gs = gridspec.GridSpec(1, 1)


fig=plt.figure(facecolor='white',figsize=sizefigs_L)
ax=fig.add_subplot(gs[0, 0])
ax=settings_plot(ax)

sns.histplot(data=dem, x="PayoffDollar",stat='percent')

plt.xlabel('Experimental payoff (CAD)', fontsize=20)
plt.ylabel(r'Percent of sample',fontsize=20)
plt.savefig('payments.png',bbox_inches='tight')