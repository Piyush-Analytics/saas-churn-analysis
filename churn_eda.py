import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# Plot styling
sns.set_theme(style="whitegrid")
plt.rcParams['figure.figsize'] = (12, 5)
plt.rcParams['font.size'] = 12

# Load data
df = pd.read_csv('WA_Fn-UseC_-Telco-Customer-Churn.csv')

# Clean data
df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
df['TotalCharges'].fillna(df['MonthlyCharges'], inplace=True)
df['Churn_Flag'] = df['Churn'].apply(lambda x: 1 if x == 'Yes' else 0)

# Tenure groups
df['Tenure_Group'] = pd.cut(df['tenure'],
    bins=[0, 12, 24, 36, 48, 60, 72],
    labels=['0-12', '13-24', '25-36', '37-48', '49-60', '61+'])

print("=" * 50)
print("   SAAS CHURN ANALYSIS — KEY METRICS")
print("=" * 50)
print(f"  Total Customers    : {len(df)}")
print(f"  Churned            : {df['Churn_Flag'].sum()}")
print(f"  Retained           : {len(df) - df['Churn_Flag'].sum()}")
print(f"  Churn Rate         : {df['Churn_Flag'].mean()*100:.1f}%")
print(f"  Avg Monthly Charge : ${df['MonthlyCharges'].mean():.2f}")
print(f"  Avg Tenure         : {df['tenure'].mean():.1f} months")
print(f"  Total MRR          : ${df['MonthlyCharges'].sum():,.2f}")
print("=" * 50)
print("✅ Data loaded successfully!")

# ── Chart 1: Churn Overview ───────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Count
df['Churn'].value_counts().plot(kind='bar', ax=axes[0],
    color=['#2ecc71', '#e74c3c'], edgecolor='black', width=0.5)
axes[0].set_title('Churn Count', fontsize=14, fontweight='bold')
axes[0].set_xticklabels(['Retained', 'Churned'], rotation=0)
for p in axes[0].patches:
    axes[0].annotate(str(int(p.get_height())),
        (p.get_x() + p.get_width()/2, p.get_height() + 20),
        ha='center', fontsize=12)

# Pie
df['Churn'].value_counts().plot(kind='pie', ax=axes[1],
    colors=['#2ecc71', '#e74c3c'], autopct='%1.1f%%',
    startangle=90, labels=['Retained', 'Churned'])
axes[1].set_title('Churn Rate', fontsize=14, fontweight='bold')
axes[1].set_ylabel('')

plt.suptitle('Customer Churn Overview', fontsize=16, fontweight='bold')
plt.tight_layout()
plt.savefig('chart1_churn_overview.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 1 saved!")

# ── Chart 2: Churn by Contract Type ──────────────────────────
contract_churn = df.groupby('Contract')['Churn_Flag'].mean() * 100
contract_churn = contract_churn.sort_values(ascending=False)

plt.figure(figsize=(10, 5))
bars = plt.bar(contract_churn.index, contract_churn.values,
               color=['#e74c3c', '#f39c12', '#2ecc71'],
               edgecolor='black', width=0.5)
plt.title('Churn Rate by Contract Type', fontsize=15, fontweight='bold')
plt.xlabel('Contract Type')
plt.ylabel('Churn Rate (%)')
for bar, val in zip(bars, contract_churn.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
             f'{val:.1f}%', ha='center', fontsize=12, fontweight='bold')
plt.tight_layout()
plt.savefig('chart2_churn_by_contract.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 2 saved!")

# ── Chart 3: Churn by Tenure Group ───────────────────────────
tenure_churn = df.groupby('Tenure_Group', observed=True)['Churn_Flag'].mean() * 100

plt.figure(figsize=(12, 5))
bars = plt.bar(tenure_churn.index.astype(str), tenure_churn.values,
               color=['#e74c3c', '#f39c12', '#3498db', '#2ecc71', '#9b59b6', '#1abc9c'],
               edgecolor='black', width=0.5)
plt.title('Churn Rate by Tenure Group (Months)', fontsize=15, fontweight='bold')
plt.xlabel('Tenure Group')
plt.ylabel('Churn Rate (%)')
for bar, val in zip(bars, tenure_churn.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
             f'{val:.1f}%', ha='center', fontsize=12, fontweight='bold')
plt.tight_layout()
plt.savefig('chart3_churn_by_tenure.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 3 saved!")

# ── Chart 4: Monthly Charges Distribution ────────────────────
plt.figure(figsize=(12, 5))
sns.histplot(data=df, x='MonthlyCharges', hue='Churn',
             palette={'Yes': '#e74c3c', 'No': '#2ecc71'},
             bins=30, alpha=0.7)
plt.title('Monthly Charges Distribution by Churn', fontsize=15, fontweight='bold')
plt.xlabel('Monthly Charges ($)')
plt.ylabel('Count')
plt.tight_layout()
plt.savefig('chart4_monthly_charges.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 4 saved!")

# ── Chart 5: Churn by Internet Service ───────────────────────
internet_churn = df.groupby('InternetService')['Churn_Flag'].mean() * 100
internet_churn = internet_churn.sort_values(ascending=False)

plt.figure(figsize=(10, 5))
bars = plt.bar(internet_churn.index, internet_churn.values,
               color=['#e74c3c', '#f39c12', '#2ecc71'],
               edgecolor='black', width=0.5)
plt.title('Churn Rate by Internet Service', fontsize=15, fontweight='bold')
plt.xlabel('Internet Service')
plt.ylabel('Churn Rate (%)')
for bar, val in zip(bars, internet_churn.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
             f'{val:.1f}%', ha='center', fontsize=12, fontweight='bold')
plt.tight_layout()
plt.savefig('chart5_internet_service.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 5 saved!")

# ── Chart 6: Churn by Payment Method ─────────────────────────
payment_churn = df.groupby('PaymentMethod')['Churn_Flag'].mean() * 100
payment_churn = payment_churn.sort_values(ascending=False)

plt.figure(figsize=(12, 5))
bars = plt.barh(payment_churn.index, payment_churn.values,
                color=['#e74c3c', '#f39c12', '#3498db', '#2ecc71'],
                edgecolor='black')
plt.title('Churn Rate by Payment Method', fontsize=15, fontweight='bold')
plt.xlabel('Churn Rate (%)')
for bar, val in zip(bars, payment_churn.values):
    plt.text(val + 0.3, bar.get_y() + bar.get_height()/2,
             f'{val:.1f}%', va='center', fontsize=11, fontweight='bold')
plt.tight_layout()
plt.savefig('chart6_payment_method.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 6 saved!")

# ── Chart 7: Cohort Retention Heatmap ────────────────────────
cohort_data = df.groupby(['Tenure_Group', 'Contract'], observed=True)['Churn_Flag'].mean() * 100
cohort_pivot = cohort_data.unstack()

plt.figure(figsize=(12, 6))
sns.heatmap(cohort_pivot, annot=True, fmt='.1f', cmap='RdYlGn_r',
            linewidths=0.5, cbar_kws={'label': 'Churn Rate %'})
plt.title('Cohort Churn Rate Heatmap\n(Tenure Group vs Contract Type)',
          fontsize=15, fontweight='bold')
plt.xlabel('Contract Type')
plt.ylabel('Tenure Group (Months)')
plt.tight_layout()
plt.savefig('chart7_cohort_heatmap.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 7 — Cohort Heatmap saved!")

# ── Chart 8: CLV by Contract Type ────────────────────────────
df['CLV'] = df['MonthlyCharges'] * df['tenure']
clv_contract = df.groupby('Contract')['CLV'].mean().sort_values(ascending=False)

plt.figure(figsize=(10, 5))
bars = plt.bar(clv_contract.index, clv_contract.values,
               color=['#2ecc71', '#3498db', '#e74c3c'],
               edgecolor='black', width=0.5)
plt.title('Average Customer Lifetime Value by Contract', fontsize=15, fontweight='bold')
plt.xlabel('Contract Type')
plt.ylabel('Average CLV ($)')
for bar, val in zip(bars, clv_contract.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 20,
             f'${val:,.0f}', ha='center', fontsize=12, fontweight='bold')
plt.tight_layout()
plt.savefig('chart8_clv_contract.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 8 saved!")

# ── Chart 9: Churn by Senior Citizen ─────────────────────────
senior_churn = df.groupby('SeniorCitizen')['Churn_Flag'].mean() * 100

plt.figure(figsize=(8, 5))
bars = plt.bar(['Non-Senior', 'Senior'], senior_churn.values,
               color=['#2ecc71', '#e74c3c'], edgecolor='black', width=0.4)
plt.title('Churn Rate by Senior Citizen Status', fontsize=15, fontweight='bold')
plt.xlabel('Customer Type')
plt.ylabel('Churn Rate (%)')
for bar, val in zip(bars, senior_churn.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
             f'{val:.1f}%', ha='center', fontsize=12, fontweight='bold')
plt.tight_layout()
plt.savefig('chart9_senior_churn.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 9 saved!")

# ── Chart 10: Service Count vs Churn ─────────────────────────
service_cols = ['PhoneService', 'OnlineSecurity', 'OnlineBackup',
                'DeviceProtection', 'TechSupport', 'StreamingTV', 'StreamingMovies']
df['Service_Count'] = df[service_cols].apply(lambda x: (x == 'Yes').sum(), axis=1)

service_churn = df.groupby('Service_Count')['Churn_Flag'].mean() * 100

plt.figure(figsize=(12, 5))
bars = plt.bar(service_churn.index.astype(str), service_churn.values,
               color=['#e74c3c' if v > 25 else '#2ecc71' for v in service_churn.values],
               edgecolor='black', width=0.5)
plt.title('Churn Rate by Number of Services Subscribed', fontsize=15, fontweight='bold')
plt.xlabel('Number of Services')
plt.ylabel('Churn Rate (%)')
for bar, val in zip(bars, service_churn.values):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.3,
             f'{val:.1f}%', ha='center', fontsize=11, fontweight='bold')
plt.tight_layout()
plt.savefig('chart10_service_count.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Chart 10 saved!")

# ── Chart 11: Combined Dashboard Summary ─────────────────────
fig, axes = plt.subplots(2, 3, figsize=(20, 12))
fig.suptitle('SaaS Churn Analysis Dashboard — Telco Customer Dataset',
             fontsize=20, fontweight='bold', y=1.01)

from matplotlib.image import imread
charts = [
    ('chart1_churn_overview.png', 'Churn Overview'),
    ('chart2_churn_by_contract.png', 'By Contract'),
    ('chart3_churn_by_tenure.png', 'By Tenure'),
    ('chart5_internet_service.png', 'Internet Service'),
    ('chart7_cohort_heatmap.png', 'Cohort Heatmap'),
    ('chart8_clv_contract.png', 'CLV by Contract'),
]
for ax, (path, title) in zip(axes.flatten(), charts):
    try:
        img = imread(path)
        ax.imshow(img)
        ax.set_title(title, fontsize=13, fontweight='bold')
        ax.axis('off')
    except:
        ax.set_visible(False)

plt.tight_layout()
plt.savefig('SaaS_Churn_Dashboard_Summary.png', dpi=150, bbox_inches='tight')
plt.show()
print("✅ Dashboard Summary saved!")

# ── Key Insights ──────────────────────────────────────────────
print("\n" + "=" * 55)
print("        SAAS CHURN — KEY INSIGHTS")
print("=" * 55)
print(f"  Churn Rate              : {df['Churn_Flag'].mean()*100:.1f}%")
print(f"  Month-to-Month Churn    : {df[df['Contract']=='Month-to-month']['Churn_Flag'].mean()*100:.1f}%")
print(f"  Two Year Contract Churn : {df[df['Contract']=='Two year']['Churn_Flag'].mean()*100:.1f}%")
print(f"  Fiber Optic Churn       : {df[df['InternetService']=='Fiber optic']['Churn_Flag'].mean()*100:.1f}%")
print(f"  Senior Citizen Churn    : {df[df['SeniorCitizen']==1]['Churn_Flag'].mean()*100:.1f}%")
print(f"  0-12 Month Tenure Churn : {df[df['Tenure_Group']=='0-12']['Churn_Flag'].mean()*100:.1f}%")
print(f"  Avg CLV (Retained)      : ${df[df['Churn']=='No']['CLV'].mean():,.0f}")
print(f"  Avg CLV (Churned)       : ${df[df['Churn']=='Yes']['CLV'].mean():,.0f}")
print("=" * 55)
print("✅ Analysis Complete!")